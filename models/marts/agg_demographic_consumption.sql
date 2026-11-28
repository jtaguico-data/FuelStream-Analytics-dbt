--agg_demographic_consumption.sql
{{ config( materialized='table' ) }}

with
transactions as (
    select * from {{ ref('fct_transactions') }}
),

clients as (
    select * from {{ ref('dim_clients') }}
),

dates as (
    select
        date_id,
        date_trunc(date_id, month) as month_date,
        extract(year from date_id) as year,
        extract(month from date_id) as month
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
        c.age_group,
        c.gender,
        c.member_status,
        c.customer_segment,
        p.product_id,
        p.product_category,
        p.product_tier,
        count(t.transaction_id) as total_transactions,
        count(distinct t.person_id) as active_customers,
        sum(t.clean_quantity) as total_quantity,
        sum(t.points) as total_points,
        safe_divide(sum(t.clean_quantity),count(t.transaction_id)) as avg_quantity_per_transaction
    from transactions as t 
    inner join clients as c 
        on t.person_id = c.person_id
    inner join dates as d 
        on t.date_id = d.date_id
    inner join products as p 
        on t.product_id = p.product_id
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

select * from final
