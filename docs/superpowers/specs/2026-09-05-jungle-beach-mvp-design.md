# Jungle → Beach Two-Biome MVP Design

**Status:** Approved design specification
**Date:** 2026-09-05
**Scope:** Design documentation only

## Relationship to the prior jungle specification

This specification extends
`docs/superpowers/specs/2026-09-05-jungle-overworld-design.md`.
It supersedes only that document's statements that the MVP is jungle-only, that
later biomes are all non-playable, and that map transitions are out of scope.
The beach is now the second playable world and the jungle's east exit is now an
active bridge checkpoint.

All other applicable contracts from the prior specification remain in force,
including the display resolution, 8px grid movement, integer pixel snapping,
independent visual/collision/encounter data, completed-step
`Events.player_moved(position)` semantics, stable public world/player methods,
blocked building doors, and the separation between encounter-zone detection and
battle ownership.

## Goals

- Deliver two polished, original top-down creature-RPG worlds with the
  readability of FireRed-era composition without copying Pokémon maps or assets.
- Make the jungle the initial world and the beach the next world.
- Give each world a complete, legible 25×15 visual-tile layout occupying
  400×240 logical pixels.
- Connect the maps through a clear east-side jungle log bridge, a short fade,
  and a beach boardwalk arrival, with a reciprocal return route.
- Use the user's licensed 16×16 jungle and beach tile packs coherently,
  including buildings assembled from matching wood and boardwalk material.
- Preserve existing movement, collision, encounter-zone, camera, state-machine,
  and integration contracts wherever the new map boundary does not require an
  extension.
- Keep map content deterministic and make map replacement safe across menu,
  battle, catching, and other overworld state recreation.

## Non-goals

- Battles, creature selection, encounter probability, encounter cooldowns, or
  changes to `Events.encounter_triggered`.
- More biomes, interiors, enterable buildings, NPCs, dialogue, quests, shops,
  items, cutscenes, or scripted bridge interactions.
- Seamless scrolling between maps; both directions use the same short fade.
- Diagonal or free movement, changes to movement timing, or changes to the 8px
  collision footprint.
- A new save-file format or disk persistence. The required persistence is
  session state on `Game.player`, consistent with the current project.
- Recreating, tracing, or redistributing Pokémon maps, tiles, characters, names,
  or other protected content.
- An implementation plan. This document defines the approved behavior and data
  contracts only.

## Coordinate and display contracts

Each map uses three aligned coordinate systems:

- **Visual tiles:** 25 columns × 15 rows of 16×16 logical pixels, indexed
  `(0,0)` through `(24,14)`.
- **Navigation cells:** 50 columns × 30 rows of 8×8 logical pixels, indexed
  `(0,0)` through `(49,29)`. One visual tile covers a 2×2 navigation-cell block.
- **World pixels:** 400×240 logical pixels.

All exact layout rectangles in this document are `Rect2i(x, y, width, height)`
with an exclusive end. Unless explicitly called navigation cells, layout
coordinates are visual tiles. Named point coordinates are navigation cells and
refer to the cell containing the player's 8×8 foot body.

The game remains 200×120 logical pixels scaled by nearest-neighbor exactly 4×
to the 800×480 physical display. The camera therefore shows 12.5×7.5 visual
tiles (25×15 navigation cells) at once. Camera positions, actors, and transition
overlays are integer-aligned in logical space.

## Asset provenance and processing manifest

The user supplied the following packs and confirmed that the project may modify
and redistribute them. This rights confirmation applies to the listed source
family only; it does not apply to reference screenshots or third-party game
assets.

