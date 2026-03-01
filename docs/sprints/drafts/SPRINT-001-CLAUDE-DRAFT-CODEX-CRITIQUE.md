# Sprint 001 Claude Draft - Codex Critique

## Overall Assessment

Claude's draft is internally coherent for a narrow MVP, but it is materially misaligned with the updated Sprint 001 intent and explicit interview constraints. The most important issue is that it plans a different sprint (single-room, session-only prototype) than the one requested (full 4-zone, rotating market, marketplace art, and DataStore persistence from day one).

## Findings (Ordered by Severity)

### 1) Critical: Direct violation of hard scope constraints

**Evidence**
- Single-room scope is explicit: lines 7, 17, 31, 199, 224, 228.
- 4-zone map deferred to Sprint 002: line 18.
- DataStore deferred to Sprint 008: line 24; also reaffirmed as session-only on lines 7, 88, 246, 253.
- Rotating market stock is optional/open question rather than committed: line 264.
- Marketplace model usage is optional/open question rather than committed: line 262.

**Why this matters**
These points conflict directly with the interview requirements and make the document non-executable as Sprint 001 planning input.

**Required correction**
Rebaseline Sprint 001 to include all four constraints as non-negotiable in Overview, Architecture, Implementation Plan, and Definition of Done.

### 2) High: Definition of Done validates the wrong product slice

**Evidence**
- DoD verifies a cozy single room (line 228) and omits 4-zone accessibility, 5-minute refresh behavior, and persistence checks.
- No rejoin validation criteria for persisted state.

**Why this matters**
Even perfect execution of this DoD would still fail stakeholder expectations for Sprint 001.

**Required correction**
Replace DoD with acceptance checks that explicitly test:
- 4-zone traversal and interactions,
- market refresh every 5 minutes,
- DataStore save/load for coins/inventory/recipe discovery.

### 3) High: Sprint sequencing creates architectural debt against current goals

**Evidence**
- Overarching strategy pushes world, persistence, and live-ops primitives to later sprints (lines 18 and 24).

**Why this matters**
Given the updated goals, deferring these systems forces rework (UI navigation, world interactions, data schema migration, economy assumptions).

**Required correction**
Move persistence, full world shell, and rotating stock into Sprint 001 foundation phases; keep later sprints focused on depth/polish, not fundamental rewrites.

### 4) Medium: Market system under-specifies scarcity behavior

**Evidence**
- Market tasks only cover static buy UI/validation (lines 150-155).
- Rotating stock is unresolved (line 264).

**Why this matters**
The 5-minute cadence is a core retention mechanic and a stated requirement, not a future enhancement.

**Required correction**
Add explicit global refresh scheduler, rarity-weighted offer generation, stock quantities, and client update broadcasting.

### 5) Medium: Persistence/security treatment is incomplete for day-one production shape

**Evidence**
- Session-only state is stored runtime-side with no crash/rejoin resilience (lines 78-80, 88).
- Security notes exclude persistence concerns because DataStore is deferred (line 253).

**Why this matters**
If persistence is mandatory in Sprint 001, save reliability and failure handling are part of core correctness.

**Required correction**
Add DataStore schema versioning, retry/backoff, autosave cadence, leave/close saves, and fallback behavior under transient failures.

## Strengths Worth Keeping

- Clean server-authoritative transaction posture (lines 86, 251-252).
- Good separation of market, brewing, and economy services (lines 67-75).
- Concrete starter content tables for ingredients/recipes (lines 112-139), useful as initial tuning seed.

## Merge Guidance

To merge with intent cleanly, keep Claude's service decomposition and starter content, but replace scope/sequencing with:

1. Full 4-zone world in Sprint 001.
2. Marketplace art integration in Sprint 001.
3. Rotating stock implementation (5-minute cadence) in Sprint 001.
4. DataStore persistence and rejoin validation in Sprint 001.

Without those changes, the draft should be considered out of scope for the requested sprint.
