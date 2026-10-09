# squadswap-wow-v2-bsc

A [nuthatch](https://github.com/nuthatch-org/nuthatch) nest for **SquadSwap WOW v2** on BNB Smart
Chain — a concentrated-liquidity DEX forked from PancakeSwap V3, itself a Uniswap V3 fork.

Every pool is discovered at runtime from the factory's `PoolCreated` event. There is no per-pool
configuration anywhere in this nest, and none is ever needed.

```sh
nuthatch init --from https://github.com/nuthatch-org/squadswap-wow-v2-bsc
cd squadswap-wow-v2-bsc
nuthatch dev --rpc https://your-bsc-archive-endpoint
nuthatch sql "SELECT * FROM pool_activity LIMIT 10"
```

## What it indexes

| Contract | Address | From block |
|---|---|---:|
| Factory | `0x10d8612D9D8269e322AB551C18a307cB4D6BC07B` | 46,190,543 |
| PoolManager | `0x391Eaa90f931C6330132efe6c73EBDf77d782eF5` | 46,190,551 |
| NonfungiblePositionManager | `0x501535ef0B92eE1df5C12f47720f1E479b1Db7b4` | 46,190,624 |
| Pool | discovered from `PoolCreated` | — |

27 tables. ABIs are vendored from the live subgraph deployment
`QmQTCx7o6NW9SdJuyQSCYz71YLm3K43dkmtjZ38hbqvwPL`, taken from its own pinned IPFS CIDs rather than
re-resolved from a block explorer, so they are byte-for-byte the ABIs the deployed indexer uses.

## Views

| View | What it answers |
|---|---|
| `pools` | Every pool ever created, with pair, launch fee tier and tick spacing |
| `pool_custom_fee_current` | Current per-pool fee override state |
| `pool_effective_fee` | **The fee a pool is actually charging** |
| `swaps` | Every swap, with pair, effective fee and post-swap price |
| `liquidity_events` | Mints and burns as one stream with a `kind` discriminator |
| `position_owners` | Current owner of each position NFT |
| `position_liquidity` | Net liquidity per position |
| `tokens` | Token universe, ranked by pool count |
| `pool_activity` | Per-pool swap counts and span |

## Two things that differ from a vanilla Uniswap V3 nest

**Swap carries two extra parameters.** `protocolFeesToken0` and `protocolFeesToken1` are emitted by
this fork and not by vanilla V3. Anything written against a stock V3 schema will not find them.

**A pool's fee is not necessarily the fee it was created with.** A separate `PoolManager` contract
can override a pool's fee, and can toggle that override on and off independently of setting it. So
`factory__pool_created.fee` is the *launch* tier, not the live one. Use `pool_effective_fee`:

```sql
SELECT pool, launch_fee, custom_fee, override_enabled, effective_fee
FROM pool_effective_fee
WHERE override_enabled;
```

A pool with a custom fee set but the toggle off is charging its launch fee. Reading the fee and
ignoring the toggle is the obvious way to get this wrong, and it is why this nest exists rather
than pointing you at the generic [`uniswap-v3`](https://github.com/nuthatch-org/uniswap-v3) nest.

## Footguns

- **Big ints are exact text.** Use the `*_dec` DECIMAL companions for arithmetic. Never `SUM(amount0)`.
- **Solidity bools are text.** `enabled` holds the strings `'true'` and `'false'`, not a SQL boolean.
  Compare with `enabled = 'true'`. See [nuthatch#539](https://github.com/nuthatch-org/nuthatch/issues/539).
- **Prices are raw, and marginal.** `price_token1_per_token0` is derived from `sqrtPriceX96` in raw
  token units. Multiply by `10^(decimals0 - decimals1)` for a human price; token decimals need a
  contract call and are deliberately not indexed here. It is also the **post-swap marginal** price,
  not what the swap executed at: measured against the realised `amount1/amount0` ratio it differs by
  0.16-1.0% on these pools, which is price impact plus fee, not an error.
- **Signed amounts decode properly.** `amount0_dec` / `amount1_dec` are true signed decimals, so
  `SUM` and subtraction behave. Verified: 320,949 and 329,860 of 650,815 swaps carry a negative
  side respectively, one per swap.
- **`from` and `to` are SQL keywords.** Double-quote them.

## Backfilling

The factory deployed at block 46,190,543, so a from-deployment backfill is roughly 69.5 million BSC
blocks. **You need an archive endpoint.** Every free public BSC RPC tested refuses either deep
`eth_getLogs` or archive state:

| Endpoint | Verdict |
|---|---|
| `bsc-rpc.publicnode.com` | `getLogs` needs an address filter; archive requires a paid token |
| `bsc-dataseed.binance.org` | `limit exceeded` on a 10-block `getLogs`; `missing trie node` at depth |
| `bsc-dataseed1.defibit.io` | as above |
| `bsc.drpc.org` | 320-block `getLogs` window, no archive depth |

Run `nuthatch doctor --rpc <url> --address 0x10d8612D9D8269e322AB551C18a307cB4D6BC07B` before
trusting an endpoint — it reports the largest safe window and whether archive depth is real.

The configured `rpc_urls` below are public tip-following endpoints, fine for following the chain
head but not for history. Point `--rpc` at your own archive node or a keyed provider.

## Checks

```sh
nuthatch check --dir .
```

Three checks ship with recorded fixtures: no pool emits swaps without appearing in the registry, every
pool resolves to exactly one positive effective fee, and a frozen sealed slice
(46,190,543–47,000,000) holds 5,962 swaps across 21 pools. The first two are expressed as
differences rather than counts so they stay valid as the nest indexes more history.

## Provenance

Built by [Nuthatch](https://discord.gg/CQewvyJ69Y) from the live subgraph deployment, after
a support thread about the subgraph's query reliability. The nest is not a replacement for that
subgraph on the decentralised network — it is a local copy you hold, with no retention window but
your own.
