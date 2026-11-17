{{ config(materialized='view') }}

with 

source as (

    select * from {{ source('fuelstream_transactions', 'sh_trx_Unq') }}

),

renamed as (

    select
        process,
        user_id,
        prod as product_id,
        qty as quantity,
        points,
        site as site_id,
        safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S', date_rg) as registered_at,
        trx_ch as transaction_channel_id,
        trx_id as transaction_id,
        safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S', date) as transacted_at,
        person_id
    from source


)

select * from renamed