-- Every swap across every discovered pool, joined to its pair and the fee it was actually charging.
--
-- `amount0_dec` / `amount1_dec` are the DECIMAL companions of the raw int256 columns and are what
-- arithmetic should use; the bare `amount0` / `amount1` are exact text and must never be SUMmed.
-- The sign convention is the pool's: one side negative (leaving the pool) and one positive
-- (entering it), from the pool's point of view.
--
-- `price_token1_per_token0` is derived from sqrtPriceX96, the post-swap price accumulator:
-- price = (sqrtPriceX96 / 2^96)^2. It is in RAW token units. For a human-readable price multiply by
-- 10^(decimals0 - decimals1); token decimals need a contract call, which the declarative core does
-- not do, so join a vendored token list if you need them.
CREATE VIEW swaps AS
SELECT
  s.address                                           AS pool,
  p.token0,
  p.token1,
  f.effective_fee,
  s.block_number,
  s.block_timestamp,
  s.tx_hash,
  s.log_index,
  s.sender,
  s.recipient,
  s.amount0_dec,
  s.amount1_dec,
  pow(CAST(s.sqrtPriceX96 AS DOUBLE) / pow(2, 96), 2) AS price_token1_per_token0,
  CAST(s.tick AS INTEGER)                             AS tick,
  s.liquidity_dec
FROM pool__swap s
LEFT JOIN pools p            ON p.pool = s.address
LEFT JOIN pool_effective_fee f ON f.pool = s.address;
