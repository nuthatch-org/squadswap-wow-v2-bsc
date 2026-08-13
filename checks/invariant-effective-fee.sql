-- Every registered pool must resolve to exactly one effective fee, and that fee must be positive.
-- Guards the custom-fee override join: a duplicate SetCustomFee or ToggleCustomFee row leaking past
-- the row_number() would fan pool_effective_fee out beyond one row per pool.
--
-- Deliberately expressed as DIFFERENCES rather than counts, so the fixture stays valid as the nest
-- indexes more history. A check whose expected value grows is a check that fails every day.
SELECT
  (SELECT count(*) FROM pool_effective_fee) - (SELECT count(*) FROM pools) AS unpriced_or_duplicated,
  (SELECT count(*) FROM pool_effective_fee WHERE effective_fee <= 0)       AS nonpositive_fees;
