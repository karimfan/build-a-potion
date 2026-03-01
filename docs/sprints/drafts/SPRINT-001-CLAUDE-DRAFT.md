# Sprint 001: Core Alchemy Loop — Gather, Brew, Sell

## Overview

This is the foundational sprint for Brew a Potion. The goal is to establish a **playable core loop** in the simplest possible form: a player spawns in, buys ingredients from a market, brews them in a cauldron to discover potions, and sells potions for coins to buy more ingredients.

We deliberately keep the scope tight — one cozy room/area rather than four separate zones, session-only state (no DataStore yet), and a small recipe set. The architecture, however, is designed to scale: a clean client/server split with shared data modules in ReplicatedStorage, server authority over economy and recipes, and RemoteEvents for all player actions. Every future sprint builds on this foundation.

The design philosophy mirrors the game design doc's own advice: "Get the loop right, get it live, and let real player data guide your iteration."

## Iterative Build Strategy (Overarching Plan)

Before diving into Sprint 001's implementation, here's how we envision the full game emerging across sprints:

| Sprint | Theme | What's Playable After |
|--------|-------|-----------------------|
| **001** | Core Loop MVP | Buy ingredients, brew potions, sell for coins — single room |
| **002** | World & Zones | 4-zone map (Shop, Market, Trading Post, Wild Grove) with teleportation |
| **003** | Progression & Upgrades | Cauldron tiers, brew timers, storage expansion, mutation system |
| **004** | Recipe Depth & Discovery | Full recipe matrix (50+), recipe book UI, discovery animations |
| **005** | Monetization | Gems currency, game passes, developer products, Daily Demand Board |
| **006** | Social Mechanics | Potion effects on players, gifting, ingredient stealing, shop visiting |
| **007** | Visual Polish & Audio | Particle effects, brewing animations, ambient sounds, weather |
| **008** | Persistence & Live Ops | DataStore saving, daily login rewards, weekly content drops, leaderboards |
| **009** | Launch Prep | Analytics, exploit prevention, mobile/Xbox testing, soft launch |

Each sprint produces a playable increment. We can reorder, split, or merge sprints based on feedback.

## Use Cases (Sprint 001)

1. **New Player Arrives**: Player spawns in a cozy alchemy room. They see a market stall, a cauldron, and a sell counter. No tutorial needed — the spatial layout guides them.
2. **Buy Ingredients**: Player walks to the market stall, clicks it, sees a list of available ingredients with prices. They start with 100 coins and can buy common ingredients (5-20 coins each).
3. **Brew a Potion**: Player walks to the cauldron, clicks it, sees their inventory. They drag/select 2 ingredients into the cauldron and click "Brew." The combination is checked against recipes. Success = potion appears in inventory. Failure = "Sludge."
4. **Sell a Potion**: Player walks to the sell counter, clicks it, sees their potions. They click "Sell" on a potion and receive coins.
5. **Loop Continues**: Player uses earned coins to buy more/better ingredients, tries new combinations, discovers new recipes.

## Architecture

```
┌─────────────────────────────────────────────┐
│                   CLIENT                     │
│                                              │
│  StarterGui/                                 │
│    MarketGui     - Buy ingredients UI        │
│    CauldronGui   - Brewing interface UI      │
│    SellGui       - Sell potions UI           │
│    HudGui        - Coin display, inventory   │
│                                              │
│  StarterPlayer/StarterPlayerScripts/         │
│    PlayerController - Proximity prompts,     │
│                       UI triggers            │
│                                              │
│  ReplicatedStorage/                          │
│    Shared/                                   │
│      IngredientData  - Ingredient definitions│
│      RecipeData      - Recipe combinations   │
│      PotionData      - Potion definitions    │
│                                              │
│  ─────── RemoteEvents / RemoteFunctions ─────│
│    BuyIngredient(ingredientId)               │
│    BrewPotion(ingredient1, ingredient2)      │
│    SellPotion(potionId)                      │
│    GetPlayerData() -> inventory, coins       │
│                                              │
│                   SERVER                     │
│                                              │
│  ServerScriptService/                        │
│    GameManager       - Player join/leave,    │
│                        session state         │
│    MarketService     - Buy validation,       │
│                        stock management      │
│    BrewingService    - Recipe lookup,         │
│                        brew logic            │
│    EconomyService    - Coin transactions,    │
│                        sell logic            │
│                                              │
│  ServerStorage/                              │
│    PlayerData/       - Runtime session data  │
│      {playerId} = {coins, ingredients,       │
│                     potions, recipes}        │
└─────────────────────────────────────────────┘
```

### Key Architecture Decisions

- **Server authority**: All economy actions (buy, brew, sell) are validated server-side. The client sends requests; the server validates and responds.
- **Shared data modules**: Ingredient, recipe, and potion definitions live in ReplicatedStorage so both client (for UI display) and server (for validation) can access them.
- **Session state**: Player data lives in a server-side table indexed by PlayerId. No DataStore in Sprint 001 — this keeps things simple and avoids quota issues during rapid testing.
- **Proximity-based interaction**: Players walk up to stations (market, cauldron, sell counter) and get proximity prompts. Clicking opens the relevant GUI. This is the "60-second hook" approach — the environment teaches.

