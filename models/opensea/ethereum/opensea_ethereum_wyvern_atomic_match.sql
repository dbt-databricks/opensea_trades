with wyvern_atomic_match as (
    select *
    from  {{ source('ethereum_opensea', 'wyvern_exchange_call_atomic_match_') }}
    union
    select *
    from {{ source('ethereum_opensea', 'wyvern_exchange_2_call_atomic_match_') }}
),

tx as (
    select *
    from {{ source('ethereum', 'transactions') }}
),

wyvern_data as (
    select
        call_tx_hash as tx_hash,
        call_block_number as block_number,
        call_block_time as block_time,
        addrs[1] as buyer,
        {{ utils.binary_to_address(utils.substring('calldata_buy', 49, 20)) }} as buyer_when_aggr,
        addrs[8] as seller,
        cast(uints[4] as double) as currency_amount,
        case
            when {{ utils.substring('calldata_buy', 1, 4) }} in ({{ utils.binary_literal('68f0bcaa') }})
                then 'Bundle Trade'
            else 'Single Item Trade'
        end as trade_type,
        case
            when {{ utils.substring('calldata_buy', 1, 4) }} in ({{ utils.binary_literal('fb16a595') }}, {{ utils.binary_literal('23b872dd') }})
                then 'erc721'
            when {{ utils.substring('calldata_buy', 1, 4) }} in ({{ utils.binary_literal('23b872dd') }}, {{ utils.binary_literal('f242432a') }})
                then 'erc1155'
        end as erc_standard,
        addrs[0] as exchange_contract_address,
        case
            when {{ utils.substring('calldata_buy', 1, 4) }} in ({{ utils.binary_literal('fb16a595') }}, {{ utils.binary_literal('96809f90') }})
                then {{ utils.binary_to_address(utils.substring('calldata_buy', 81, 20)) }}
            else addrs[4]
        end as nft_contract_address,
        case
            when addrs[6] = '0x0000000000000000000000000000000000000000'
                then '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
            else addrs[6]
        end as currency_contract,
        addrs[6] as original_currency_contract,
        case
            when {{ utils.substring('calldata_buy', 1, 4) }} in ({{ utils.binary_literal('fb16a595') }}, {{ utils.binary_literal('96809f90') }})
                then cast(round({{ utils.binary_to_numeric(utils.substring('calldata_buy', 101, 32)) }}, 0) as {{ dbt_utils.type_string() }})
            when {{ utils.substring('calldata_buy', 1, 4) }} in ({{ utils.binary_literal('23b872dd') }}, {{ utils.binary_literal('f242432a') }})
                then cast(round({{ utils.binary_to_numeric(utils.substring('calldata_buy', 69, 32)) }}, 0) as {{ dbt_utils.type_string() }})
        end as token_id
    from wyvern_atomic_match
    where
        (addrs[3] = '0x5b3256965e7c3cf26e11fcaf296dfc8807c01073'
            or addrs[10] = '0x5b3256965e7c3cf26e11fcaf296dfc8807c01073')
        and call_success = true
)

select
    w.tx_hash,
    w.block_number,
    w.block_time,
    w.buyer,
    w.buyer_when_aggr,
    w.seller,
    w.currency_amount,
    w.trade_type,
    w.erc_standard,
    w.exchange_contract_address,
    w.nft_contract_address,
    w.currency_contract,
    w.original_currency_contract,
    w.token_id,
    tx.from_address as tx_from,
    tx.to_address as tx_to
from wyvern_data w

left join tx on tx.hash = w.tx_hash