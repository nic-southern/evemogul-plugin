---
name: market-check
description: Check EVE Online market prices and orders through EVE Mogul. Use when the user asks about Jita or hub prices, spreads, or orders for an item.
---

# Market check

When the user asks about prices or orders:

1. Resolve item names with `bulk_lookup_types` before calling market tools.
2. Use `search_locations` if they name a station or system.
3. Use `get_market_orders_by_type` for regional or hub prices.
4. Use `get_market_orders` when they want one structure only.
5. Prefer best bid/ask and spread in the reply. Do not invent prices.
