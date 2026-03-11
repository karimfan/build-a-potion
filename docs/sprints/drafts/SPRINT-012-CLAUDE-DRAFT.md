# Sprint 012: Potion Arena — PvP Duels with Auto-Sim & Boost Mechanic

## Overview

The Potion Arena is a new 5th zone where players wager potions in 1v1 duels. Combat power comes from potion rarity, mutation multipliers, and star count. The fight auto-simulates over 8 seconds with dramatic VFX, but both players can rapidly click/tap a "Boost" button during the animation to add up to 20% bonus power — creating excitement and a feeling of participation without real combat.

The winner takes one potion of their choice from the loser's wagered set and earns bonus stars. This creates a potion sink (driving players back to brew), strategic decisions (sell that Mythic or save it as a weapon?), and shareable TikTok moments (dramatic reveal of who wins).

## Use Cases

1. **Player challenges another**: Walks to Arena, interacts with Challenge Board, selects opponent from server player list. Opponent gets notification with accept/decline.
2. **Loadout phase**: Both players pick 1-3 potions from inventory. 30-second timer. UI shows each potion's combat power contribution.
3. **Fight phase**: 8-second auto-simulation with escalating VFX. Both players mash "BOOST!" button. Click counter visible, energy bar fills.
4. **Result reveal**: Dramatic slow-mo moment, winner announced with VFX explosion. Winner picks one potion from loser's wagered potions.
5. **Reward**: Winner gets chosen potion + 3 bonus stars (5 if beating higher-star opponent). Global announcement for Mythic+ potion stakes.
6. **Decline**: Player can always decline a challenge. No forced PvP.
7. **Disconnect**: If a player disconnects mid-duel, they forfeit — opponent wins automatically.

## Architecture

### Combat Power Formula

```
PlayerPower = PotionPower + StarBonus + BoostBonus

PotionPower = sum of each wagered potion's combat value:
  Common: 10, Uncommon: 25, Rare: 80, Mythic: 250, Divine: 1000
  × mutation multiplier (Glowing 2x, Bubbling 2.5x, ... Golden 10x)

StarBonus = StarCount × 1 (flat 1 power per star)

BoostBonus = PotionPower × (boostClicks / maxClicks) × 0.20
  maxClicks = 40 (in 8 seconds = 5 clicks/sec achievable)
  So boost adds 0-20% of base potion power

FinalPower = (PotionPower + StarBonus + BoostBonus) × randomModifier
  randomModifier = random(0.90, 1.10) — ±10% luck factor
```

### Duel Flow (Server-Authoritative)

```
1. Challenger fires ChallengePlayer(targetUserId)
   → Server validates both players exist, not in duel, have potions
   → Server sends challenge notification to target

2. Target accepts via AcceptChallenge(challengerId)
   → Server creates DuelSession { state="loadout", players, timer }
   → Both clients enter loadout UI

3. Both players fire WagerPotion(potionId) up to 3 times
   → Server validates ownership, moves potion to wager escrow
   → Server broadcasts wager state to both clients

4. Timer expires or both confirm → state="fighting"
   → Server sends FightStart to both clients
   → 8-second timer begins

5. During fight, clients fire BoostClick() rapidly
   → Server counts clicks per player (rate-limited to 8/sec max)

6. Timer expires → Server computes power, determines winner
   → Server sends FightResult to both clients + spectators

7. Winner fires ClaimReward(potionId) to pick from loser's wagers
   → Server transfers potion, awards stars
   → Global announcement if Mythic+ potion involved
```

### New Service: ArenaService

```
_G.ArenaService
  - challengePlayer(challenger, targetId)
  - acceptChallenge(target, challengerId) / declineChallenge(...)
  - wagerPotion(player, potionId)
  - confirmLoadout(player)
  - registerBoostClick(player)
  - claimReward(winner, potionId)
  - getDuelState(player) → current duel info

DuelSession = {
    id, state ("pending"/"loadout"/"fighting"/"result"/"done"),
    player1 = { userId, wagers={}, boostClicks=0, power=0 },
    player2 = { userId, wagers={}, boostClicks=0, power=0 },
    winnerId, startUnix, phaseEndUnix
  }
```

### New Config: ArenaTuning.lua

```lua
ArenaTuning.PotionCombatPower = { Common=10, Uncommon=25, Rare=80, Mythic=250, Divine=1000 }
ArenaTuning.StarPowerMultiplier = 1
ArenaTuning.MaxWagers = 3
ArenaTuning.LoadoutSeconds = 30
ArenaTuning.FightSeconds = 8
ArenaTuning.MaxBoostClicks = 40
ArenaTuning.BoostMaxPercent = 0.20
ArenaTuning.LuckRange = {0.90, 1.10}
ArenaTuning.WinnerStars = 3
ArenaTuning.UnderdogStars = 5
ArenaTuning.DuelCooldownSeconds = 30
```

### New Client: ArenaController.client.lua

Handles:
- Challenge Board UI (player list, challenge button)
- Challenge received notification (accept/decline)
- Loadout UI (potion picker, power preview, timer)
- Fight animation (escalating VFX, boost button, click counter)
- Result reveal (winner announcement, potion claim UI)

### Arena Zone (5th zone in workspace)

- Circular stone arena with glowing rune floor
- Challenge Board (ProximityPrompt)
- Two player pedestals (where fighters stand during animation)
- Spectator area around the edge
- Connected to other zones via path

## Implementation Plan

### Phase 1: ArenaTuning Config + ArenaService Core (~25%)

**Files:**
- `src/shared/Config/ArenaTuning.lua` — Create
- `src/server/Services/ArenaService.lua` — Create
- `default.project.json` — Register both
- `src/server/Bootstrap.server.lua` — Add ArenaService

### Phase 2: Arena Zone World Build (~15%)

**Files:**
- Workspace via MCP — Build arena zone with paths, pedestals, challenge board

### Phase 3: ArenaController Client — Matchmaking + Loadout (~20%)

**Files:**
- `src/client/ArenaController.client.lua` — Create
- `default.project.json` — Register

### Phase 4: Fight Simulation + Boost Mechanic (~15%)

**Files:**
- `src/server/Services/ArenaService.lua` — Fight resolution logic
- `src/client/ArenaController.client.lua` — Boost button, click tracking

### Phase 5: Fight VFX + Audio (~15%)

**Files:**
- `src/client/ArenaController.client.lua` — VFX emitters, sound layers, result reveal

### Phase 6: Reward + Announcements (~10%)

**Files:**
- `src/server/Services/ArenaService.lua` — Potion transfer, star award
- Integration with GlobalAnnouncement, PlayerDataService
