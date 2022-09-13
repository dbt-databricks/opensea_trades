{{config(alias='nft_mints')}}

  select *
  from {{ ref("nft_ethereum_mints") }}