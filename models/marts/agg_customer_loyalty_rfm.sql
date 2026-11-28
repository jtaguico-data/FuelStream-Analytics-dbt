-- agg_customer_loyalty_rfm.sql
{{ config( materialized='table' ) }}

{{ config( materialized='table' ) }}

with clients as (
    select 
        person_id,
        customer_segment,
        age_group,
        gender,
        member_status
    from {{ ref('dim_clients') }}
),

products as (
    select
        product_id,
        product_category,
        product_tier
    from {{ ref('dim_products') }}
),

tx_summary as (
    select 
        t.person_id,
        min(t.date_id) as first_tx_date,
        max(t.date_id) as last_tx_date,
        date_diff(max(max(t.date_id)) over (), max(t.date_id), day) as recency_days,
        count(distinct date_trunc(t.date_id, month)) as active_months,
        count(t.transaction_id) as total_transactions,
        countif(p.product_category = 'Fuel') as fuel_transactions,
        countif(p.product_category = 'Convenience Store') as store_transactions,
        countif(p.product_category = 'Lubricants') as lubricants_transactions,
        sum(t.clean_quantity) as total_quantity,
        sum(case when p.product_category = 'Fuel' then t.clean_quantity else 0 end) as fuel_quantity,
        sum(case when p.product_category = 'Convenience Store' then t.clean_quantity else 0 end) as store_quantity,
        sum(case when p.product_category = 'Lubricants' then t.clean_quantity else 0 end) as lubricants_quantity,
        safe_divide(
            countif(p.product_category = 'Fuel' and p.product_tier = 'Premium'),
            countif(p.product_category = 'Fuel')
        ) as premium_fuel_share,
        sum(t.points) as total_points,
        count(distinct t.site_id) as distinct_sites_visited
    from {{ ref('fct_transactions') }} t
    inner join products p
        on t.product_id = p.product_id
    group by 1
),

final as (
    select
        c.person_id,
        c.customer_segment,
        c.age_group,
        c.gender,
        c.member_status,
        tx.first_tx_date,
        tx.last_tx_date,
        tx.recency_days,
        coalesce(tx.active_months, 0) as active_months,
        coalesce(tx.total_transactions, 0) as total_transactions,
        coalesce(tx.fuel_transactions, 0) as fuel_transactions,
        coalesce(tx.store_transactions, 0) as store_transactions,
        coalesce(tx.lubricants_transactions, 0) as lubricants_transactions,
        coalesce(tx.total_quantity, 0) as total_quantity,
        coalesce(tx.fuel_quantity, 0) as fuel_quantity,
        coalesce(tx.store_quantity, 0) as store_quantity,
        coalesce(tx.lubricants_quantity, 0) as lubricants_quantity,
        coalesce(tx.premium_fuel_share, 0) as premium_fuel_share,
        coalesce(tx.total_points, 0) as total_points,
        coalesce(tx.distinct_sites_visited, 0) as distinct_sites_visited,
        case
            when coalesce(tx.total_transactions, 0) = 0 then 'Never Transacted'
            when tx.recency_days > 180 then 'Churned'
            when tx.recency_days between 91 and 180 then 'At Risk'
            when tx.recency_days <= 90
                and tx.fuel_transactions >= 15
                and (tx.store_transactions + tx.lubricants_transactions) > 0 then 'VIP Multi-Category'
            when tx.recency_days <= 90
                and tx.fuel_transactions >= 15 then 'Loyal Fuel Regular'
            else 'Occasional Active'
        end as loyalty_segment
    from clients c
    left join tx_summary tx
        on c.person_id = tx.person_id
)

select * from final
