{{config(alias='ens_reverse_registrars')}}

select
  *
from {{ ref('ens_ethereum_reverse_registrars') }}