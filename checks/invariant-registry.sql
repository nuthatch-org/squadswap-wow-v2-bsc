-- Every pool that has ever emitted a swap must exist in the factory registry. A failure here means
-- the factory discovery rule missed a child, which is the one way this nest can be quietly wrong:
-- events would be decoded into pool__* tables for an address the registry does not know about.
SELECT count(*) AS orphan_pools
FROM (SELECT DISTINCT address FROM pool__swap) s
LEFT JOIN pools p ON p.pool = s.address
WHERE p.pool IS NULL;
