# Builds dashboard/data.js from the dbt marts.
# Facts are pre-aggregated by month x region (all measures additive), so the
# dashboard can filter by period and region without loading 100k rows.
import json
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "dashboard" / "data.js"


def rows(con, sql):
    rel = con.sql(sql)
    cols = rel.columns
    out = []
    for r in rel.fetchall():
        rec = {}
        for c, v in zip(cols, r):
            if hasattr(v, "isoformat"):
                v = v.isoformat()[:10]
            elif isinstance(v, float):
                v = round(v, 4)
            rec[c] = v
        out.append(rec)
    return out


def main():
    con = duckdb.connect(str(ROOT / "warehouse" / "olist.duckdb"), read_only=True)

    cube = rows(con, """
        select
            d.year_month                                                    as m,
            coalesce(c.region, 'Unknown')                                   as r,
            count(*) filter (where f.is_valid_order)                        as orders,
            count(*) filter (where f.is_valid_order and f.is_first_order)   as new_cust,
            round(sum(f.item_value) filter (where f.is_valid_order), 2)     as gmv,
            round(sum(f.freight_value) filter (where f.is_valid_order), 2)  as freight,
            count(*) filter (where f.is_delivered)                          as delivered,
            count(*) filter (where f.is_delivered and f.is_late)            as late,
            sum(f.delivery_days) filter (where f.is_delivered)              as deliv_days,
            sum(f.review_score)                                             as rev_sum,
            count(f.review_score)                                           as rev_n,
            count(*) filter (where f.review_score <= 2)                     as bad_n,
            count(*) filter (where f.order_status = 'canceled')             as canceled,
            count(*)                                                        as all_orders
        from fct_orders f
        join dim_date d using (date_key)
        left join dim_customer c using (customer_key)
        where d.is_in_analysis_window
        group by 1, 2
        order by 1, 2
    """)

    states = rows(con, """
        select
            d.year_month                                                    as m,
            f.customer_state                                                as s,
            coalesce(c.region, 'Unknown')                                   as r,
            count(*) filter (where f.is_valid_order)                        as orders,
            round(sum(f.item_value) filter (where f.is_valid_order), 2)     as gmv,
            count(*) filter (where f.is_delivered)                          as delivered,
            count(*) filter (where f.is_delivered and f.is_late)            as late,
            sum(f.delivery_days) filter (where f.is_delivered)              as deliv_days,
            sum(f.review_score)                                             as rev_sum,
            count(f.review_score)                                           as rev_n
        from fct_orders f
        join dim_date d using (date_key)
        left join dim_customer c using (customer_key)
        where d.is_in_analysis_window
        group by 1, 2, 3
        order by 1, 2, 3
    """)

    categories = rows(con, """
        select
            d.year_month                                as m,
            coalesce(c.region, 'Unknown')               as r,
            p.category                                  as cat,
            round(sum(i.price), 2)                      as gmv,
            count(*)                                    as items
        from fct_order_items i
        join dim_date d using (date_key)
        join dim_product p using (product_key)
        left join dim_customer c using (customer_key)
        where d.is_in_analysis_window and i.is_valid_order
        group by 1, 2, 3
        order by 1, 2, 3
    """)

    payload = {
        "cube": cube,
        "states": states,
        "categories": categories,
        "deliveryVsReviews": rows(con, "select * from mart_delivery_vs_reviews order by delivery_bucket"),
        "cohorts": rows(con, "select * from mart_cohort_retention order by cohort_month, months_since_first"),
        "sellers": rows(con, """
            select seller_key, state_code, region, orders, delivered_items, gmv, late_rate,
                   avg_review, bad_review_rate, tier
            from mart_seller_scorecard
            where tier <> 'Too few orders'
            order by gmv desc, seller_key
        """),
        "sellerTiers": rows(con, """
            select tier, count(*) as sellers, sum(gmv) as gmv,
                   sum(gmv) / (select sum(gmv) from mart_seller_scorecard) as gmv_share
            from mart_seller_scorecard group by 1 order by 1
        """),
        "customerTypes": rows(con, """
            select customer_type, count(*) as customers, avg(lifetime_item_value) as avg_value
            from dim_customer where orders > 0 group by 1 order by 1
        """),
    }
    con.close()
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text("// built by scripts/build_dashboard_data.py\nwindow.OLIST = "
                   + json.dumps(payload, separators=(",", ":")) + ";\n")
    print(f"wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
