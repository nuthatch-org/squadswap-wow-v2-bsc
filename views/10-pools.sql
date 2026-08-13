-- The pool registry: one row per pool the factory has ever created, with its token pair, the fee
-- tier it launched with (hundredths of a bip: 100 = 0.01%, 500 = 0.05%, 2500 = 0.25%, 10000 = 1%)
-- and its tick spacing. `pool` is the pool contract address, which is the key every `pool__*` event
-- joins on via their implicit `address` column.
--
-- One factory rule in nuthatch.toml discovers every row here. There is no per-pool configuration
-- anywhere in this nest.
CREATE VIEW pools AS
SELECT
  pool,
  token0,
  token1,
  CAST(fee AS INTEGER)         AS launch_fee,
  CAST(tickSpacing AS INTEGER) AS tick_spacing,
  block_number                 AS created_block,
  block_timestamp              AS created_at
FROM factory__pool_created;
