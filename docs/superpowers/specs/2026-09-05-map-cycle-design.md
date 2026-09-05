# House–Beach Map Cycle Design

## Goal

Use the two approved Summer Library assets as playable maps without changing the core state machine or existing gameplay contracts.

The repeating route is:

`Default exterior → house interior → beach exterior → house interior → default exterior`

## Approach

Keep one `OverworldState` and the existing player, camera, menu, NPC, and encounter integration. The world subsystem owns a small map-mode controller with three modes: default, interior, and beach. It swaps only presentation, collision queries, spawn tiles, camera bounds, and encounter-zone reporting.

This is preferred over creating new core game states because `GameState` intentionally has only one overworld state and may not be edited by this subsystem. It is also preferred over duplicating the full overworld scene because duplicated player and encounter logic would drift.

## Scene and Data Changes

- Import Summer assets `eb413fbc-28cd-4ed2-ba4c-d7b50d19c03a` and `d30329db-65fd-42b0-a3af-e4744af3a458` under `assets/backgrounds/`.
- Add background sprite nodes for the beach and interior to `OverworldState.tscn`; only the active map presentation is visible.
- Retain the existing default `TileMapLayer`, house, NPCs, player, camera, HUD, and encounter system.
- Add pure world-owned map data describing each new map's walkable grid, entry/exit trigger, spawn, bounds, and encounter zones.
- Extend `Player.gd` with an optional walkability callback. Its default remains `GrassMap.is_walkable`, preserving existing callers and tests.

## Map Flow

The initial exterior is default and the next exterior is beach.

1. Stepping onto the default house door enters the interior and places the player just inside its exit.
2. Stepping onto the interior exit changes to the remembered next exterior, initially beach, and flips the remembered exterior to default.
3. Entering the beach house returns to the same interior.
4. Exiting changes to default and flips the remembered exterior back to beach.
5. The sequence repeats for the session.

Each transition cancels active movement, moves the player to a safe map-specific spawn, updates camera limits, and emits no encounter roll for the transition itself.

## Gameplay and Safety

- Movement remains four-direction grid movement through `InputManager`.
- Menu behavior remains available on every map.
- NPC dialogue remains available wherever NPCs are visible.
- Default and beach maps report their configured encounter tiles through the existing `EventBus.player_moved` signal. The interior reports no encounter zones.
- No changes are made to `core/` or `project.godot`.
- Invalid saved positions fall back to the active map's spawn.

## Verification

- Unit tests cover map cycling, per-map collision selection, safe spawns, and indoor encounter suppression.
- Existing world, menu, battle, and encounter tests remain green.
- Runtime playtest walks through the complete cycle twice and confirms movement, menu access, camera bounds, and unchanged encounter integration.
