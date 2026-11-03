-- what customers paid should be close to items + freight for delivered orders.
-- vouchers and installment interest cause small gaps, so allow 5% of orders to differ by more than 1 BRL
select 1
from (
    select avg(case when abs(payment_value - order_value) > 1 then 1.0 else 0 end) as mismatch_rate
    from {{ ref('fct_orders') }}
    where is_delivered and payment_value is not null
)
where mismatch_rate > 0.05
