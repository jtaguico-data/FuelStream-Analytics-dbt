{{ config(materialized='view') }}

with 

source as (

    select * from {{ source('fuelstream_transactions', 'sh_trx_Unq') }}

),

renamed as (

    select
        process,
        user_id,
        card,
        prod as product_id,
        qty as quantity,
        points,
        site as site_id,
        date_rg as registered_at,
        trx_ch as transaction_channel_id,
        trx_id as transaction_id,
        date as transacted_at,
        person_id
    from source


)

select * from renamed