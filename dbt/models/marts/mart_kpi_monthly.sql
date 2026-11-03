-- Monthly KPI table for the executive page
with o as (
    select f.*, d.month_start
    from {{ ref('fct_orders') }} f
    join {{ ref('dim_date') }} d using (date_key)
    where d.is_in_analysis_window
),
m as (
    select
        month_start,
        count(*) filter (where is_valid_order)                              as orders,
        count(distinct customer_key) filter (where is_valid_order)          as active_customers,
        count(*) filter (where is_valid_order and is_first_order)           as new_customers,
        sum(item_value) filter (where is_valid_order)                       as gmv,
        sum(freight_value) filter (where is_valid_order)                    as freight,
        avg(item_value) filter (where is_valid_order)                       as avg_order_value,
        avg(case when is_late then 1.0 else 0 end) filter (where is_delivered) as late_rate,
        avg(delivery_days) filter (where is_delivered)                      as avg_delivery_days,
        avg(review_score)                                                   as avg_review,
        avg(case when review_score <= 2 then 1.0 else 0 end)
            filter (where review_score is not null)                         as bad_review_rate,
        avg(case when order_status = 'canceled' then 1.0 else 0 end)        as cancel_rate
    from o
    group by month_start
)
select
    *,
    gmv / lag(gmv) over (order by month_start) - 1                          as gmv_mom,
    gmv / lag(gmv, 12) over (order by month_start) - 1                      as gmv_yoy,
    freight / gmv                                                           as freight_share
from m
order by month_start
