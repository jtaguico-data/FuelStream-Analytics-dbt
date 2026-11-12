{{ config(materialized='view') }}

with source as (
    select * from {{ source('fuelstream_consumers', 'clients_02') }}
),

renamed as (
    select
        persona_id as person_id,
        fechanacimiento as birth_date,
        genero as gender,
        recibecorreo as receives_email,
        numerocuenta as account_number,
        fecharegistro as registered_at,
        estadosocio as member_status,
        tipocuenta as account_type,
        
        -- Transform string/int 'YYYYMMDD' to DATE BigQuery format
        parse_date('%Y%m%d', cast(fecha_archivo as string)) as file_date,
        
        -- Empty columns inserted as Nulls for later unification
        cast(null as timestamp) as updated_at,
        cast(null as string) as email_status,
        cast(null as string) as is_domain_valid
    from source
)

select * from renamed