| Source identifier | Role | Required processing | Derived runtime destination |
| --- | --- | --- | --- |
| `tf_jungle_a1` | Jungle ground, path, edges | Preserve native pixels; slice on the source's 16px grid; crop only complete cells | `res://assets/tiles/jungle_tiles.png` |
| `tf_jungle_a2` | Jungle autotile/terrain complements | Preserve native pixels; explicit 16px regions | `res://assets/tiles/jungle_tiles.png` |
| `tf_jungle_b` | Jungle props and vegetation | Preserve native pixels; explicit regions for every prop | `res://assets/sprites/jungle_props.png` |
| `tf_jungle_a5` | Jungle structures/details | Preserve native pixels; explicit regions; assemble only style-compatible wood pieces | `res://assets/sprites/jungle_props.png` |
| `tf_beach_tileA1` | Beach ground and shoreline | Source is an exact nearest-neighbor 3× export; downsample once from 768×576 to native 256×192 using nearest-neighbor, then slice on a 16px grid | `res://assets/tiles/beach_tiles.png` |
| `tf_beach_tileB` | Beach props and structures | Source is an exact nearest-neighbor 3× export; downsample once from 768×768 to native 256×256 using nearest-neighbor, then define explicit prop regions | `res://assets/sprites/beach_props.png` |

Processing is lossless nearest-neighbor only: no smoothing, anti-aliasing,
subpixel scaling, palette interpolation, or repeated resize cycles. Derived
atlases retain 16×16 alignment. If a source sheet contains padding or
non-grid-aligned large props, those props use explicit pixel regions instead of
implicit grid slicing.

The `beach_tileset` composite is a visual reference only and is not sliced,
committed as a runtime dependency, or treated as authoritative source art.
Cozytown preview strips are unsuitable runtime sources and are excluded.
Pastel Cozytown houses are not used in this MVP. A future recolor would require
a cohesive palette pass and a demonstrated need not met by the primary pack
family.

Large trees, palms, roofs, shelters, bridge pieces, signs, and similar props
have:

1. an explicit source region and world-space draw offset;
2. a separate navigation-cell collision footprint;
3. a back/base draw portion below the player where appropriate; and
4. a front/canopy/roof portion above the player where appropriate.

Visual dimensions never imply collision dimensions. The runtime provenance
record for derived atlases identifies the source identifiers above, the
nearest-neighbor transform where applicable, and the user's confirmed
modification/redistribution grant; reference-only composites and previews are
not listed as redistributable sources.

## Visual direction

The shared target is a polished top-down creature-RPG world: high-contrast
walkable routes, controlled detail density, distinct silhouettes, readable
doors and boundaries, and landmarks visible within one or two camera screens.
FireRed is a readability benchmark only. Layout geometry, decorative clusters,
palette treatment, buildings, and landmark arrangements are original.

The jungle uses deep green borders, warmer clearings and dirt, layered ferns
and palms, restrained fossil details, and warm wooden expedition construction.
The beach uses pale sand, saturated water, dune vegetation, boardwalk wood,
rocks, and nautical shelter details. The transition's log bridge shares jungle
wood on its west end and leads naturally into the beach boardwalk palette.

Buildings are scenery with blocked doors. The jungle building is a compact
wooden field station assembled from `tf_jungle_*` materials. The beach building
is an open-looking but non-enterable dock shelter assembled from
`tf_beach_tileB` boardwalk/wood elements. Their roofs use front layering so the
player can pass behind the lower roof edge while remaining blocked by the
building's true footprint.

## Jungle map: `jungle`

### Terrain composition

The jungle retains the Expedition Trail concept, but its active route now
terminates at the east bridge instead of a blocked future-biome marker.

- `Rect2i(0, 0, 25, 15)` is the complete map extent.
- The outer one-visual-tile ring is dense jungle boundary except at the east
  bridge opening, visual tiles `(24,7)` and `(24,8)`.
- The primary trail is three navigation cells wide. Its centerline follows
  navigation points `(5,25) → (5,19) → (17,19) → (17,14) → (34,14) →
  (34,8) → (38,8) → (38,15) → (46,15)`.
- `Rect2i(6,8,8,4)` is the field-station clearing.
- `Rect2i(15,5,5,5)` is the fossil clearing.
- `Rect2i(19,2,4,5)` is the pond and irregular bank.
- `Rect2i(9,2,7,4)`, `Rect2i(7,11,10,3)`, and `Rect2i(1,4,5,4)` are the
  north, south, and west encounter clearings respectively; the trail and
  landmark footprints are carved safe through them.
- `Rect2i(23,7,2,2)` is the log-bridge checkpoint. Its walkable deck is
  navigation `Rect2i(46,14,4,2)`, and only its outer navigation
  `Rect2i(48,14,2,2)` is the transition trigger.

