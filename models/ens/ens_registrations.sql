{{config(alias='ens_registrations')}}

select
  *
from {{ ref('ens_ethereum_registrations') }}