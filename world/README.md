# world/ — grassland map, player, camera, encounter zones

Owner: Person 2. Scope is PRD §6 only: the map, the player, collision, the camera, and
reporting encounter zones. No encounter rolls, no battle, no menu UI.

## Files

| File | Purpose |
|---|---|
| `GrassMap.gd` | Map data (ASCII) plus `is_walkable` / `is_encounter_zone` / `atlas_coords`. Pure data, no nodes. |
| `Player.gd` | Grid-stepping player sprite. Owns stepping and animation, reads no input. |
| `OverworldState.gd` | The `GameStateBase` state. Paints the map, drives the player, moves the camera, emits `player_moved`. |
| `OverworldState.tscn` | `Tiles` (TileMapLayer) + `Player` (Sprite2D) + `Camera` (Camera2D). |
| `overworld_tileset.tres` | TileSet over the compact Studio-derived tile atlas. |
| `tools/prepare_studio_assets.gd` | Rebuilds the runtime tile and trainer atlases from the original Studio sheets. |

Tests live in `tests/test_world.gd`.

## The map

40 x 30 tiles of 16 px = 640 x 480 px, so the camera reveals a compact section of the 200 x 120
viewport. Small and dense on purpose: crossing it takes about a minute.

The map is ASCII in `GrassMap.MAP`, one character per tile, and is edited by hand:

```
.  grass          :  tall grass (encounter zone)   =  path       ,  flowers
T  tree (blocked) o  rock (blocked)                ~  water (blocked)
#  hedge (blocked, forms the border)
```

Rules the tests enforce, so a bad edit fails `tests/run.sh` rather than the demo:

- every row is exactly `WIDTH` characters and there are exactly `HEIGHT` rows
- the outer ring is solid, so the player can never walk off the map
- every glyph has an atlas column
- every walkable tile is reachable on foot from `START_TILE`
- every tall-grass tile is walkable

## Collision

There are no physics bodies or collision shapes in the overworld. A tile is walkable when
its glyph is in `GrassMap.WALKABLE`, and the player checks the target tile before each step.
Out-of-bounds reads as hedge, so callers never need their own bounds check.

This is deliberate: movement is grid-locked, so a glyph lookup is both cheaper and more
predictable than a physics query, and it can be unit-tested with no scene at all.

## Player API

`Player.gd` extends `Sprite2D`. `OverworldState` is the only caller.

```
place(tile: Vector2i)          teleport, cancel any step in progress
is_stepping() -> bool          true while a step is in flight
try_step(dir: Vector2i) -> bool  turn to face dir, begin a step if the target is walkable
advance(delta: float) -> bool  progress a step; true on the frame it completes
tile: Vector2i                 the tile the player occupies (commits when a step starts)
facing: Vector2i               UP / DOWN / LEFT / RIGHT
```

Movement is one tile per step at `STEP_TIME` (0.14 s, about 114 px/s), four directions only.
Holding a direction chains steps with no pause; releasing stops at the next tile boundary,
so the player always rests tile-aligned. Positions are rounded to whole pixels because
sub-pixel sprites shimmer badly at this resolution.

The Studio-derived sprite sheet is 8 frames of 16x20: `DIR_ROW[facing] * 2 + sub_frame`,
where sub-frame 0 is mid-stride and 1 is feet together. Idle rests on feet together. The
left-facing animation mirrors the matching right-facing Studio profile.

## Encounter-zone API (for Person 3)

Prefer the signal. It fires once per completed tile step, which is exactly one encounter
roll:

```
EventBus.player_moved(tile: Vector2i, in_encounter_zone: bool)
```

`in_encounter_zone` is true when the tile the player just stepped onto is tall grass.
Blocked moves emit nothing, so bumping a tree is not a roll.

Two queries are also available when you need to ask rather than listen:

```
GrassMap.is_encounter_zone(tile) -> bool   static, needs no node reference
OverworldState.is_in_encounter_zone()      the player's current tile
```

`GameData.player_tile` always holds the player's tile, so returning from a battle resumes
exactly where the player left off.

## Camera

`Camera2D` centred on the player's tile with `limit_*` set to the map bounds, so the view
never shows past the edge of the map. No smoothing: a hard follow matches the era.

## Regenerating the art

The compact runtime atlases are deterministically cut from the original Summer Studio
compositions. After replacing either source sheet, run:

```sh
S=/Applications/Summer.app/Contents/MacOS/Summer
$S --headless --disable-crash-handler --path . -s res://world/tools/prepare_studio_assets.gd
$S --headless --disable-crash-handler --path . --import --quit-after 60
```

The source files are `assets/studio/overworld_tileset.png` and
`assets/studio/trainer_walk.png`; the generated runtime files are committed for reliable
loading and export.
