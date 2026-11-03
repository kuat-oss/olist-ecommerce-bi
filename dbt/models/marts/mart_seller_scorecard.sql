-- Seller scorecard: sellers with 30+ delivered items get a tier
with i as (
    select i.*
    from {{ ref('fct_order_items') }} i
    join {{ ref('dim_date') }} d using (date_key)
    where i.is_valid_order and d.is_in_analysis_window
),
s as (
    select
        seller_key,
        count(distinct order_id)                                    as orders,
        count(*) filter (where is_delivered)                        as delivered_items,
        sum(price)                                                  as gmv,
        avg(case when is_late then 1.0 else 0 end) filter (where is_delivered) as late_rate,
        avg(review_score)                                           as avg_review,
        avg(case when review_score <= 2 then 1.0 else 0 end)
            filter (where review_score is not null)                 as bad_review_rate
    from i
    group by seller_key
)
select
    s.*,
    d.state_code,
    d.region,
    case
        when s.delivered_items < 30 then 'Too few orders'
        when s.late_rate > 0.15 or s.avg_review < 3.5 then 'At risk'
        when s.late_rate <= 0.05 and s.avg_review >= 4.3 then 'Top'
        else 'Standard'
    end                                                              as tier
from s
left join {{ ref('dim_seller') }} d using (seller_key)
order by gmv desc
