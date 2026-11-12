{{ config (materialized='view')}}

with clients01 as 
(select *, 1 as source_priority from {{ ref('stg_clients_01') }} )  
, clients02 as 
    -- table clients 2 has a few repeated rows, no difference between rows, audited previously 
(SELECT DISTINCT c.*, 2 as source_priority from {{ ref('stg_clients_02') }} c ), 

--unioned_clients 
unioned_clients as (
    select * from clients01 
    union all
    select * from clients02
),

--ranked_clients
ranked_clients as (
    SELECT *, 
    ROW_NUMBER() OVER(
        PARTITION BY person_id 
        order by source_priority
    ) as row_num 
    FROM unioned_clients 
),

-- final
final as (
    -- filter duplicates and drop helper columns using BigQuery EXCEPT
    select * except (source_priority, row_num)
    from ranked_clients
    where row_num = 1
)

select * from final