## Implementation Plan

### Phase 1: Data Definitions & Server Infrastructure (~25%)

Define the shared data that drives the entire game, and set up the server-side session management.

**Files (Roblox instances):**
- `ReplicatedStorage/Shared/IngredientData` (ModuleScript) — Ingredient catalog
- `ReplicatedStorage/Shared/RecipeData` (ModuleScript) — Recipe combination mappings
- `ReplicatedStorage/Shared/PotionData` (ModuleScript) — Potion definitions and sell values
- `ReplicatedStorage/Remotes/` (Folder) — RemoteEvents and RemoteFunctions
- `ServerScriptService/GameManager` (Script) — Player session initialization

**Tasks:**
- [ ] Create IngredientData module with 8-10 starter ingredients across Common and Uncommon tiers
- [ ] Create RecipeData module with 10-12 recipes (ingredient combos → potion results)
- [ ] Create PotionData module with potion names, descriptions, sell values, rarity
- [ ] Create RemoteEvents: BuyIngredient, BrewPotion, SellPotion
- [ ] Create RemoteFunction: GetPlayerData
- [ ] Build GameManager that initializes player session data on join (100 starting coins, empty inventory)

**Starter Ingredients:**

| ID | Name | Tier | Cost | Element |
|----|------|------|------|---------|
| mushroom | Mushroom | Common | 10 | Earth |
| fern_leaf | Fern Leaf | Common | 8 | Earth |
| river_water | River Water | Common | 5 | Water |
| ember_root | Ember Root | Common | 15 | Fire |
| crystal_dust | Crystal Dust | Uncommon | 50 | Light |
| moonpetal | Moonpetal | Uncommon | 60 | Shadow |
| fire_salt | Fire Salt | Common | 12 | Fire |
| dewdrop | Dewdrop | Common | 7 | Water |

**Starter Recipes:**

| Ingredients | Result | Sell Value |
|-------------|--------|------------|
| Mushroom + River Water | Healing Salve | 25 |
| Ember Root + Crystal Dust | Fire Shield Elixir | 180 |
| Moonpetal + Dewdrop | Night Vision Tonic | 120 |
| Fern Leaf + River Water | Growth Potion | 30 |
| Fire Salt + Ember Root | Flame Draught | 45 |
| Mushroom + Crystal Dust | Glow Potion | 90 |
| Moonpetal + Fire Salt | Shadow Flame Brew | 150 |
| Fern Leaf + Mushroom | Forest Remedy | 20 |
| River Water + Dewdrop | Purification Elixir | 18 |
| Crystal Dust + Moonpetal | Starlight Serum | 200 |
| Any invalid combo | Sludge | 2 |

### Phase 2: Market System (~20%)

Build the ingredient market — the entry point of the core loop.

**Files:**
- `ServerScriptService/MarketService` (Script) — Server-side buy logic
- `StarterGui/MarketGui` (ScreenGui) — Market UI
- `StarterGui/MarketGui/MarketController` (LocalScript) — Client-side market logic

**Tasks:**
- [ ] Build MarketService: validate buy requests (check coins, deduct, add ingredient to inventory)
- [ ] Build MarketGui: scrollable list of ingredients with names, icons (colored frames), prices, and "Buy" buttons
- [ ] Build MarketController: send BuyIngredient remote, update UI on response
- [ ] Market GUI opens when player approaches market stall (ProximityPrompt)
- [ ] Show player's current coin balance in the market UI

### Phase 3: Brewing System (~25%)

The heart of the game — the cauldron where ingredients become potions.

**Files:**
- `ServerScriptService/BrewingService` (Script) — Server-side brewing logic
- `StarterGui/CauldronGui` (ScreenGui) — Brewing UI
- `StarterGui/CauldronGui/CauldronController` (LocalScript) — Client-side brewing logic

**Tasks:**
- [ ] Build BrewingService: receive 2 ingredient IDs, look up recipe, return potion or Sludge, deduct ingredients from inventory
- [ ] Build CauldronGui: show player's ingredients, two "slots" to select ingredients, a "Brew" button, and a result display
- [ ] Build CauldronController: manage ingredient selection, send BrewPotion remote, show result with a brief animation/effect
- [ ] Recipe lookup: sort ingredient pair alphabetically for consistent matching (A+B == B+A)
- [ ] Show "New Recipe Discovered!" feedback when a potion is brewed for the first time

### Phase 4: Sell System & HUD (~15%)

Close the loop — let players convert potions back to coins.

**Files:**
- `ServerScriptService/EconomyService` (Script) — Server-side sell logic
- `StarterGui/SellGui` (ScreenGui) — Sell interface
- `StarterGui/SellGui/SellController` (LocalScript) — Client-side sell logic
- `StarterGui/HudGui` (ScreenGui) — Persistent coin counter and inventory indicator

