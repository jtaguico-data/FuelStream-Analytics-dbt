--dim_products.sql
{{ config(materialized='view') }}

with
products as (
    select distinct product_id
    from {{ ref('int_transactions') }}
)

, final as (
    select 
        product_id,
        case 
            when product_id IN ('SUPER','NAFTA','DIESEL') then 'Fuel'
            when product_id IN ('LUBRI PREM','LUBRI REGU') then 'Lubricants'
            when product_id IN ('PRODUCTO SHOP') then 'Convenience Store'
            else 'Other'        
        end as product_category,
        case 
            when product_id IN ('LUBRI PREM','NAFTA') then 'Premium'
            when product_id IN ('SUPER', 'DIESEL', 'LUBRI REGU', 'PRODUCTO SHOP') then 'Standard'
            else 'Other'     
        end as product_tier
    from products
)

select * from final 