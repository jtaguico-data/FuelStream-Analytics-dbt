-- fct_transactions.sql
{{ config(materialized='view') }}

with 
transactions as (
    select *
    from {{ ref('int_transactions') }} 
)

, final as (
    select
        -- Primary and Foreign keys
        transaction_id, 
        person_id, 
        product_id,
        date(transacted_at) as date_id,
        site_id,
        transaction_channel_id,
        -- Timestamps
        transacted_at,
        registered_at,
        -- Metrics
        quantity,
        points,
        safe_divide(points, quantity) as points_per_unit,
        case
            when quantity <= 0 or quantity > 1500 then true
            else false
        end as is_quantity_outlier,
        case
            when quantity > 0 and quantity <= 1500 then quantity
            else null
        end as clean_quantity,
    from transactions
)

select * from final


