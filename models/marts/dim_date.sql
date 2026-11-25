-- query dim_date.sql
{{ config(materialized='view') }}

with

date_spine as (
    select date_day
    from unnest(generate_date_array(date '2016-01-01', date '2019-12-31')) as date_day  
)

, holidays as (
    select 
        cast(holiday_date as date) as holiday_date
        , holiday_name
    from {{ ref('argentina_holidays') }}
)

, final as (
    select
        d.date_day as date_id
        , extract(year from d.date_day) as year
        , extract(month from d.date_day) as month
        , format_date('%B', d.date_day) as month_name
        , extract(dayofweek from d.date_day) as day_of_week
        , format_date('%A', d.date_day) as day_name
        , case when extract(dayofweek from d.date_day) in (1,7) then true else false end as is_weekend
        , case when h.holiday_date is not null then true else false end as is_holiday
        , h.holiday_name
    from date_spine as d
    left join holidays as h 
    on d.date_day = h.holiday_date
)

select * from final