**Tasks:**
- [ ] Build EconomyService: validate sell requests, remove potion from inventory, add coins
- [ ] Build SellGui: show player's potions with names, values, and "Sell" buttons
- [ ] Build SellController: send SellPotion remote, update UI
- [ ] Build HudGui: always-visible coin counter in top corner, updates in real-time via remote events
- [ ] Add coin-change notification ("+25 coins" floating text on sell)

### Phase 5: Game World & Interaction (~15%)

Build the physical space and wire up proximity-based interactions.

**Files:**
- `Workspace/` — Physical game world (Parts, Models)
- `StarterPlayer/StarterPlayerScripts/PlayerController` (LocalScript) — Proximity prompt handling

**Tasks:**
- [ ] Build a cozy single-room alchemy shop: floor, walls, warm lighting
- [ ] Place a market stall model/part with ProximityPrompt → opens MarketGui
- [ ] Place a cauldron model/part with ProximityPrompt → opens CauldronGui
- [ ] Place a sell counter model/part with ProximityPrompt → opens SellGui
- [ ] Add basic ambient lighting (warm tones, point lights near cauldron)
- [ ] Set spawn point near the room entrance
- [ ] Build PlayerController to handle proximity prompt triggers and GUI visibility

## Files Summary

| Location | Type | Purpose |
|----------|------|---------|
| `ReplicatedStorage/Shared/IngredientData` | ModuleScript | Ingredient catalog (id, name, tier, cost, element) |
| `ReplicatedStorage/Shared/RecipeData` | ModuleScript | Recipe mappings (ingredient pair → potion id) |
| `ReplicatedStorage/Shared/PotionData` | ModuleScript | Potion catalog (id, name, description, sell value, rarity) |
| `ReplicatedStorage/Remotes/` | Folder | RemoteEvents and RemoteFunctions |
| `ServerScriptService/GameManager` | Script | Player session init, state management |
| `ServerScriptService/MarketService` | Script | Buy ingredient validation and execution |
| `ServerScriptService/BrewingService` | Script | Recipe lookup, brew execution |
| `ServerScriptService/EconomyService` | Script | Sell potion, coin management |
| `StarterGui/MarketGui` | ScreenGui + LocalScript | Ingredient market interface |
| `StarterGui/CauldronGui` | ScreenGui + LocalScript | Brewing interface |
| `StarterGui/SellGui` | ScreenGui + LocalScript | Potion selling interface |
| `StarterGui/HudGui` | ScreenGui + LocalScript | Persistent coin counter |
| `StarterPlayer/StarterPlayerScripts/PlayerController` | LocalScript | Proximity prompt → GUI triggers |
| `Workspace/Room` | Model | Physical game environment |

## Definition of Done

- [ ] Player spawns into a cozy room with visible market stall, cauldron, and sell counter
- [ ] Walking up to each station shows a proximity prompt
- [ ] Market shows available ingredients with prices; buying deducts coins and adds to inventory
- [ ] Cauldron shows inventory; selecting 2 ingredients and brewing produces correct potion or Sludge
- [ ] Sell counter shows potions; selling adds correct coin amount
- [ ] Coin balance displays in HUD and updates in real-time
- [ ] A player can complete the full loop: start with 100 coins → buy ingredients → brew → sell → buy again
- [ ] Economy is positive-sum for common recipes (selling a Healing Salve for 25 > buying Mushroom 10 + River Water 5)
- [ ] Server validates all transactions (no client-side cheating possible)
- [ ] Works in Roblox Studio play mode

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| MCP code injection is brittle for large scripts | Medium | High | Build incrementally, test each module before moving on |
| UI layout breaks on mobile aspect ratios | Medium | Medium | Use UDim2 scaling, test at multiple resolutions later |
| Recipe lookup edge cases (order, duplicates) | Low | Medium | Alphabetical sort on ingredient pairs, unit test via console |
| Session data lost on rejoin | High (by design) | Low | Acceptable for Sprint 001; DataStore comes in Sprint 008 |
| Scope creep into polish/animations | Medium | Medium | Strictly defer visual polish to later sprints |

## Security Considerations

- All economy transactions are server-authoritative — the client cannot set its own coin balance
- RemoteEvent inputs are validated (ingredient IDs must exist, player must have sufficient coins/items)
- No DataStore in this sprint, so no persistence-related exploits to worry about yet

## Dependencies

- None (first sprint, greenfield)
- Requires Roblox Studio running with MCP connected

## Open Questions

1. Should we use marketplace models for furniture/cauldron or build from primitives? (Marketplace models look better but add complexity)
2. How should we handle the recipe book tracking in this sprint — just a server-side set of discovered recipes, or also a viewable UI?
3. Should the market have a static inventory (all ingredients always available) or start with the rotating stock mechanic from the design doc?
