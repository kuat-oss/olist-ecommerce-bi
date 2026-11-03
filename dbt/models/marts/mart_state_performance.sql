select
    f.customer_state                                                as state_code,
    s.state_name,
    s.region,
    count(*) filter (where f.is_valid_order)                        as orders,
    sum(f.item_value) filter (where f.is_valid_order)               as gmv,
    avg(f.delivery_days) filter (where f.is_delivered)              as avg_delivery_days,
    avg(case when f.is_late then 1.0 else 0 end) filter (where f.is_delivered) as late_rate,
    avg(f.freight_value / nullif(f.item_value, 0)) filter (where f.is_valid_order) as avg_freight_ratio,
    avg(f.review_score)                                             as avg_review
from {{ ref('fct_orders') }} f
join {{ ref('dim_date') }} d using (date_key)
left join {{ ref('brazil_states') }} s on s.state_code = f.customer_state
where d.is_in_analysis_window
group by 1, 2, 3
order by gmv desc
