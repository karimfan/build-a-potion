# Sprint 007 Claude Draft: Codex Critique

## Executive Summary

Claude’s draft captures the core fantasy direction and includes the major requested systems, but it is under-specified in architecture and acceptance criteria compared with recent sprint plan quality. The interview refinement (fixed shelf positions) is implicitly aligned, but should be explicitly locked as a non-negotiable scope anchor to prevent drift into customization work.

## What Claude Draft Gets Right

1. **Correct top-level scope**: Covers potion displays, Wild Grove expansion, market announcements, and physical Daily Demand Board.
2. **Strong thematic alignment**: Keeps the magical/fantasy art direction central across all zones.
3. **Actionable task lists**: Phase tasks are implementation-oriented and easy to execute.
4. **Interview-compatible shelf concept**: Uses three fixed shelf locations in the shop and auto-fill behavior.

## High-Severity Issues

1. **No explicit fixed-shelf constraint from interview finding**
- Draft describes three shelf locations but does not explicitly state that shelf positions are fixed for Sprint 007 and that customization is out of scope.
- Impact: team can unintentionally expand into user-placeable shelf/furniture mechanics, risking schedule and complexity.

2. **Definition of Done lacks measurable/technical acceptance checks**
- DoD is mostly feature-presence statements and visual judgments.
- Missing verifiable constraints like display slot cap enforcement, persistence behavior, trigger conditions for announcements, and regression gates.
- Impact: high risk of “looks done” without consistent behavior quality.

## Medium-Severity Issues

1. **Architecture section missing**
- No data model or flow description for display persistence and render mapping.
- Missing server/client ownership clarity for demand board and announcement logic.
- Impact: implementation decisions can diverge and increase integration bugs.

2. **File plan mixes conceptual workspace edits with code edits without integration contract**
- References `Workspace/Zones/*` plus Lua files, but does not define how authored world assets are discovered by runtime scripts (anchors, naming convention, fallback handling).
- Impact: brittle coupling between hand-authored parts and scripted rendering.

3. **Wild Grove expansion target is broad but not operationalized**
- States 240x240 and 12 nodes, but no collision/pathing/readability validation requirements.
- Impact: expanded map can ship with dead zones or blocked interactions.

## Low-Severity Issues

1. **No Risks & Mitigations section**
- Recent sprint style includes risk tables; this draft omits them.

2. **No Security Considerations section**
- Should confirm server authority for inventory/display persistence, demand state, and announcements.

3. **No Dependencies/Open Questions sections**
- Missing explicit ties to Sprint 005/006 systems and unresolved product decisions.

## Concrete Corrections Recommended

1. Add a hard scope anchor: **“Potion display shelves are fixed-position only in Sprint 007 (3 shelves, auto-fill, no manual placement/customization).”**
2. Add a brief architecture section with:
- `PotionDisplays` persistence shape,
- server claim flow -> data update,
- client fixed-slot render mapping,
- demand board data source/update path.
3. Tighten DoD with measurable checks:
- display cap (30) enforced,
- persistence verified across relog,
- market announcement fires only for Rare+ refresh,
- Wild Grove nodes all interactable/reachable,
- regression sweep for buy/forage/brew/sell.
4. Add standard sections consistent with recent style: Risks & Mitigations, Security, Dependencies, Open Questions.

## Final Assessment

Claude’s draft is directionally correct and production-usable as a task checklist, but it does not yet match the rigor of recent sprint docs. The two blocking fixes are: (1) explicitly lock the fixed-shelf interview decision, and (2) add architecture + measurable DoD criteria so implementation quality can be validated consistently.
