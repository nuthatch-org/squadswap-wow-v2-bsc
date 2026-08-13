-- A fixed, fully-sealed slice of history. Counts here must not move once the range is sealed, so a
-- change means either a reorg reached into sealed data (it must not) or the decode registry changed.
SELECT
  count(*)                     AS swaps,
  count(DISTINCT address)      AS pools_swapped,
  min(block_number)            AS first_block,
  max(block_number)            AS last_block
FROM pool__swap
WHERE block_number BETWEEN 46190543 AND 47000000;
