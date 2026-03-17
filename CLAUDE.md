# Build a Potion — Development Workflow

## Architecture

```
GitHub Repo (source of truth)
    |
    v
Local Filesystem (src/)
    |
    v
Rojo Server (rojo serve) ──── port 34872 ───> Rojo Plugin (Studio)
                                                    |
                                                    v
                                              Roblox Studio
                                                    ^
                                                    |
                                          MCP Server (Studio plugin)
                                                    |
Claude Code <──── MCP Client ──────────────────────/
```

## Golden Rules

1. **All code changes go through local Lua files** — never modify Studio directly
2. **All changes must be committed to GitHub** — the repo is the source of truth
3. **Rojo syncs code to Studio** — this is the only path from code to Studio
4. **MCP is read-only for debugging** — use it to inspect, screenshot, read scripts, check console; never to write changes

## Rojo Setup

### File Naming Convention
- **Server scripts**: `.server.lua` → Rojo syncs as `Script` (auto-runs)
- **Client scripts**: `.client.lua` → Rojo syncs as `LocalScript`
- **Modules**: `.lua` → Rojo syncs as `ModuleScript` (must be `require()`d)

> **Critical**: All self-running server services must be `.server.lua`. Using `.lua` creates a ModuleScript that won't execute, leading to duplicate scripts if the rbxl already has a Script version.

### Workflow
1. Start the Rojo server: `rojo serve`
2. In Studio, open the Rojo plugin and click **Connect**
3. Edit `.lua` files locally — Rojo live-syncs to Studio
4. If the project file (`default.project.json`) changes, **disconnect and reconnect** the Rojo plugin
5. If scripts appear duplicated in Studio, delete the old rbxl-baked versions and keep the Rojo-managed ones, then save the place file

### Troubleshooting Rojo
- If changes don't appear in Studio, verify the plugin shows **Connected**
- If the port changed (after restarting `rojo serve`), reconnect the plugin
- Read the script in Studio via MCP `script_read` to verify the synced content
- Use `inspect_instance` to check if duplicate instances exist at the same path

## MCP (Roblox Studio Bridge)

The MCP server runs inside Studio and exposes tools to Claude Code.

### Safe to use (read-only / debugging)
- `list_roblox_studios` — check connection
- `search_game_tree` — find instances
- `inspect_instance` — read properties
- `script_read` / `script_search` / `script_grep` — read code in Studio
- `screen_capture` — see what the player sees
- `get_console_output` — check for errors
- `start_stop_play` — start/stop playtests

### Do NOT use for changes
- `execute_luau` — do not use to modify game state; all changes via Lua files + Rojo
- `multi_edit` — same; changes must be in version-controlled files

## Project Structure

```
src/
  server/
    Bootstrap.server.lua          — startup script, confirms services exist
    FallSafety.server.lua         — respawns players who fall below Y=-20
    Services/
      *.server.lua                — self-running server services
  client/
    *.client.lua                  — client-side controllers
  shared/
    Config/                       — shared configuration modules
    Types.lua                     — type definitions
default.project.json              — Rojo project mapping
```

## World Layout

- **Shop decorations** are built at **world origin** `(0, 0, -8)` by `WildGroveDecorationService`
- **Ground tiles** (`LegoGround/Tile`) provide collision at `Y=0` across the world
- The shop has an invisible collision floor (120x120) at origin
- The cauldron model lives in `Workspace.Zones.YourShop.Cauldron` but gets repositioned to the platform at origin at runtime

## Lighting

Rojo expects Color3 values as **0-1 floats**, not 0-255 integers. When setting colors in `default.project.json`, divide by 255:
- `[90, 75, 60]` (wrong) → `[0.353, 0.294, 0.235]` (correct)
