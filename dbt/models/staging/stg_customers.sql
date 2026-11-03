-- customer_id is created per order. customer_unique_id is the actual person,
-- so repeat-purchase analysis has to use customer_unique_id.
select
    customer_id,
    customer_unique_id,
    lpad(cast(customer_zip_code_prefix as varchar), 5, '0') as zip_prefix,
    customer_city   as city,
    customer_state  as state_code
from {{ source('raw', 'customers') }}
