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
| `overworld_tileset.tres` | Generated TileSet over the tile atlas. |
| `tools/gen_art.gd` | Generates `assets/tiles/overworld.png` and `assets/sprites/player.png`. |
| `tools/gen_tileset.gd` | Generates `overworld_tileset.tres`. |

Tests live in `tests/test_world.gd`.

## The map

40 x 30 tiles of 8 px = 320 x 240 px, so a little over two screens of the 200 x 120
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

Movement is one tile per step at `STEP_TIME` (0.14 s, about 57 px/s), four directions only.
Holding a direction chains steps with no pause; releasing stops at the next tile boundary,
so the player always rests tile-aligned. Positions are rounded to whole pixels because
sub-pixel sprites shimmer badly at this resolution.

The sprite sheet is 8 frames of 8x12: `DIR_ROW[facing] * 2 + sub_frame`, where sub-frame 0
is mid-stride and 1 is feet together. Idle rests on feet together.

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

The art is generated so the palette stays in one place. After changing `tools/gen_art.gd`:

```sh
S=/Applications/Summer.app/Contents/MacOS/Summer
$S --headless --disable-crash-handler --path . -s res://world/tools/gen_art.gd
$S --headless --path . --import
$S --headless --disable-crash-handler --path . -s res://world/tools/gen_tileset.gd
```

The four-shade palette lives in `gen_art.gd`'s `PAL`. Person 6 owns the final look; this is
a coherent starting point, not a claim on the art direction.
