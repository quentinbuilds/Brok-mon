# Jungle Overworld Design

## Goal

Replace the prototype overworld with a polished, original, dinosaur-themed jungle map that evokes the readability and top-down composition of GBA-era monster-catching games.

The MVP contains one playable biome: jungle. Later volcanic, snowy mountain, desert, and forest regions remain future work.

## Visual and resolution contract

- Physical Arduino display: 800×480, landscape.
- Logical game canvas: 200×120.
- Integer scale: exactly 4×.
- Terrain grid: 8×8 logical pixels.
- Player footprint: one tile; visible sprite approximately 16×20 logical pixels.
- Texture filtering: nearest-neighbor.
- Camera positions and moving sprites snap to integer logical pixels.

The 200×120 size is the render resolution for the whole game, not the maximum size of each asset.

## Intellectual-property boundary

Poke Nexus and Pokémon FireRed are composition and readability references only.

The project will not copy or redistribute their tiles, sprites, maps, logos, characters, names, or audio. All committed assets will be original or explicitly licensed for this project. The visual language may use genre conventions such as top-down paths, tile-based vegetation, dark tall grass, and compact GBA-era proportions.

## Direction

Use the Expedition Trail layout:

- A winding dirt trail leads from the player spawn through the jungle.
- Two small research huts establish a dinosaur expedition outpost.
- Hut walls and doors are solid; interiors and door interaction are absent in the MVP.
- Three visually distinct tall-grass clearings serve as encounter zones.
- A pond or river edge provides a strong landmark.
- A fossil shrine or excavation clearing provides the central dinosaur-themed point of interest.
- Cycads, giant ferns, palms, vines, rocks, bones, eggshell fragments, and dinosaur footprints distinguish the biome from a generic forest.
- Dense vegetation forms the map boundary.
- Blocked routes visually foreshadow later volcanic, snowy mountain, desert, and forest regions without making those biomes playable.

The playable map is approximately 50×30 terrain tiles, or 400×240 logical pixels. The 200×120 camera therefore exposes roughly one quarter of the map at a time. A player should understand the main route quickly and explore the map in one to two minutes.

## Rendering approach

Use a hybrid, original asset-atlas approach:

1. Create original terrain, vegetation, building, fossil, and player pixel-art atlases.
2. Keep map layout as deterministic tile data.
3. Render terrain and props in separate layers so the player can pass behind tall foreground foliage.
4. Keep collision and encounter metadata independent of visible tile IDs.

This replaces the current procedural rectangle drawing. It preserves the current data-driven API while producing coherent art that can be iterated independently.

Recommended scene hierarchy:

```text
Overworld
├── WorldMap
│   ├── Ground
│   ├── EncounterGrass
│   ├── PropsBack
│   ├── Collision
│   ├── Player
│   └── PropsFront
└── HUD
```

## Player movement

Movement changes from continuous motion to FireRed-style grid steps:

- One directional input starts one 8px tile step.
- The visual move interpolates quickly between tile centers.
- A held direction repeats after a short initial delay.
- Input cannot start a second move while a step is in progress.
- Only four cardinal directions are supported.
- The player faces the attempted direction even when collision blocks the step.
- `Events.player_moved(position)` emits once after each completed successful step.
- The player stops exactly on the tile grid.

The camera follows the player without fractional smoothing and clamps to map bounds.

## Collision and houses

Collision metadata marks trees, rocks, water, cliffs, hut walls, hut doors, fossil barriers, and map boundaries as blocked.

Houses have visible doors, but the door tiles remain blocked. Pressing the action button at a door has no effect in this MVP.

The player must never enter blocked tiles or move outside the map.

## Encounter zones

Only tall grass is an encounter zone. Regular jungle floor and dirt paths are safe.

Person 2 owns detection but not random encounter logic:

- `world.is_encounter_zone(world_pos) -> bool`
- `world.is_encounter_zone_tile(tile) -> bool`
- `player.is_in_encounter_zone() -> bool`

Person 3 listens to `Events.player_moved`, queries the world, applies probability and cooldown, then emits `Events.encounter_triggered(creature)`.

## Stable integration API

Preserve these existing methods:

```text
world.map_size_px() -> Vector2
world.spawn_position() -> Vector2
world.world_to_tile(world_pos) -> Vector2i
world.tile_center(tile) -> Vector2
world.is_blocked(world_pos) -> bool
world.is_encounter_zone(world_pos) -> bool
world.can_stand(world_pos, body) -> bool
player.is_moving() -> bool
player.is_in_encounter_zone() -> bool
```

Named regions include:

```text
player_start
research_outpost
fossil_clearing
pond
north_meadow
south_meadow
west_thicket
volcanic_exit
snow_exit
desert_exit
forest_exit
```

## Files

- Modify `game/project.godot`: 200×120 viewport, 800×480 window override, nearest filtering.
- Modify `game/config/game_config.gd`: logical and physical display constants plus 4× scale.
- Replace `game/world/world_map.gd`: jungle tile data, layered rendering, collision, regions.
- Replace `game/world/player_actor.gd`: grid-step movement and directional animation.
- Modify `game/states/overworld.gd`: pixel-snapped camera and minimal debug HUD.
- Create original files under `game/assets/tiles/`, `game/assets/sprites/`, and `game/assets/backgrounds/`.
- Update `game/tests/autopilot/world_player.gd`: movement, grid alignment, collision, grass, and display assertions.
- Update `docs/world.md` and `docs/architecture.md`.

The duplicate untracked `gok-mon-(4.6)/` directory is not part of the implementation and must not become a second project source.

## Verification

Automated checks must prove:

1. The viewport is 200×120 and scales to 800×480.
2. The player spawns in the jungle on a walkable path.
3. Every completed move changes position by exactly one 8px tile.
4. Holding a direction repeats moves without leaving the grid.
5. Trees, rocks, water, map edges, hut walls, and hut doors block movement.
6. Tall grass reports an encounter zone; ordinary jungle floor and paths do not.
7. The menu transition still works.
8. No Summer/GDScript diagnostics occur during the probe.

Visual verification captures the spawn, research huts, fossil clearing, tall grass, pond, and a blocked house door at native logical resolution and at the 4× physical scale.

## Out of scope

- House interiors or entering houses
- NPCs and dialogue
- Real encounters, creature selection, or battle logic
- The four later biomes
- Map transitions
- Cutscenes, quests, shops, or item pickups
- Direct reuse of Poke Nexus or Pokémon assets
