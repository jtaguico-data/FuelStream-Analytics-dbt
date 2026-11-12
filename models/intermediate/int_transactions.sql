{{ config(materialized='view') }}

with trx as 
(select * from {{ ref('stg_transactions') }} ), 
clients as 
(select person_id from {{ ref('int_clients') }}  )

-- Enforce referential integrity by filtering out orphaned transactions.
select
    t.*
from trx as t
inner join clients as c
on t.person_id = c.person_id