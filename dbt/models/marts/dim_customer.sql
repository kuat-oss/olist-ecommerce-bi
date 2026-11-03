-- one row per real customer (customer_unique_id). Includes customers whose
-- only order was canceled, so every order in the facts finds its customer.
with per_customer as (
    select
        customer_unique_id,
        arg_min(state_code, purchased_at)                           as state_code,
        min(order_date) filter (where is_valid_order)               as first_order_date,
        max(order_date) filter (where is_valid_order)               as last_order_date,
        count(*) filter (where is_valid_order)                      as orders,
        coalesce(sum(item_value) filter (where is_valid_order), 0)  as lifetime_item_value
    from {{ ref('int_orders') }}
    group by customer_unique_id
)
select
    pc.customer_unique_id                           as customer_key,
    pc.state_code,
    s.state_name,
    s.region,
    pc.first_order_date,
    date_trunc('month', pc.first_order_date)::date  as cohort_month,
    pc.last_order_date,
    pc.orders,
    pc.lifetime_item_value,
    case
        when pc.orders = 0 then 'No valid order'
        when pc.orders = 1 then 'One-time'
        else 'Repeat'
    end                                             as customer_type
from per_customer pc
left join {{ ref('brazil_states') }} s on s.state_code = pc.state_code
