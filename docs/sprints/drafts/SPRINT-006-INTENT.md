# Sprint 006 Intent: Scoring, Leaderboard, Daily Demand, Progression, Non-Modal Brew Timer

## Seed

Multiple interconnected systems:
1. **Scoring system** — composite score from time played + potions brewed (rarity-weighted) + coins from selling. Real-time tracking. Leaderboard.
2. **Daily Demand Board** — 3 potions with 2x-5x bonus sell value, rotating daily. Strategic brewing decisions.
3. **Global announcements** — "[PlayerName] just brewed a Wish Potion!" for Divine/Mythic brews.
4. **Progression/Upgrades** — Better cauldrons (faster brew, higher mutation), more brew stations, storage expansion, shop decorations.
5. **Non-modal brew timer** — Brew timer as a small HUD element, not a full-screen modal. Player can walk around during brew.
6. **Progression curve** — Generous first 30 minutes, then gradual slowdown for monetization friction.

## Context

- All tracking is greenfield — no scoring, leaderboard, upgrades, or daily demand exist
- BrewStats (TotalBrewed, TotalValueBrewed, CurrentStreak, BestStreak) exist in V3 DataStore
- CauldronGui currently closes during brew — needs HUD-based brew timer instead
- EconomyService has base + mutation sell values — needs Daily Demand bonus layer
- DataStore V3 → V4 migration needed for score, upgrades, daily demand state

## Uncertainty: HIGH — 6 interconnected systems, scope is very ambitious

## Open Questions
1. Should upgrades use coins only or also Gems (premium currency)?
2. How many upgrade tiers for the cauldron?
3. Should the leaderboard be per-server, global, or both?
4. Should Daily Demand be server-specific or global (same for all players)?
