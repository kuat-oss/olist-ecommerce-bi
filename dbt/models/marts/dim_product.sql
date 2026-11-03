select
    product_id      as product_key,
    category,
    is_category_missing,
    photos_qty,
    weight_g,
    volume_cm3,
    case
        when weight_g is null then 'unknown'
        when weight_g < 500 then '1. under 0.5 kg'
        when weight_g < 2000 then '2. 0.5-2 kg'
        when weight_g < 10000 then '3. 2-10 kg'
        else '4. over 10 kg'
    end             as weight_band
from {{ ref('stg_products') }}
