# Sprint 013: Robux Shop — Developer Products for Potions & Ingredients

## Overview

Adds a full Robux monetization system using Roblox Developer Products (repeatable purchases). Players can buy ingredient packs, potion packs, and convenience items. Stars are NOT purchasable — they must be earned through brewing, preserving progression integrity and Arena balance.

## Product Catalog

### Ingredient Packs
| Product | Price | Contents |
|---------|-------|----------|
| Common Ingredient Pack | 25 R$ | 5 random Common ingredients |
| Uncommon Ingredient Pack | 75 R$ | 3 random Uncommon ingredients |
| Rare Ingredient | 199 R$ | 1 random Rare ingredient |
| Mythic Ingredient | 399 R$ | 1 random Mythic ingredient |

### Potion Packs
| Product | Price | Contents |
|---------|-------|----------|
| Common Potion Pack | 49 R$ | 3 random Common potions |
| Uncommon Potion Pack | 99 R$ | 2 random Uncommon potions |
| Rare Potion | 249 R$ | 1 random Rare potion |
| Mythic Potion | 499 R$ | 1 random Mythic potion |

### Convenience
| Product | Price | Effect |
|---------|-------|--------|
| Instant Brew | 19 R$ | Skip current brew timer instantly |
| Mutation Charm | 49 R$ | Guarantee mutation on next brew |

## Architecture

- **MarketplaceService.ProcessReceipt** callback on server validates and grants items
- All grants are server-authoritative — client only prompts purchase
- Mutation Charm stored as `data.Charms.MutationGuarantee` flag, consumed on next brew claim
- Instant Brew sets `ActiveBrew.EndUnix = os.time()` making it immediately claimable
- Global announcements for Rare+ purchases

## Setup Required

Product IDs in `RobuxShopTuning.lua` are currently `0` (placeholder). Before publishing:
1. Go to Creator Dashboard > Your Game > Monetization > Developer Products
2. Create each product with matching name and Robux price
3. Copy the Product IDs into `RobuxShopTuning.Products[n].productId`

## Files

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/RobuxShopTuning.lua` | Create | Product catalog, pricing, grant definitions |
| `src/server/Services/RobuxShopService.lua` | Create | ProcessReceipt handler, item grant logic |
| `src/client/RobuxShopController.client.lua` | Create | Shop UI with categories, buy buttons, HUD access |
| `src/server/Services/BrewingService.lua` | Modify | Mutation Charm integration |
