select
    s.seller_id         as seller_key,
    s.state_code,
    st.state_name,
    st.region,
    s.city
from {{ ref('stg_sellers') }} s
left join {{ ref('brazil_states') }} st on st.state_code = s.state_code
