with days as (
    select unnest(generate_series(date '2016-09-01', date '2018-10-31', interval 1 day))::date as date_day
)
select
    cast(strftime(date_day, '%Y%m%d') as integer)   as date_key,
    date_day                                        as date,
    extract(year from date_day)::int                as year,
    extract(quarter from date_day)::int             as quarter,
    'Q' || extract(quarter from date_day)           as quarter_label,
    extract(month from date_day)::int               as month,
    strftime(date_day, '%b')                        as month_name,
    date_trunc('month', date_day)::date             as month_start,
    strftime(date_day, '%Y-%m')                     as year_month,
    extract(isodow from date_day)::int              as day_of_week,
    strftime(date_day, '%a')                        as day_name,
    extract(isodow from date_day) in (6, 7)         as is_weekend,
    date_day between date '{{ var("analysis_start") }}' and date '{{ var("analysis_end") }}'
                                                    as is_in_analysis_window
from days
