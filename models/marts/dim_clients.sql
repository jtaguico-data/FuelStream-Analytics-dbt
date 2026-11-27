-- query dim_clients.sql
{{ config(materialized='view') }}

with clients as (
    select * from {{ ref('int_clients') }}
),

-- raw age
calculated_ages as (
    select 
        *, 
        date_diff(date '2019-10-01', birth_date, year) as raw_age 
    from clients
),

-- age groups
final as (
    select 
        person_id, 
        birth_date, 
        gender, 
        receives_email, 
        account_number,
        registered_at, 
        member_status, 
        account_type,
        -- Cleaning rules
        case 
            when raw_age between 18 and 100 then raw_age 
            else null 
        end as age,
        case 
            when raw_age between 18 and 24 then '18-24'
            when raw_age between 25 and 34 then '25-34'
            when raw_age between 35 and 44 then '35-44'
            when raw_age between 45 and 54 then '45-54'
            when raw_age between 55 and 64 then '55-64'
            when raw_age between 65 and 100 then '65+'
            else 'Unknown'
        end as age_group
    from calculated_ages
)

select * from final
