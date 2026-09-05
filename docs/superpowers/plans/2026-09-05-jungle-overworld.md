# Jungle Overworld Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an original dinosaur-themed jungle overworld with FireRed-style grid movement at 200×120 logical pixels, scaled exactly 4× to the 800×480 Arduino display.

**Architecture:** Keep the existing `Game`, `InputManager`, and `Events` contracts. Replace procedural prototype drawing with deterministic tile data rendered from original atlases, split terrain and props into back/front layers, and move the player one 8px grid step at a time.

**Tech Stack:** Summer Engine 0.5.65, Godot-compatible GDScript 4.7, Summer autopilot probes, standard Godot `Image` asset generation.

## Global Constraints

- Physical display is 800×480 landscape.
- Logical render canvas is 200×120 and scales exactly 4×.
- Use nearest-neighbor texture filtering and integer camera coordinates.
- Use only original or explicitly licensed assets; do not copy Poke Nexus or Pokémon assets.
- MVP biome is jungle only.
- Houses remain blocked scenery with no interiors or interaction.
- Person 2 owns world, movement, collision, camera, and encounter-zone detection—not encounter probability or battles.
- Preserve existing `WorldMap`, `InputManager`, `Game.player`, and `Events.player_moved` integration APIs.
- Do not use or commit the duplicate `gok-mon-(4.6)/` project.

---

### Task 1: Correct the display contract

**Files:**
- Modify: `game/config/game_config.gd`
- Modify: `game/project.godot`
- Modify: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Produces: `LOGICAL_SIZE = Vector2i(200, 120)`, `DISPLAY_SIZE = Vector2i(800, 480)`, `PIXEL_SCALE = 4`
- Preserves: `DISPLAY_WIDTH`, `DISPLAY_HEIGHT`, `ASSET_WIDTH`, `ASSET_HEIGHT` as compatibility aliases where existing code still reads them

- [ ] **Step 1: Add failing resolution assertions to the world probe**

```gdscript
report("logical_size", GameConfig.LOGICAL_SIZE)
report("display_size", GameConfig.DISPLAY_SIZE)
report("pixel_scale", GameConfig.PIXEL_SCALE)
if get_viewport().get_visible_rect().size != Vector2(200, 120):
	report("error", "logical viewport must be 200x120")
	finish()
	return
if GameConfig.DISPLAY_SIZE != Vector2i(800, 480):
	report("error", "physical display must be 800x480")
	finish()
	return
```

- [ ] **Step 2: Run the probe and confirm the old portrait contract fails**

Run:

```bash
bash game/tests/autopilot/run.sh game/tests/autopilot/world_player.gd
```

Expected: non-zero with a logical viewport or physical display mismatch.

- [ ] **Step 3: Replace the shared constants**

Use this contract in `game/config/game_config.gd`:

```gdscript
extends Node

const LOGICAL_WIDTH := 200
const LOGICAL_HEIGHT := 120
const LOGICAL_SIZE := Vector2i(LOGICAL_WIDTH, LOGICAL_HEIGHT)

const DISPLAY_WIDTH := 800
const DISPLAY_HEIGHT := 480
const DISPLAY_SIZE := Vector2i(DISPLAY_WIDTH, DISPLAY_HEIGHT)

const PIXEL_SCALE := 4
const TILE_SIZE := 8

# Compatibility: these now describe the logical art canvas.
const ASSET_WIDTH := LOGICAL_WIDTH
const ASSET_HEIGHT := LOGICAL_HEIGHT
const ASSET_SIZE := LOGICAL_SIZE

const DEBUG_STATE_JUMPS := true

func asset_fit_scale() -> float:
	return float(PIXEL_SCALE)

func asset_to_display(asset_pos: Vector2) -> Vector2:
	return asset_pos * PIXEL_SCALE
```

Set these keys in `game/project.godot`:

```ini
[display]
window/size/viewport_width=200
window/size/viewport_height=120
window/size/window_width_override=800
window/size/window_height_override=480
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"

[rendering]
textures/default_filters/use_nearest_mipmap_filter=false
textures/canvas_textures/default_texture_filter=0
```

- [ ] **Step 4: Run the probe**

Expected: viewport `(200.0, 120.0)`, display `(800, 480)`, scale `4`, and no diagnostics.

- [ ] **Step 5: Commit**

