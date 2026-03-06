# Sprint 011 Merge Notes

## Claude Draft Strengths
- Rich product vision with named sub-zones (Starlight Glade, Moonwell Spring, Shadow Hollow) that add world flavor
- Clear retention loop articulation (brew more -> forage better -> brew rarer)
- Comprehensive implementation plan with MCP world building phases
- HUD "Forage Power" indicator (confirmed by interview)
- Detailed sub-zone loot pools

## Codex Draft Strengths
- Progressive unlock of EXISTING 12 nodes (4 starter, then 2 more at each threshold) — simpler, lower risk
- Stronger probability tables (more aggressive uncommon/rare scaling, especially at high tiers)
- Explicit rarity bucket splitting per node (not just one common pool + one uncommon pool)
- Statistical validation criteria (10k roll sampling, not "forage 20 times")
- Better risk analysis around economy impact

## Valid Critiques Accepted

1. **Base node pools contain non-commons** — Codex is correct. Nodes 6-12 already include uncommons like `glowshroom_cap`, `dewdrop_pearl`, `nightshade_berry`. The "0-star = common only" guarantee requires filtering these out at roll time OR acknowledging the existing mixed pools. Fix: at Tier 0, force common tier selection; existing mixed pools become the "bonus" at higher tiers.

2. **"Highest player in server" rare scaling is bad design** — Codex is correct. This violates the personal progression intent. Fix: use the TRIGGERING player's stars for rare node outcome, not server-wide max.

3. **Node ID validation should be strict** — Good catch. Current fallback to `{"mushroom"}` for unknown nodeIds is exploitable. Fix: whitelist validation for all node IDs.

4. **Shadow Hollow rare-only pools are too generous** — Valid concern. Fix: make Shadow Hollow pools mixed uncommon/rare (not pure rare).

5. **Statistical validation should be more rigorous** — Accepted. Use deterministic sampling (5k+ rolls per tier).

## Critiques Rejected (with reasoning)

1. **"Reduce scope to existing 12 nodes, no new sub-zones"** — Rejected. The user explicitly confirmed sub-zones during the interview. The 3 new sub-zones ARE the grove expansion feature. However, I'll adopt Codex's idea of ALSO progressively unlocking existing base nodes (start with 8 visible, unlock remaining 4 at thresholds), creating a dual progression: base nodes unlock + sub-zones unlock.

2. **"Modify ForageNodeFeedback instead of new controller"** — Rejected. ForageNodeFeedback handles cooldown animation only. Sub-zone barriers, unlock VFX, and the Forage Power HUD badge are distinct enough to warrant a separate GroveExpansionController.

## Interview Refinements Applied
- Cooldowns stay fixed at 60s (no star-based reduction)
- HUD "Forage Power" indicator when in WildGrove — show tier name + drop bonus
- Sub-zones confirmed as the right approach

## Final Decisions
- **Probability tables**: Use Codex's more aggressive scaling (0.40/0.45/0.15 at tier 4) but cap rare at 10% from regular nodes (compromise between my 8% and Codex's 15%)
- **Base node access**: All 12 base nodes accessible from start (keep backward compat with existing S008 world), but star-scaled drop tables apply
- **Sub-zones**: 3 new sub-zones (6 new nodes) at 10/25/50 star gates — as designed in Claude draft
- **Sub-zone pools**: Mixed uncommon/rare (not pure rare), with rarer ingredients at higher-threshold zones
- **Rare node scaling**: Per-triggering-player, not server-wide
- **Node ID validation**: Strict whitelist for all 18 node IDs
- **Forage Power HUD**: Badge showing tier name + bonus % when in WildGrove
- **Statistical verification**: 5k+ roll sampling per tier
