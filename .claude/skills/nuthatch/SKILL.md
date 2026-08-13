---
name: nuthatch
description: Query this self-hosted nuthatch nest on bsc - decoded events, balances, and read-only SQL. Use when asked about on-chain activity for these contracts.
---

# Querying the nuthatch nest

Contracts indexed on bsc:
- `factory` = 0x10d8612D9D8269e322AB551C18a307cB4D6BC07B
- `pool_manager` = 0x391Eaa90f931C6330132efe6c73EBDf77d782eF5
- `position_manager` = 0x501535ef0B92eE1df5C12f47720f1E479b1Db7b4

Data is local - never call an external API for it.

## Preferred: MCP
If a `nuthatch` MCP server is configured, use its tools. Call `schema` first to learn the
data model, then `sql` / `entity` / `balance` / `top_balances`.

## Fallback: HTTP (a `nuthatch dev` must be running)
- Recent rows:  `curl localhost:8288/entities?limit=20`
- Read-only SQL: `curl -G localhost:8288/sql --data-urlencode 'q=SELECT count(*) FROM transfers'`

`sql` sees finalized data only; balances/entity cover the live tip.
