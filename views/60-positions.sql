-- Concentrated-liquidity positions as NFTs, from the NonfungiblePositionManager.
--
-- `tokenId` is the position NFT. Ownership is the latest Transfer for that id; minting shows as a
-- Transfer from the zero address and burning as a Transfer to it. `"from"` and `"to"` are SQL
-- keywords and must stay double-quoted.
CREATE VIEW position_owners AS
SELECT tokenId, owner, since_block, since_at
FROM (
  SELECT
    tokenId,
    "to"            AS owner,
    block_number    AS since_block,
    block_timestamp AS since_at,
    row_number() OVER (PARTITION BY tokenId ORDER BY block_number DESC, log_index DESC) AS rn
  FROM position_manager__transfer
)
WHERE rn = 1;

-- Net liquidity per position: everything added, minus everything removed. A position at zero has
-- been fully withdrawn but its NFT may still exist and still be owned.
CREATE VIEW position_liquidity AS
SELECT
  tokenId,
  SUM(liq)      AS net_liquidity_dec,
  SUM(amt0)     AS net_amount0_dec,
  SUM(amt1)     AS net_amount1_dec,
  MIN(first_bn) AS first_block,
  MAX(last_bn)  AS last_block
FROM (
  SELECT tokenId, liquidity_dec AS liq, amount0_dec AS amt0, amount1_dec AS amt1,
         block_number AS first_bn, block_number AS last_bn
  FROM position_manager__increase_liquidity
  UNION ALL
  SELECT tokenId, -liquidity_dec, -amount0_dec, -amount1_dec, block_number, block_number
  FROM position_manager__decrease_liquidity
)
GROUP BY tokenId;