### Landmarks and named regions

Named point regions use navigation coordinates:

- `player_start`: `(5,25)`, facing down, on safe trail.
- `research_outpost`: `(17,19)`.
- `field_station_door`: `(17,21)`, visibly closed and blocked.
- `fossil_clearing`: `(34,14)`.
- `pond`: `(42,8)`.
- `north_meadow`: `(25,7)`.
- `south_meadow`: `(28,24)`.
- `west_thicket`: `(7,11)`.
- `beach_checkpoint`: `(48,15)`, a transition trigger.
- `beach_checkpoint_return`: `(46,15)`, the safe destination when returning
  from the beach, facing west.

The old `volcanic_exit`, `snow_exit`, `desert_exit`, and `forest_exit` names may
remain as blocked decorative regions for compatibility, but none initiates a
transition. Existing callers that inspect these names continue to receive valid
positions.

The field station occupies visual `Rect2i(7,8,4,3)`. Its collision footprint is
navigation `Rect2i(14,16,8,6)`, including the door cell. Decorative roof pixels
may overhang that footprint but do not add collision.

## Beach map: `beach`

### Terrain composition

The beach is a crescent shore with a boardwalk arrival, a dock shelter, a safe
central promenade, tide pools, and dune-grass encounter pockets.

- `Rect2i(0,0,25,15)` is the complete map extent.
- Ocean occupies all of rows `y=0..2`, plus:
  - row `y=3`: `x=0..4` and `x=17..24`;
  - row `y=4`: `x=0..2` and `x=19..24`;
  - row `y=5`: `x=0..1` and `x=21..24`;
  - row `y=6`: `x=22..24`;
  - row `y=7`: `x=23..24`;
  - rows `y=8..12`: `x=24`;
  - rows `y=13..14`: `x=22..24`.
- Sand fills the remaining interior unless replaced by boardwalk, rock, dune
  vegetation, or tide-pool data.
- `Rect2i(0,7,10,2)` is the west-to-center boardwalk.
- `Rect2i(8,5,5,4)` is the dock-shelter platform. The shelter itself occupies
  visual `Rect2i(9,5,3,2)` with collision navigation
  `Rect2i(18,10,6,4)`; its south-facing door/opening remains blocked in the MVP.
- `Rect2i(10,7,9,2)` is the safe sand promenade linking the shelter to the
  crescent's east lookout.
- `Rect2i(14,4,4,2)` and `Rect2i(18,9,4,3)` are tide-pool/rock gardens with
  water and rock cells blocked independently.
- `Rect2i(3,10,5,3)` and `Rect2i(10,11,7,3)` are dune-grass encounter pockets.
  A two-navigation-cell-wide safe sand route remains between them.
- The south and southwest map edge outside the return boardwalk is closed by
  dunes, driftwood, palms, and rocks; the ocean closes the north and east.

### Landmarks and named regions

- `boardwalk_arrival`: `(4,15)`, facing east, safe destination from jungle.
- `jungle_checkpoint`: `(1,15)`, reciprocal transition trigger.
- `jungle_checkpoint_return`: `(3,15)`, a safe boardwalk cell immediately
  inside the beach.
- `dock_shelter`: `(20,16)`.
- `dock_shelter_door`: `(20,14)`, visibly closed and blocked.
- `crescent_lookout`: `(36,15)`.
- `north_tide_pool`: `(31,9)`.
- `south_tide_pool`: `(39,21)`.
- `west_dunes`: `(10,23)`.
- `south_dunes`: `(26,25)`.

The reciprocal trigger occupies navigation `Rect2i(0,14,2,2)`. The boardwalk
continues visually off the west edge so the return reads as a route rather than
an invisible teleport.

## Transition flow

`Overworld` owns transitions. `PlayerActor` continues to own movement and emit
exactly one `Events.player_moved(position)` only after each completed,
successful 8px step.

1. `Overworld` receives the completed `player_moved` event.
2. It queries the active `WorldMap` transition metadata using the player's
   completed foot-cell position.
3. If no transition exists, normal encounter-zone consumers may process the
   completed step unchanged.
4. If a transition exists, `Overworld` immediately locks new movement input.
5. A full-screen black `CanvasLayer` fades from transparent to opaque over
   0.15 seconds.
