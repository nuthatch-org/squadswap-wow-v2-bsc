-- SquadSwap's fee override layer, which vanilla Uniswap V3 does not have. A separate PoolManager
-- contract can set a per-pool fee that differs from the tier the pool was created with, and can
-- toggle that override on and off independently of setting it.
--
-- Both are event streams rather than state, so "the current override" is the latest row per pool.
-- A pool with a SetCustomFee but the toggle off is charging its launch fee, not the override:
-- reading the fee and ignoring the toggle is the obvious way to get this wrong.
--
-- FOOTGUN: `enabled` is a Solidity bool but is stored as exact text, so it holds the STRINGS
-- 'true' and 'false', not a SQL boolean. `WHERE enabled` and `COALESCE(enabled, false)` both fail
-- with a type error. Compare against the string, as below, to get a real boolean out.
CREATE VIEW pool_custom_fee_current AS
WITH latest_fee AS (
  SELECT pool, CAST(fee AS INTEGER) AS custom_fee, block_number, block_timestamp,
         row_number() OVER (PARTITION BY pool ORDER BY block_number DESC, log_index DESC) AS rn
  FROM pool_manager__set_custom_fee
),
latest_toggle AS (
  SELECT pool, (enabled = 'true') AS is_enabled, block_number,
         row_number() OVER (PARTITION BY pool ORDER BY block_number DESC, log_index DESC) AS rn
  FROM pool_manager__toggle_custom_fee
)
SELECT
  f.pool,
  f.custom_fee,
  COALESCE(t.is_enabled, FALSE) AS override_enabled,
  f.block_number                AS fee_set_block,
  f.block_timestamp             AS fee_set_at
FROM latest_fee f
LEFT JOIN latest_toggle t ON t.pool = f.pool AND t.rn = 1
WHERE f.rn = 1;

-- The fee each pool is actually charging: the override where one is set and enabled, otherwise the
-- tier it was created with. This is the column to use for anything fee-weighted.
CREATE VIEW pool_effective_fee AS
SELECT
  p.pool,
  p.token0,
  p.token1,
  p.launch_fee,
  c.custom_fee,
  COALESCE(c.override_enabled, FALSE) AS override_enabled,
  CASE WHEN COALESCE(c.override_enabled, FALSE) THEN c.custom_fee ELSE p.launch_fee END
    AS effective_fee
FROM pools p
LEFT JOIN pool_custom_fee_current c ON c.pool = p.pool;
