# Jungle world + player (Person 2)

Replace target is still [`game/states/overworld.tscn`](../game/states/overworld.tscn). Map and actor code live in `game/world/`.

The final display contract is **800×480 physical**, **200×120 logical**, and
`GameConfig.PIXEL_SCALE == 4`. World movement uses an **8px logical grid step**.
The jungle map is 50×30 tiles (400×240 logical pixels), so the camera can follow.

Licensed 16×16 atlases are loaded from:

- `res://assets/tiles/jungle_auto_ground.png`
- `res://assets/tiles/jungle_auto_water.png`
- `res://assets/tiles/jungle_objects.png`
- `res://assets/tiles/jungle_extra.png`
- `res://assets/tiles/beach_auto_water.png`
- `res://assets/tiles/beach_objects.png`
- `res://assets/sprites/player.png`

The jungle is the starting world. Walking the east log-bridge fades into the
beach boardwalk. Walking west off that boardwalk fades back to the jungle.

## Files

- [`game/world/world_map.gd`](../game/world/world_map.gd) — tiles, draw, collision, encounter zones, named regions, map id
- [`game/world/jungle_map_data.gd`](../game/world/jungle_map_data.gd) — deterministic 50×30 jungle layout
- [`game/world/beach_map_data.gd`](../game/world/beach_map_data.gd) — deterministic 50×30 beach layout
- [`game/world/player_actor.gd`](../game/world/player_actor.gd) — 16×20 sprite, 8×8 foot collision, facing, 8px grid steps
- [`game/states/overworld.gd`](../game/states/overworld.gd) — hosts map + camera + HUD + fade transitions

## Tile legend

| Value | Name | Walk | Encounter zone |
| --- | --- | --- | --- |
| 0 | path | yes | no |
| 1 | lawn | yes | no |
| 2 | tall grass | yes | **yes** |
| 3 | water | no | no |

Trees, rocks, field-station and dock-shelter doors, water, and ocean cells are
blocked independently of the visual tile ID. Buildings are scenery only: their
visible doors stay blocked and cannot be entered. Beach dune grass is the
beach encounter zone.

## Collision

`WorldMap.can_stand(world_pos, body)` tests the player's 8×8 lower-foot
collision footprint against blocked tiles. The 16×20 visual sprite can overlap
neighboring scenery without blocking a legal one-tile path. The player cannot
leave the map.

## Jungle regions

The named regions are `player_start`, `research_outpost`, `fossil_clearing`,
`pond`, `north_meadow`, `south_meadow`, `west_thicket`, `volcanic_exit`,
`snow_exit`, `desert_exit`, and `forest_exit`.

Only the jungle region is playable. The volcanic, snow, desert, and forest
markers are blocked signposts for future work.

## Encounter-zone API

Person 2 does **not** start battles and does **not** emit
`Events.encounter_triggered`.

Only **tall grass** is an encounter zone. Lawn and path are safe.

Person 3 owns the encounter-zone handoff and should:

1. Listen to `Events.player_moved(position)`
2. Ask `world.is_encounter_zone(position)` or `player.is_in_encounter_zone()`
3. Roll their own encounter chance
4. Emit `Events.encounter_triggered(creature)` when a fight should start

```
world.is_encounter_zone(world_pos) -> bool
world.is_blocked(world_pos) -> bool
world.world_to_tile(world_pos) -> Vector2i
world.spawn_position() -> Vector2
world.map_size_px() -> Vector2
world.regions["player_start" | "research_outpost" | "fossil_clearing" | "pond" |
              "north_meadow" | "south_meadow" | "west_thicket" |
              "volcanic_exit" | "snow_exit" | "desert_exit" | "forest_exit"]
player.is_in_encounter_zone() -> bool
player.is_moving() -> bool
```

## Player API

Session position/direction stay on `Game.player`. The actor writes them every move.

- 4 directions, no diagonals (`InputManager.move_vector()`)
- Stops as soon as input stops
- Faces the last move (eyes / back of head)
- Moves exactly 8 logical pixels per completed step
- Camera2D follows, clamped to the map

## How to test

Title → A → overworld. Walk the dirt path, push into hut doors or water
(movement must stop), step into dark bladed grass (HUD says `TALL GRASS`),
then return to the path (`SAFE`). C opens the menu stub and B returns to the
jungle at the saved position.
