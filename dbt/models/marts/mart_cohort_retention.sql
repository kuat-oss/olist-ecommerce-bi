-- Share of each monthly cohort that ordered again N months after their first order
with o as (
    select
        f.customer_key,
        date_trunc('month', d.date)::date as order_month
    from {{ ref('fct_orders') }} f
    join {{ ref('dim_date') }} d using (date_key)
    where f.is_valid_order
),
c as (
    select customer_key, cohort_month from {{ ref('dim_customer') }}
    where cohort_month between date '{{ var("analysis_start") }}' and date '{{ var("analysis_end") }}'
),
activity as (
    select distinct
        c.cohort_month,
        date_diff('month', c.cohort_month, o.order_month) as months_since_first,
        o.customer_key
    from o join c using (customer_key)
)
select
    cohort_month,
    months_since_first,
    count(distinct customer_key)                                            as customers,
    count(distinct customer_key)::double
        / max(count(distinct customer_key)) over (partition by cohort_month) as retention_rate
from activity
where months_since_first between 0 and 12
group by 1, 2
order by 1, 2
