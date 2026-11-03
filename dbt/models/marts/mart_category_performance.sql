with i as (
    select i.*, p.category
    from {{ ref('fct_order_items') }} i
    join {{ ref('dim_product') }} p using (product_key)
    join {{ ref('dim_date') }} d using (date_key)
    where i.is_valid_order and d.is_in_analysis_window
),
cat as (
    select
        category,
        count(distinct order_id)                                    as orders,
        count(*)                                                    as items,
        sum(price)                                                  as gmv,
        avg(price)                                                  as avg_price,
        sum(freight_value) / sum(price)                             as freight_share,
        avg(case when is_late then 1.0 else 0 end) filter (where is_delivered) as late_rate,
        avg(review_score)                                           as avg_review
    from i
    group by category
)
select
    *,
    rank() over (order by gmv desc)                                  as gmv_rank,
    sum(gmv) over (order by gmv desc rows between unbounded preceding and current row)
        / sum(gmv) over ()                                           as cumulative_gmv_share
from cat
order by gmv desc