```bash
git add game/config/game_config.gd game/project.godot game/tests/autopilot/world_player.gd
git commit -m "fix: set 200x120 logical display contract"
```

---

### Task 2: Generate original jungle pixel-art atlases

**Files:**
- Create: `game/tools/generate_jungle_assets.gd`
- Create: `game/assets/tiles/jungle_tiles.png`
- Create: `game/assets/sprites/jungle_props.png`
- Create: `game/assets/sprites/player.png`
- Create: `game/assets/backgrounds/jungle_palette.png`

**Interfaces:**
- Produces 8×8 terrain cells in `jungle_tiles.png`
- Produces grid-aligned props: fern, cycad, palm, rock, bone, footprint, eggshell, hut pieces, fossil shrine
- Produces 16×20 player frames: down/up/left/right, two walking frames each

- [ ] **Step 1: Create a deterministic Godot image generator**

`generate_jungle_assets.gd` must extend `SceneTree`, build images only from hard-coded original palettes and pixel coordinates, and save PNGs under `res://assets/`.

Core structure:

```gdscript
extends SceneTree

const CLEAR := Color(0, 0, 0, 0)
const JUNGLE_DARK := Color("173b2b")
const JUNGLE_MID := Color("2f6b3f")
const JUNGLE_LIGHT := Color("67a84f")
const PATH_LIGHT := Color("d4b06a")
const PATH_DARK := Color("a97942")
const WATER := Color("247ba0")
const STONE := Color("697386")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tiles"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/backgrounds"))
	_build_tiles().save_png("res://assets/tiles/jungle_tiles.png")
	_build_props().save_png("res://assets/sprites/jungle_props.png")
	_build_player().save_png("res://assets/sprites/player.png")
	_build_palette().save_png("res://assets/backgrounds/jungle_palette.png")
	quit()

func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)
```

Create atlas cells with explicit methods such as `_draw_lawn`, `_draw_path`, `_draw_tall_grass`, `_draw_water`, `_draw_tree`, `_draw_hut`, and `_draw_fossil`. Each method writes only integer pixel rectangles into a transparent image. Do not use antialiasing or downloaded source art.

- [ ] **Step 2: Run the generator**

```bash
/Applications/Summer.app/Contents/MacOS/Summer \
  --headless --path game \
  -s res://tools/generate_jungle_assets.gd
```

Expected: four PNG files exist and the process exits 0.

- [ ] **Step 3: Verify atlas dimensions and opacity**

Add a small validation path to the generator or probe:

```gdscript
var tiles := Image.load_from_file("res://assets/tiles/jungle_tiles.png")
if tiles.get_width() != 64 or tiles.get_height() != 32:
	push_error("jungle tile atlas must be 64x32")
	quit(1)
```

Expected dimensions:

- `jungle_tiles.png`: 64×32
- `jungle_props.png`: 128×64
- `player.png`: 64×40
- `jungle_palette.png`: 16×1

- [ ] **Step 4: Commit**

```bash
git add game/tools/generate_jungle_assets.gd game/assets
git commit -m "art: add original jungle pixel atlases"
```

---

### Task 3: Replace the prototype map with the Expedition Trail

**Files:**
- Create: `game/world/jungle_map_data.gd`
- Modify: `game/world/world_map.gd`
- Modify: `game/world/world_map.tscn`
- Test: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Preserves: `map_size_px`, `spawn_position`, `world_to_tile`, `tile_center`, `is_blocked`, `is_encounter_zone`, `can_stand`
- Produces: `region_position(name: String) -> Vector2`, `is_house_door(tile: Vector2i) -> bool`

- [ ] **Step 1: Write failing map-contract assertions**

```gdscript
if world.map_size_px() != Vector2(400, 240):
	report("error", "jungle map must be 50x30 8px tiles")
	finish()
	return
for region_name in [
	"player_start", "research_outpost", "fossil_clearing", "pond",
	"north_meadow", "south_meadow", "west_thicket",
	"volcanic_exit", "snow_exit", "desert_exit", "forest_exit"
]:
	if world.region_position(region_name) == Vector2.ZERO:
		report("error", "missing region: " + region_name)
		finish()
		return
```

- [ ] **Step 2: Define deterministic map data**

`jungle_map_data.gd` exposes:

