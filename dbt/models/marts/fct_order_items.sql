-- grain: one row per item in an order
select
    i.order_id,
    i.order_item_id,
    cast(strftime(o.order_date, '%Y%m%d') as integer) as date_key,
    o.customer_unique_id                              as customer_key,
    i.product_id                                      as product_key,
    i.seller_id                                       as seller_key,
    i.price,
    i.freight_value,
    o.is_valid_order,
    o.is_delivered,
    o.is_late,
    o.review_score
from {{ ref('stg_order_items') }} i
join {{ ref('int_orders') }} o using (order_id)
