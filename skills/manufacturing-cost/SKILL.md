---
name: manufacturing-cost
description: Estimate EVE Online manufacturing cost with the user's facilities and blueprints. Use when they ask whether to build an item or what it costs to manufacture.
---

# Manufacturing cost

1. Resolve the product with `bulk_lookup_types`.
2. Call `calculate_manufacturing_cost` with the type ID.
3. If they ask about owned blueprints first, use `get_user_blueprints`.
4. Compare build cost to sell prices from `get_market_orders_by_type` only when they ask about profit.
5. Quote the returned cost breakdown. Do not invent material prices.
