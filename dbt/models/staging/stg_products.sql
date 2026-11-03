-- the source has "lenght" typos in column names; fixed here
select
    p.product_id,
    coalesce(t.product_category_name_english,
             replace(p.product_category_name, '_', ' '),
             'unknown')                       as category,
    p.product_category_name is null           as is_category_missing,
    p.product_name_lenght                     as name_length,
    p.product_description_lenght              as description_length,
    p.product_photos_qty                      as photos_qty,
    p.product_weight_g                        as weight_g,
    p.product_length_cm * p.product_height_cm * p.product_width_cm as volume_cm3
from {{ source('raw', 'products') }} p
left join {{ source('raw', 'category_translation') }} t using (product_category_name)