6. At full opacity, `Overworld` stores the destination `map_id` and position,
   removes the current map/player/camera, creates the destination map and
   player, and positions the player at the declared destination.
7. The camera is clamped and snapped before the black overlay is removed.
8. The overlay fades from opaque to transparent over 0.15 seconds, then
   movement unlocks.

The forward transition is:

`jungle: beach_checkpoint (48,15) → beach: boardwalk_arrival (4,15), facing east`.

The reciprocal transition is:

`beach: jungle_checkpoint (1,15) → jungle: beach_checkpoint_return (46,15), facing west`.

The destination spawn does not emit a synthetic `player_moved` event and cannot
immediately retrigger because each destination lies outside its map's trigger
rectangle. Menu input and movement input are ignored from transition start
until fade-in completion. Encounter-zone consumers must not roll for the
transition-triggering step; transition handling takes precedence for that
completed move.

## Architecture and data contracts

### Map definitions

Add `game/world/beach_map_data.gd` beside
`game/world/jungle_map_data.gd`. Each definition returns deterministic data with
the same contract:

```text
id: StringName
visual_tile_size: 16
navigation_tile_size: 8
width: 50
height: 30
ground: 30×50 navigation-cell IDs
props_back: ordered explicit prop records
props_front: ordered explicit prop records
blocked: set of Vector2i navigation cells
encounters: set of Vector2i navigation cells
doors: set of Vector2i navigation cells
regions: Dictionary[StringName, Vector2i]
transitions: ordered transition records
assets: terrain and prop atlas references plus explicit source regions
```

Each transition record contains `source_rect`, `destination_map_id`,
`destination_region`, and `destination_facing`. Definition validation requires
unique IDs, 50×30 ground data, in-bounds blocked/encounter/door cells,
in-bounds named regions, non-overlapping transition sources, and a valid,
walkable destination region outside a destination trigger.

### `WorldMap`

`WorldMap` is parameterized by a map definition or registered map ID before it
builds layers. It renders only the active definition and has no authority to
replace maps, fade, or mutate session location.

These stable public methods and semantics are preserved:

```text
world.map_size_px() -> Vector2
world.spawn_position() -> Vector2
world.world_to_tile(world_pos) -> Vector2i
world.tile_center(tile) -> Vector2
world.is_blocked(world_pos) -> bool
world.is_encounter_zone(world_pos) -> bool
world.is_encounter_zone_tile(tile) -> bool
world.can_stand(world_pos, body) -> bool
world.region_position(name) -> Vector2
world.is_house_door(tile) -> bool
player.is_moving() -> bool
player.is_in_encounter_zone() -> bool
```

`spawn_position()` resolves the active definition's spawn/arrival default, not
a global jungle constant. `map_size_px()` returns `(400,240)` for both maps.
`world_to_tile()` and `tile_center()` continue to use the 8px navigation grid.
`is_house_door()` remains the compatibility name and returns true for any
blocked building door, including the beach shelter.

New read-only queries expose `map_id()` and the transition record at a
navigation cell or world position. Callers do not inspect visual tile IDs to
infer these values.

### `Overworld`

`Overworld` owns:

- the active map ID;
- construction and replacement of `WorldMap`, `PlayerActor`, and camera;
- the connection to completed `Events.player_moved`;
- transition precedence, movement lock, fade overlay, and reciprocal travel;
- validating/restoring session position; and
- camera/HUD rebinding after replacement.

`PlayerActor` remains map-agnostic. It receives a world instance and starting
position, respects an explicit movement-enabled lock, retains cardinal
grid-step behavior, and keeps its existing public methods.

## Collision, encounter, and render layering

The scene's logical order remains:

```text
Ground
EncounterDecoration
PropsBack
Player
PropsFront
HUD
TransitionFade
```

Ground IDs choose terrain art only. Collision is authored as 8px navigation
cells independent of source regions and draw bounds. Water, dense vegetation,
cliffs/dunes, rocks, structural walls, closed doors, and map boundaries are
blocked. Bridge and boardwalk deck cells are walkable. Front-layer canopies and
roofs may overlap the player visually without changing collision.

