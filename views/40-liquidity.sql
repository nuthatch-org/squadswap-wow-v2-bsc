-- Liquidity added and removed, as one stream. Mint and Burn carry the same shape, so they are
-- unioned with a `kind` discriminator rather than left as two near-identical tables to join by hand.
--
-- `amount` is the liquidity delta; `amount0`/`amount1` are the token amounts that moved. All three
-- use their `_dec` companions. Burn amounts are reported positive by the contract - a Burn is a
-- removal by virtue of being a Burn, not by carrying a negative number.
CREATE VIEW liquidity_events AS
SELECT
  'mint'          AS kind,
  address         AS pool,
  block_number, block_timestamp, tx_hash, log_index,
  owner,
  CAST(tickLower AS INTEGER) AS tick_lower,
  CAST(tickUpper AS INTEGER) AS tick_upper,
  amount_dec, amount0_dec, amount1_dec
FROM pool__mint
UNION ALL
SELECT
  'burn'          AS kind,
  address         AS pool,
  block_number, block_timestamp, tx_hash, log_index,
  owner,
  CAST(tickLower AS INTEGER) AS tick_lower,
  CAST(tickUpper AS INTEGER) AS tick_upper,
  amount_dec, amount0_dec, amount1_dec
FROM pool__burn;
