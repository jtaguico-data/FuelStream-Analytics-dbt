--agg_monthly_network_volume.sql
{{ config( materialized='table' ) }}

with transactions as (
    select * from {{ ref('fct_transactions') }}
)

, dates as (
    select
        date_id,
        date_trunc(date_id, month) as month_date,
        extract(year from date_id) as year,
        extract(month from date_id) as month,
        is_weekend,
        is_holiday
    from {{ ref('dim_date') }}
)

, products as (
    select
        product_id,
        product_category,
        product_tier
    from {{ ref('dim_products') }}
)

, final as (
    select
        d.month_date,
        d.year,
        d.month,
        t.site_id,
        p.product_id,
        p.product_category,
        p.product_tier,
        count(t.transaction_id) as total_transactions,
        count(distinct t.person_id) as active_customers,
        sum(t.clean_quantity) as total_quantity,
        sum(t.points) as total_points,
        safe_divide(sum(t.points), sum(t.clean_quantity)) as avg_points_per_unit,
        sum(case when d.is_weekend then t.clean_quantity else 0 end) as weekend_quantity,
        sum(case when d.is_holiday then t.clean_quantity else 0 end) as holiday_quantity
    from transactions t
    inner join dates d
        on t.date_id = d.date_id
    inner join products p
        on t.product_id = p.product_id
    group by 1, 2, 3, 4, 5, 6, 7
)

select * from final