Jungle encounter cells are dark tall grass only. Beach encounter cells are
dune grass only. Dirt, lawn, clearings, sand, boardwalk, bridge, and promenade
are safe. This MVP supplies deterministic encounter metadata and preserves the
query API; it does not roll probability, choose a creature, start a battle, or
change encounter cooldown behavior.

Transition cells are safe and take precedence over encounter processing even
if malformed data accidentally marks one as an encounter. Validation reports
that overlap as an error.

## Session state and recreation

`Game.player` is the session source of truth for:

- `map_id`, defaulting to `jungle` for a new session;
- `position`, stored as the player's logical top-left foot-body position; and
- `direction`.

Position and map ID are written together at each completed move and at the
opaque midpoint of a map transition. Returning from menu, battle, or catching
recreates the correct map first and then restores that map's position and
direction. State recreation never substitutes the destination map's default
spawn for a valid stored position.

Restoration accepts a position only when it is 8px-aligned, in bounds, and
walkable for the 8×8 body. An invalid position resolves deterministically to
the nearest walkable navigation cell by breadth-first search with neighbor
order down, left, right, up. If no walkable cell exists, restoration uses the
definition's validated default spawn. This also handles positions made invalid
by migration from the current jungle layout.

## Camera and HUD

Each active map gets a fresh `Camera2D` attached to the player, with smoothing
disabled, integer position, and limits `(0,0)` through `(400,240)`. The camera
is made current only after the destination player is positioned. During map
replacement the opaque fade prevents a one-frame view of `(0,0)` or an
unclamped camera.

The HUD remains a screen-space `CanvasLayer`, not a child of either map. The
existing zone indicator remains functional and reads `SAFE`, `TALL GRASS`, or
`DUNE GRASS` from active-map metadata. No minimap, map title card, transition
prompt, or additional permanent HUD is added. The fade layer is above all map
and HUD content.

## Error and fallback behavior

- Unknown or missing session `map_id`: report one descriptive error, select
  `jungle`, and restore at `player_start`.
- Invalid stored position: use the deterministic nearest-walkable resolution
  above and persist the corrected result.
- Invalid transition destination or destination region: keep the current map
  and position, fade back in, unlock input, and report an error. Never strand
  the screen black or partially replace session state.
- Re-entrant transition requests while locked: ignore them.
- Missing required runtime atlas: report the exact resource and render a
  nearest-neighbor debug fallback for the affected layer while retaining
  collision and route functionality. Do not silently substitute a reference
  composite or Cozytown art.
- Invalid map-definition dimensions or out-of-bounds contract data: reject the
  definition before display. If it is the requested beach definition, remain
  on the current valid jungle instance; if no valid map exists during initial
  entry, construct the jungle definition's collision-safe debug rendering.

Error paths do not emit `player_moved`, trigger encounters, or mutate to a
destination map ID unless destination construction succeeds.

## Deterministic tests

Automated checks must prove:

1. Both definitions report 50×30 navigation cells, 400×240 world pixels, and
   16×16 visual art aligned to the 8px navigation grid.
2. A fresh session enters `jungle` at `player_start`; map recreation restores
   valid jungle or beach map ID, position, and direction exactly.
3. Existing stable world/player public methods remain callable with their prior
   coordinate semantics on both maps.
4. All declared regions, prop collision footprints, encounters, doors, and
   transition rectangles are in bounds; transitions do not overlap encounters.
5. Every walkable landmark and both destination regions are reachable from the
   relevant spawn without crossing blocked cells.
6. Jungle water, boundary vegetation, station walls/door, rocks, and fossil
   barriers block; trail, clearings, and bridge deck permit movement.
7. Beach ocean, dunes, shelter walls/door, tide pools, and rocks block; sand,
   promenade, boardwalk, and legal shore routes permit movement.
8. Jungle tall grass and beach dune grass report encounter zones; all declared
   safe terrain reports false.
9. A successful step onto jungle `(48,15)` emits one `player_moved`, suppresses
   encounter processing, locks input, and ends at beach `(4,15)` facing east
   after a 0.15s-out/0.15s-in fade.
10. A successful step onto beach `(1,15)` performs the reciprocal transition
    and ends at jungle `(46,15)` facing west.