```gdscript
extends RefCounted

const WIDTH := 50
const HEIGHT := 30
const TILE := 8

enum Ground { LAWN, PATH, TALL_GRASS, WATER }
enum Prop { NONE, TREE, FERN, CYCAD, PALM, ROCK, BONE, FOOTPRINT, EGGSHELL,
	HUT_WALL, HUT_DOOR, FOSSIL_SHRINE, EXIT_MARKER }

static func build() -> Dictionary:
	return {
		"ground": _build_ground(),
		"props": _build_props(),
		"blocked": _build_blocked(),
		"encounters": _build_encounters(),
		"regions": {
			"player_start": Vector2i(5, 25),
			"research_outpost": Vector2i(16, 19),
			"fossil_clearing": Vector2i(34, 14),
			"pond": Vector2i(42, 7),
			"north_meadow": Vector2i(25, 7),
			"south_meadow": Vector2i(28, 23),
			"west_thicket": Vector2i(7, 11),
			"volcanic_exit": Vector2i(48, 15),
			"snow_exit": Vector2i(25, 2),
			"desert_exit": Vector2i(2, 15),
			"forest_exit": Vector2i(25, 28),
		},
	}
```

The builders use fill/stamp/carve helpers to create:

- two-tile dense jungle border;
- S-shaped path from south spawn to research outpost, fossil clearing, and pond;
- two 4×3 hut footprints with blocked door tiles;
- three tall-grass clearings;
- fossil shrine clearing;
- four blocked biome exit markers.

- [ ] **Step 3: Build layered rendering**

`world_map.gd` loads map data and creates:

```gdscript
var ground_layer: Node2D
var encounter_layer: Node2D
var props_back: Node2D
var props_front: Node2D
var blocked: Dictionary
var encounter_tiles: Dictionary
var regions: Dictionary
```

Draw sprites from the generated atlases using `Sprite2D.region_rect` or `draw_texture_rect_region`. Ground renders first; back props render before the player; canopy/front foliage renders after the player.

`is_blocked_tile` must query `blocked`, not infer collision from visual tile IDs. `is_encounter_zone_tile` must query `encounter_tiles`.

- [ ] **Step 4: Implement stable region and door methods**

```gdscript
func region_position(name: String) -> Vector2:
	if not regions.has(name):
		return Vector2.ZERO
	return tile_center(regions[name])

func is_house_door(tile: Vector2i) -> bool:
	return door_tiles.has(tile)
```

- [ ] **Step 5: Run the map probe and inspect captures**

Expected: spawn, path, both huts, fossil clearing, pond, and tall grass are legible at 200×120; no copied artwork appears.

- [ ] **Step 6: Commit**

```bash
git add game/world/jungle_map_data.gd game/world/world_map.gd game/world/world_map.tscn game/tests/autopilot/world_player.gd
git commit -m "feat: build dinosaur jungle expedition map"
```

---

### Task 4: Implement FireRed-style grid-step movement

**Files:**
- Modify: `game/world/player_actor.gd`
- Modify: `game/states/overworld.gd`
- Test: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Consumes: `InputManager.move_vector()`, `world.is_blocked_tile(tile)`, `Events.player_moved`
- Produces: `is_moving`, `is_in_encounter_zone`, `current_tile`, `try_step`

- [ ] **Step 1: Add failing movement assertions**

```gdscript
var start_tile: Vector2i = actor.current_tile()
await press(InputManager.MOVE_RIGHT, 80)
for _i in 12:
	await get_tree().physics_frame
var after_tile: Vector2i = actor.current_tile()
if after_tile != start_tile + Vector2i.RIGHT:
	report("error", "one input must move exactly one tile")
	finish()
	return
if int(actor.position.x) % GameConfig.TILE_SIZE != 0:
	report("error", "player left the 8px grid")
	finish()
	return
```

- [ ] **Step 2: Replace continuous motion with a movement state**

Use these fields:

```gdscript
const STEP_PIXELS := 8.0
const STEP_SECONDS := 0.10
const HOLD_DELAY := 0.18

var _step_start := Vector2.ZERO
var _step_target := Vector2.ZERO
var _step_elapsed := 0.0
var _moving := false
var _held_time := 0.0
var _last_direction := Vector2.ZERO
```

Core behavior:

