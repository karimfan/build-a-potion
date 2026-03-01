# Sprint 001 Intent: Core Alchemy Loop — Gather, Brew, Sell

## Seed

We will work on building the Brew a Potion game as outlined in brew_a_potion.md. We want to iteratively and incrementally build and release this game so it's playable at every iteration. Every iteration offers feedback and the ability to add/modify features. The md file is the north star — we may deviate as we build. This first sprint is the overarching plan and the first kernel of implementation.

## Context

- **Greenfield project**: No existing code, no CLAUDE.md, no prior sprints. The Roblox Studio place is either empty or default.
- **Roblox Studio MCP is connected**: We can run Luau code directly in Studio, insert marketplace models, start/stop play mode, and test in real-time.
- **Comprehensive design doc**: `brew_a_potion.md` covers the full vision — core loop, 4 zones, economy, social mechanics, monetization, 8-week roadmap, marketing strategy.
- **User priority**: Playable at every iteration. The user wants to experience the game as it grows, not wait for a big-bang delivery.

## Recent Sprint Context

No prior sprints exist. This is Sprint 001 — the foundation.

## Relevant Codebase Areas

Since this is greenfield, the relevant "codebase" is the Roblox Studio place itself. Key Roblox services we'll use:

- **Workspace** — Game world, map, physical objects
- **ServerScriptService** — Server-side game logic
- **ReplicatedStorage** — Shared modules, RemoteEvents/Functions
- **StarterGui** — UI screens (market, recipe book, sell interface)
- **StarterPack / StarterPlayer** — Player tools and character scripts
- **ServerStorage** — Server-only data (recipe database, ingredient definitions)
- **DataStoreService** — Player persistence (inventory, recipes, coins) — later sprints

## Constraints

- **Roblox/Luau only**: All game code is Luau, all assets live in Roblox Studio
- **MCP workflow**: We build by running code through the Roblox Studio MCP — creating instances, scripts, UIs programmatically
- **Mobile-first**: Roblox's primary audience is mobile. UI must work on small screens with touch input
- **Playable each sprint**: Every sprint must produce something the user can enter play mode and interact with
- **No external dependencies**: Everything must be self-contained in the Roblox place

## Success Criteria

Sprint 001 is successful if:

1. A player can spawn into a basic game world
2. There is an ingredient market where they can browse and buy ingredients (even if simple)
3. There is a cauldron they can interact with to combine ingredients
4. The brew produces a result (potion or sludge) based on the combination
5. There is a way to sell potions for coins
6. The coin balance updates and can be used to buy more ingredients
7. **The core loop is closed**: gather → brew → sell → gather again

## Verification Strategy

- **Play testing**: Enter play mode via MCP and walk through the full loop manually
- **Console output**: Print key events (purchase, brew result, sell) to verify logic
- **Economy sanity check**: Verify that selling a basic potion yields more coins than the ingredients cost (positive-sum for common recipes)
- **Edge cases**: Try brewing with insufficient ingredients, buying with insufficient coins, selling with empty inventory

## Uncertainty Assessment

- **Correctness uncertainty**: Low — the core loop is well-defined in the design doc
- **Scope uncertainty**: Medium — how much of the core loop can we fit in Sprint 001 while keeping it playable? We need to decide the minimum viable slice
- **Architecture uncertainty**: Medium — we need to establish the code architecture (module structure, client/server split, data flow) that all future sprints build on. Getting this wrong early is costly

## Open Questions

1. **How minimal is the MVP?** Should Sprint 001 have a full spatial world with zones, or can we start with a single-room prototype where market/cauldron/sell are all in one place?
2. **Data persistence**: Should Sprint 001 include DataStore saving, or is session-only state acceptable for the first iteration?
3. **UI approach**: Full ScreenGui-based UI, or proximity-based 3D interactions (click on cauldron, click on market stall), or both?
4. **How many recipes**: Should we implement the full recipe matrix from the doc, or start with 5-10 simple recipes to prove the system?
5. **Art level**: Placeholder boxes/parts, or should we insert marketplace models for a more polished feel from day one?
