{{ config(materialized='view') }}

with trx as 
(select * from {{ ref('stg_transactions') }} ), 
clients as 
(select person_id from {{ ref('int_clients') }}  )

-- Enforce referential integrity by filtering out orphaned transactions.
-- Renaming product to standard naming avoiding duplicates
select
    t.* except (product_id),
    case 
        when t.product_id = 'PRODUCTO GENERI' then 'PRODUCTO SHOP'
        when t.product_id = 'PRODUCTO GENERICO' then 'PRODUCTO SHOP'
        when t.product_id = 'NAFTA VPN' then 'NAFTA'
        when t.product_id = 'DIESEL VPN' then 'DIESEL'
        else t.product_id 
    end as product_id
from trx as t
inner join clients as c
    on t.person_id = c.person_id