```gdscript
func current_tile() -> Vector2i:
	return world.world_to_tile(position + BODY * 0.5)

func try_step(direction: Vector2) -> bool:
	Game.player.direction = direction
	var target := position + direction * STEP_PIXELS
	if not world.can_stand(target, BODY):
		queue_redraw()
		return false
	_step_start = position
	_step_target = target
	_step_elapsed = 0.0
	_moving = true
	return true

func tick(delta: float) -> void:
	if _moving:
		_step_elapsed += delta
		var weight := minf(_step_elapsed / STEP_SECONDS, 1.0)
		position = _step_start.lerp(_step_target, weight).round()
		if weight >= 1.0:
			position = _step_target.round()
			_moving = false
			Game.player.position = position
			Events.player_moved.emit(position)
		queue_redraw()
		return
	var direction := InputManager.move_vector()
	if direction == Vector2.ZERO:
		_held_time = 0.0
		_last_direction = Vector2.ZERO
		return
	if direction != _last_direction:
		_last_direction = direction
		_held_time = 0.0
		try_step(direction)
	else:
		_held_time += delta
		if _held_time >= HOLD_DELAY:
			try_step(direction)
```

- [ ] **Step 3: Render direction frames from `player.png`**

Select one of eight 16×20 atlas regions from direction and walk frame. Keep the player origin aligned so the lower 8×8 portion is the collision footprint.

- [ ] **Step 4: Remove camera smoothing**

In `overworld.gd`:

```gdscript
cam.position_smoothing_enabled = false
cam.limit_smoothed = false
cam.position = cam.position.round()
```

The camera follows the actor, remains clamped, and never samples fractional pixels.

- [ ] **Step 5: Run movement and collision probes**

Expected: one tap equals one 8px step; held direction repeats; blocked movement changes facing but not position; every completed step emits exactly one event.

- [ ] **Step 6: Commit**

```bash
git add game/world/player_actor.gd game/states/overworld.gd game/tests/autopilot/world_player.gd
git commit -m "feat: add grid-step jungle movement"
```

---

### Task 5: Verify houses, encounters, camera, and integration

**Files:**
- Modify: `game/tests/autopilot/world_player.gd`
- Modify: `docs/world.md`
- Modify: `docs/architecture.md`
- Create: `.gitignore`

**Interfaces:**
- Verifies all Person 2 APIs and Person 3 handoff
- Does not emit `Events.encounter_triggered`

- [ ] **Step 1: Add collision and encounter assertions**

The probe must:

1. place the actor beside a known hut door;
2. attempt a step through it and assert position is unchanged;
3. place the actor beside water and assert it blocks;
4. move from lawn into tall grass and assert false → true;
5. move from tall grass onto path and assert true → false;
6. open the menu and return to overworld.

Use inequality/grid assertions, not exact interpolation-frame positions.

- [ ] **Step 2: Add visual checkpoints**

```gdscript
save_frame("00_jungle_spawn")
save_frame("01_research_huts")
save_frame("02_fossil_clearing")
save_frame("03_tall_grass")
save_frame("04_pond")
save_frame("05_blocked_hut_door")
```

- [ ] **Step 3: Run both core and world probes**

```bash
bash game/tests/autopilot/run.sh game/tests/autopilot/phase1_core.gd
bash game/tests/autopilot/run.sh game/tests/autopilot/world_player.gd
```

Expected: both exit 0, `errors_seen` is empty, and all frames are present.

- [ ] **Step 4: Verify through Summer MCP**

Open `game/` in Summer, then:

1. call `summer_get_project_context`;
2. call `summer_get_diagnostics`;
3. run the game;
4. capture the running game;
5. stop the game;
6. confirm diagnostics remain empty.

- [ ] **Step 5: Update documentation**

`docs/world.md` records:

- 800×480 physical / 200×120 logical;
- 8px grid movement;
- original asset atlas paths;
- jungle region names;
- blocked houses;
- Person 3 encounter-zone contract.

`docs/architecture.md` replaces all portrait 480×800 references and states that future biomes are planned but absent.

Root `.gitignore` contains:

```gitignore
.superpowers/
gok-mon-(4.6)/
```

This prevents planning artifacts and the duplicate local project from being committed.

- [ ] **Step 6: Final status and commit**

```bash
git status --short
git add .gitignore docs/world.md docs/architecture.md game/tests/autopilot/world_player.gd
git commit -m "docs: document jungle world integration"
```

Expected: only intentionally unrelated pre-existing files remain uncommitted.
