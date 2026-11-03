-- How delivery timing relates to the review the customer leaves
select
    case
        when days_vs_estimate <= -10 then '1. 10+ days early'
        when days_vs_estimate <= -5  then '2. 5-9 days early'
        when days_vs_estimate <= 0   then '3. 0-4 days early'
        when days_vs_estimate <= 3   then '4. 1-3 days late'
        when days_vs_estimate <= 7   then '5. 4-7 days late'
        else                              '6. 8+ days late'
    end                                                         as delivery_bucket,
    count(*)                                                    as orders,
    avg(review_score)                                           as avg_review,
    avg(case when review_score <= 2 then 1.0 else 0 end)        as bad_review_rate,
    avg(case when review_score = 5 then 1.0 else 0 end)         as five_star_rate
from {{ ref('fct_orders') }}
where is_delivered and review_score is not null
group by 1
order by 1