11. Destination placement emits no synthetic `player_moved`; held input during
    either fade cannot move or retrigger the player.
12. Menu/state recreation during ordinary play returns to the active map and
    position. Menu input during a transition is ignored.
13. Invalid map IDs, positions, resources, and transition destinations follow
    the specified fallback paths without a black screen, crash, false move
    event, or partial destination state.
14. The logical viewport remains 200×120, physical output remains 800×480 at
    4× nearest-neighbor, movement remains cardinal 8px steps, and existing menu
    behavior still works outside transitions.
15. No deterministic world test starts a battle or adds encounter-probability
    behavior.

## Visual checkpoints

Capture each checkpoint at 200×120 logical resolution and at the 800×480 4×
physical scale, with nearest filtering and no subpixel seams:

- Jungle spawn: trail entry, dense boundary, and route hierarchy are obvious.
- Jungle station: coherent wooden field station, blocked readable door, and
  correct roof/player occlusion.
- Jungle fossil clearing and pond: distinct landmarks with safe route,
  collision silhouettes, and controlled decorative density.
- Jungle east checkpoint: trail visibly becomes a log bridge and leaves the
  east edge without exposing void.
- Opaque transition midpoint: full screen is black, including HUD.
- Beach arrival: boardwalk direction is immediately legible and the player is
  not standing in a trigger or blocked cell.
- Beach shelter and promenade: matching beach wood, readable blocked shelter,
  and clear safe route to the crescent lookout.
- Beach tide pools and dunes: ocean/shore curve reads naturally, dune grass is
  visually distinct from safe sand, and large palms/rocks layer correctly.
- Both map corners and camera extrema: no out-of-map reveal, jitter, blurred
  pixels, or one-frame camera flash.

## Migration from the current jungle

The current jungle already uses a 50×30 8px navigation grid and a 400×240
world. Keep that external geometry and the stable APIs. Replace the current
prototype atlas usage with the licensed jungle family, split large props into
explicit back/front records, update the east route into the active bridge, and
move map-specific constants out of `WorldMap` into the jungle definition.

Preserve the current `player_start`, research outpost, fossil clearing, pond,
meadow, thicket, and legacy blocked-exit region names where this specification
defines compatible coordinates. Replace the two generic research huts with one
cohesive wooden field station; doors remain blocked and non-interactive.

Existing session positions remain valid when walkable in the revised
definition. Positions that now intersect changed station, vegetation, pond, or
bridge collision use the deterministic nearest-walkable migration rule. No
other existing uncommitted world changes are prerequisites of this design
document, and no code or asset migration is part of this documentation commit.

## Acceptance criteria

- The committed design clearly defines exactly two playable 25×15 visual-tile
  maps, with jungle first and beach second.
- Both maps use 400×240 logical world space, 16×16 visual art tiles, 8×8
  movement/collision cells, and the existing 200×120-to-800×480 display path.
- The specified licensed pack family is the runtime art source; beach A1/B are
  downsampled exactly once to 256×192 and 256×256 before slicing; excluded
  composites and previews remain reference-only.
- Jungle and beach landmarks, blocked areas, encounter areas, named points, and
  transition endpoints are deterministic and sufficiently exact to implement
  without inventing layout decisions.
- The east jungle bridge and west beach boardwalk transition in both directions
  only after completed movement, with a 0.15s fade each way, movement lock,
  transition precedence, and no synthetic move event.
- `WorldMap` is map-definition-driven while every listed stable public method
  retains its applicable behavior.
- `Overworld` owns active-map lifecycle and transitions; `PlayerActor` remains
  map-agnostic; collision, encounters, and visual layering remain independent.
- `Game.player` preserves map ID, valid position, and direction across
  overworld recreation, with deterministic recovery from invalid state.
- Buildings match their biome art, use explicit collision and layering, and
  remain blocked/non-enterable.
- Tests and visual checkpoints cover both maps, reciprocal transitions,
  persistence, fallback behavior, collision/encounter separation, camera/HUD,
  and unchanged display/movement contracts.
- No battle, encounter-probability, additional-biome, gameplay-content, code,
  asset, or implementation-plan scope is introduced by this specification.
