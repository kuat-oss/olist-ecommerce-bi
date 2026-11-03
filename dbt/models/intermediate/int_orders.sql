-- One row per order with everything the facts and KPIs need.
with items as (
    select
        order_id,
        count(*)                    as items,
        count(distinct seller_id)   as sellers,
        sum(price)                  as item_value,
        sum(freight_value)          as freight_value
    from {{ ref('stg_order_items') }}
    group by order_id
),

payments as (
    select
        order_id,
        sum(payment_value)                              as payment_value,
        arg_max(payment_type, payment_value)            as main_payment_type,
        max(payment_installments)                       as installments
    from {{ ref('stg_order_payments') }}
    group by order_id
),

base as (
    select
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.state_code,
        o.order_status,
        o.purchased_at,
        o.order_date,
        o.approved_at,
        o.shipped_at,
        o.delivered_at,
        o.estimated_delivery_at,
        coalesce(i.items, 0)            as items,
        coalesce(i.sellers, 0)          as sellers,
        coalesce(i.item_value, 0)       as item_value,
        coalesce(i.freight_value, 0)    as freight_value,
        p.payment_value,
        p.main_payment_type,
        p.installments,
        r.review_score,
        r.has_comment                   as review_has_comment
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_customers') }} c using (customer_id)
    left join items i using (order_id)
    left join payments p using (order_id)
    left join {{ ref('stg_order_reviews') }} r using (order_id)
)

select
    *,
    order_status not in ('canceled', 'unavailable')                 as is_valid_order,
    order_status = 'delivered' and delivered_at is not null         as is_delivered,
    case when delivered_at is not null
         then date_diff('day', purchased_at, delivered_at) end      as delivery_days,
    date_diff('day', purchased_at, estimated_delivery_at)           as promised_days,
    case when delivered_at is not null
         then date_diff('day', cast(estimated_delivery_at as date), cast(delivered_at as date)) end
                                                                    as days_vs_estimate,
    case when delivered_at is not null
         then cast(delivered_at as date) > cast(estimated_delivery_at as date) end
                                                                    as is_late,
    row_number() over (partition by customer_unique_id order by purchased_at, order_id)
                                                                    as customer_order_number
from base
