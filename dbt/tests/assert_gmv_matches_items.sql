-- order-level GMV must equal the sum of item prices (within 1 cent per order)
select o.order_id, o.item_value, sum(i.price) as items_total
from {{ ref('fct_orders') }} o
join {{ ref('fct_order_items') }} i using (order_id)
group by o.order_id, o.item_value
having abs(o.item_value - sum(i.price)) > 0.01
