# World + player (Person 2)

Replace target is still [`game/states/overworld.tscn`](../game/states/overworld.tscn). Map and actor code live in `game/world/`.

Display is 480x800. Tiles are **32px**. The map is 20x26 tiles (640x832) so the camera can follow.

## Files

- [`game/world/world_map.gd`](../game/world/world_map.gd) — tiles, draw, collision, encounter zones, named regions
- [`game/world/player_actor.gd`](../game/world/player_actor.gd) — 24px actor, facing, 2-frame walk
- [`game/states/overworld.gd`](../game/states/overworld.gd) — hosts map + camera + HUD, keeps the menu key

## Tile legend

| Value | Name | Walk | Encounter zone |
| --- | --- | --- | --- |
| 0 | path | yes | no |
| 1 | lawn | yes | no |
| 2 | tall grass | yes | **yes** |
| 3 | tree | no | no |
| 4 | rock | no | no |
| 5 | water | no | no |

Double tree border. South dirt path is the spawn (gold square). Pond is north-east. Tall grass is darker with vertical blades.

## Collision

`WorldMap.can_stand(world_pos, body)` tests the player's body corners against blocked tiles. The player cannot leave the map.

## Encounter-zone API

Person 2 does **not** start battles and does **not** emit `ENCOUNTER_TRIGGERED`.

Only **tall grass** is an encounter zone. Lawn and path are safe.

Person 3 should:

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
world.regions["player_start" | "pond" | "north_meadow" | "south_meadow" | "west_thicket"]
player.is_in_encounter_zone() -> bool
player.is_moving() -> bool
```

## Player API

Session position/direction stay on `Game.player`. The actor writes them every move.

- 4 directions, no diagonals (`InputManager.move_vector()`)
- Stops as soon as input stops
- Faces the last move (eyes / back of head)
- Two-frame walk when moving
- Camera2D follows, clamped to the map

## How to test

Title → A → overworld. Walk the dirt path, push into trees/rocks/water (should stop), step into the dark bladed grass (HUD says TALL GRASS). C still opens the menu stub.
