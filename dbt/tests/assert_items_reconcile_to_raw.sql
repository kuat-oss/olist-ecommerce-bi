-- every raw order item must land in the item fact exactly once
select count(*) as diff
from {{ source('raw', 'order_items') }}
having count(*) <> (select count(*) from {{ ref('fct_order_items') }})
