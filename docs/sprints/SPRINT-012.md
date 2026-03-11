# Sprint 012: Potion Arena — PvP Duels with Auto-Sim & Boost Mechanic

## Overview

The Potion Arena is the 5th zone in Brew a Potion, introducing opt-in PvP duels where players wager potions and fight using an auto-simulated combat system with a button-mash "Boost" mechanic. Combat power derives from potion rarity, mutation multipliers, and star count. The winner claims one potion from the loser's wagers and earns bonus stars.

This creates a potion sink (driving brewing), strategic decisions (sell or save for combat?), and shareable TikTok moments (dramatic fight reveals).

## Core Mechanic: Hybrid Auto-Sim + Boost

1. **Challenge**: Player interacts with Challenge Board in Arena zone, picks an opponent
2. **Loadout** (30s): Both players wager 1-3 potions from inventory. Each potion contributes combat power based on tier (Common=10, Divine=1000) × mutation multiplier
3. **Fight** (8s): Auto-simulated with escalating VFX + audio. Both players mash a big pulsing "BOOST!" button to add up to 20% bonus power. Energy bar fills with each click.
4. **Result**: Power compared with ±10% luck factor. Winner picks one potion from loser's wagers + earns 3 stars (5 for underdog wins)

## Combat Power Formula

```
PotionPower = sum of wagered potions (tier power × mutation multiplier)
StarBonus = StarCount × 1
BoostBonus = PotionPower × (clicks / 40) × 0.20
FinalPower = (PotionPower + StarBonus + BoostBonus) × random(0.90, 1.10)
```

## Entry Requirements

- Minimum 5 stars
- Minimum 5 potions in inventory
- 30-second cooldown between duels

## Files Created

| File | Purpose |
|------|---------|
| `src/shared/Config/ArenaTuning.lua` | Combat power values, timing, boost config, rewards |
| `src/server/Services/ArenaService.lua` | Server-authoritative matchmaking, wager escrow, fight resolution, rewards |
| `src/client/ArenaController.client.lua` | Challenge board UI, loadout picker, fight VFX/audio/boost button, result reveal |
| Arena zone (workspace) | Circular stone arena with rune floor, pillars, pedestals, challenge board |

## Key Design Decisions

- **No forced PvP**: Challenges require accept/decline
- **Wager escrow**: Potions removed from inventory during loadout, returned if duel cancelled
- **Disconnect forfeit**: Disconnecting player forfeits, potions returned to both
- **Boost rate-limiting**: 0.08s minimum between counted clicks (prevents autoclicker abuse)
- **Luck factor ±10%**: Prevents deterministic outcomes, creates upsets
