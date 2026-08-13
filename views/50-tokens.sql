-- Every token appearing in any pool, ranked by how many pools reference it. A rough centrality
-- measure: the quote assets (WBNB, USDT, BUSD and friends) sort to the top.
--
-- Symbols and decimals need a contract call and are deliberately not indexed here; join a vendored
-- token list for human labels.
CREATE VIEW tokens AS
SELECT token, count(*) AS pools
FROM (
  SELECT token0 AS token FROM pools
  UNION ALL
  SELECT token1 AS token FROM pools
)
GROUP BY token
ORDER BY pools DESC, token;
