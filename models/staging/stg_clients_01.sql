{{ config(materialized='view') }}

with source as (
    select * from {{ source('fuelstream_consumers', 'clients_01') }}
),

renamed as (
    select
        idpersona as person_id,
        fechanacimiento as birth_date,
        genero as gender,
        recibecorreo as receives_email,
        numerocuenta as account_number,
        fecharegistro as registered_at,
        estadosocio as member_status,
        tipocuenta as account_type,
        
        -- Insert file_date as null for later unification
        cast(null as date) as file_date,
        
        ultima_actualizacion as updated_at,
        statusemail as email_status,
        validacion_dominio_existente as is_domain_valid
    from source
)

select * from renamed
