-- Per-pool activity summary: how busy each pool is and over what span. The first thing to look at
-- when asking "which of these pools actually matter", since a factory-discovered registry will
-- always contain a long tail of pools created once and never used.
CREATE VIEW pool_activity AS
SELECT
  p.pool,
  p.token0,
  p.token1,
  f.effective_fee,
  count(s.tx_hash)     AS swaps,
  min(s.block_number)  AS first_swap_block,
  max(s.block_number)  AS last_swap_block,
  max(s.block_timestamp) AS last_swap_at
FROM pools p
LEFT JOIN pool__swap s         ON s.address = p.pool
LEFT JOIN pool_effective_fee f ON f.pool = p.pool
GROUP BY p.pool, p.token0, p.token1, f.effective_fee
ORDER BY swaps DESC;
