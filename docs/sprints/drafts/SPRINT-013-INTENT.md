# Sprint 013 Intent: Robux Shop — Developer Products for Potions & Ingredients

## Seed

Support buying potions and ingredients with Robux. No star purchases — stars must be earned through brewing.

## Key Decisions (from interview)

- All items are Developer Products (repeatable purchases)
- Budget-friendly pricing: 25-499 Robux
- NO star purchases — only potions and ingredients
- Must use MarketplaceService:PromptProductPurchase / ProcessReceipt pattern

## Product Catalog

### Ingredient Packs
- Common Ingredient Pack (5 random commons): 25 Robux
- Uncommon Ingredient Pack (3 random uncommons): 75 Robux
- Rare Ingredient Pack (1 random rare): 199 Robux
- Mythic Ingredient (1 random mythic): 399 Robux

### Potion Packs
- Common Potion Pack (3 random commons): 49 Robux
- Uncommon Potion Pack (2 random uncommons): 99 Robux
- Rare Potion (1 random rare): 249 Robux
- Mythic Potion (1 random mythic): 499 Robux

### Convenience
- Instant Brew (skip current brew timer): 19 Robux
- Mutation Charm (guarantee mutation on next brew): 49 Robux

## Architecture

Uses Roblox MarketplaceService with ProcessReceipt callback pattern.
Server-authoritative: receipt validation -> item grant -> save -> acknowledge.
