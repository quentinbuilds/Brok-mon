# Jungle → Beach MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the prototype jungle with licensed 16×16 art and add a reciprocal faded transition into a second beach world, while keeping 8px grid movement and the existing Person 2 APIs.

**Architecture:** Keep `WorldMap` as the public façade. Move map-specific data into `jungle_map_data.gd` and `beach_map_data.gd`. `Overworld` owns map replacement, fade, movement lock, and session restore of `Game.player.map_id` plus position. Visual tiles are 16×16; navigation cells stay 8×8.

**Tech Stack:** Summer Engine 0.5.65, Godot-compatible GDScript 4.7, Summer autopilot probes, Godot `Image` nearest-neighbor processing.

## Global Constraints

- Physical display is 800×480 landscape.
- Logical render canvas is 200×120 and scales exactly 4×.
- Use nearest-neighbor texture filtering and integer camera coordinates.
- Use the user-confirmed licensed `tf_jungle_*` and `tf_beach_*` packs; do not copy Pokémon or Poke Nexus assets.
- Cozytown and `beach_tileset` composites are reference-only and must not be runtime sources.
- Houses remain blocked scenery with no interiors or interaction.
- Person 2 owns world, movement, collision, camera, encounter-zone detection, and map transitions—not encounter probability or battles.
- Preserve existing `WorldMap`, `InputManager`, `Game.player`, and `Events.player_moved` integration APIs.
- Do not use or commit the duplicate `gok-mon-(4.6)/` project.
- Do not include unrelated pre-existing uncommitted work.

## File Map

- Create: `game/assets/source/` licensed source sheets and `ATTRIBUTION.md`
- Create: `game/tools/process_licensed_tiles.gd`
- Create: `game/world/map_registry.gd`
- Create: `game/world/beach_map_data.gd`
- Modify: `game/world/jungle_map_data.gd`
- Modify: `game/world/world_map.gd`
- Modify: `game/states/overworld.gd`
- Modify: `game/world/player_actor.gd`
- Modify: `game/core/player_data.gd`
- Modify: `game/tests/autopilot/world_player.gd`
- Modify: `docs/world.md`, `docs/architecture.md`, `README.md`

---

### Task 1: Import licensed sources and build runtime atlases

**Files:**
- Create: `game/assets/source/tf_jungle_a1.png`
- Create: `game/assets/source/tf_jungle_a2.png`
- Create: `game/assets/source/tf_jungle_b.png`
- Create: `game/assets/source/tf_jungle_a5.png`
- Create: `game/assets/source/tf_beach_tileA1.png`
- Create: `game/assets/source/tf_beach_tileB.png`
- Create: `game/assets/source/ATTRIBUTION.md`
- Create: `game/tools/process_licensed_tiles.gd`
- Create: `game/assets/tiles/beach_tiles.png`
- Create: `game/assets/sprites/beach_props.png`
- Modify: `game/assets/tiles/jungle_tiles.png`
- Modify: `game/assets/sprites/jungle_props.png`
- Test: `game/tools/process_licensed_tiles.gd` validation path

**Interfaces:**
- Produces: jungle tiles/props from native jungle sheets; beach tiles 256×192; beach props 256×256
- Produces: `process_licensed_tiles.gd` exits non-zero if dimensions fail

- [ ] **Step 1: Copy source sheets and write the processor with failing checks first**

Copy the six licensed sheets from the Cursor assets folder into `game/assets/source/` using the stable names above. Write `process_licensed_tiles.gd` so it validates:

```gdscript
extends SceneTree

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _require_size(path: String, size: Vector2i) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.get_size() != size:
		_fail("%s must be %sx%s" % [path, size.x, size.y])
	return image

func _downsample3(image: Image) -> Image:
	if image.get_width() % 3 != 0 or image.get_height() % 3 != 0:
		_fail("source is not an exact 3x nearest export")
	var out := Image.create(image.get_width() / 3, image.get_height() / 3, false, Image.FORMAT_RGBA8)
	for y in out.get_height():
		for x in out.get_width():
			out.set_pixel(x, y, image.get_pixel(x * 3, y * 3))
	return out
```

- [ ] **Step 2: Run the processor and confirm it fails until derived sizes exist**

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path game -s res://tools/process_licensed_tiles.gd
```

Expected: non-zero until beach downsample and copies exist.

- [ ] **Step 3: Write the derived atlases**

- Jungle tiles: assemble `tf_jungle_a1` + `tf_jungle_a2` into `jungle_tiles.png` without resampling.
- Jungle props: copy/assemble `tf_jungle_b` + style-compatible wood from `tf_jungle_a5` into `jungle_props.png`.
- Beach tiles: downsample `tf_beach_tileA1` 768×576 → 256×192.
- Beach props: downsample `tf_beach_tileB` 768×768 → 256×256.
- No mipmaps, no smoothing, no Cozytown or composite `beach_tileset`.

- [ ] **Step 4: Re-run and assert exact sizes**

Expected: exit 0; `beach_tiles.png` 256×192; `beach_props.png` 256×256; jungle sheets remain 16px-aligned.

- [ ] **Step 5: Commit**

```bash
git add game/assets/source game/tools/process_licensed_tiles.gd game/assets/tiles game/assets/sprites
git commit -m "art: import licensed jungle and beach tiles"
```

---

### Task 2: Parameterize WorldMap by map definition

**Files:**
- Create: `game/world/map_registry.gd`
- Modify: `game/world/world_map.gd`
- Modify: `game/core/player_data.gd`
- Test: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Consumes: `jungle_map_data.build()` dictionary
- Produces: `MapRegistry.definition(map_id: StringName) -> Dictionary`
- Produces: `WorldMap.setup(map_id: StringName)` and `WorldMap.map_id() -> StringName`
- Produces: `PlayerData.map_id: StringName` defaulting to `&"jungle"`
- Preserves: `map_size_px`, `spawn_position`, `world_to_tile`, `tile_center`, `is_blocked`, `is_encounter_zone`, `can_stand`, `region_position`, `is_house_door`

- [ ] **Step 1: Add failing map-id assertions**

```gdscript
if not world.has_method("map_id") or world.map_id() != &"jungle":
	report("error", "world must expose map_id jungle by default")
	finish()
	return
if Game.player.map_id != &"jungle":
	report("error", "session map_id must default to jungle")
	finish()
	return
```

- [ ] **Step 2: Run the world probe and confirm the missing API fails**

```bash
bash /Users/mrq/Projects/gok-mon/game/tests/autopilot/run.sh /Users/mrq/Projects/gok-mon/game/tests/autopilot/world_player.gd
```

Expected: error about `map_id`.

- [ ] **Step 3: Add registry and setup**

```gdscript
# map_registry.gd
extends RefCounted
const Jungle = preload("res://world/jungle_map_data.gd")

static func definition(map_id: StringName) -> Dictionary:
	match map_id:
		&"jungle":
			return Jungle.build()
		_:
			return {}
```

`WorldMap.setup(map_id)` loads that definition, stores `id`, atlases from `data.assets`, and existing collision/region dictionaries. `spawn_position()` uses the definition's spawn region, not a jungle hardcode. `PlayerData` gains `var map_id: StringName = &"jungle"`.

- [ ] **Step 4: Run the world and core probes**

Expected: both exit 0; jungle still 400×240; existing regions still resolve.

- [ ] **Step 5: Commit**

```bash
git add game/world/map_registry.gd game/world/world_map.gd game/core/player_data.gd game/tests/autopilot/world_player.gd
git commit -m "feat: parameterize overworld by map id"
```

---

### Task 3: Rebuild the jungle with 16×16 licensed art

**Files:**
- Modify: `game/world/jungle_map_data.gd`
- Modify: `game/world/world_map.gd`
- Test: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Produces: jungle definition with `visual_tile_size=16`, `navigation_tile_size=8`, explicit `props_back`/`props_front`, `transitions`, `assets`
- Produces: east bridge trigger `Rect2i(48,14,2,2)` and `beach_checkpoint` `(48,15)`
- Preserves: legacy blocked-exit region names

- [ ] **Step 1: Add failing layout assertions**

```gdscript
if world.region_position("beach_checkpoint") == Vector2.ZERO:
	report("error", "missing jungle beach checkpoint")
	finish()
	return
if world.is_blocked(world.region_position("beach_checkpoint")):
	report("error", "bridge trigger must be walkable")
	finish()
	return
```

- [ ] **Step 2: Run the probe and confirm it fails**

Expected: missing `beach_checkpoint`.

- [ ] **Step 3: Rebuild jungle data and 16×16 ground drawing**

Follow the approved spec rectangles exactly:

- Dense 1-visual-tile border except visual `(24,7)` and `(24,8)`.
- 3-cell-wide trail through `(5,25) → (5,19) → (17,19) → (17,14) → (34,14) → (34,8) → (38,8) → (38,15) → (46,15)`.
- Field station visual `Rect2i(7,8,4,3)`, collision `Rect2i(14,16,8,6)`, door `(17,21)` blocked.
- Fossil `Rect2i(15,5,5,5)`, pond `Rect2i(19,2,4,5)`, three encounter clearings.
- Bridge deck `Rect2i(46,14,4,2)`; trigger only `Rect2i(48,14,2,2)`.
- Draw ground as 16×16 visual tiles from licensed atlas regions; keep collision on 8px cells.
- Split trees/station roof into back/front records.

- [ ] **Step 4: Capture jungle frames and rerun probes**

Expected: spawn, station, fossil, pond, and east bridge are readable; no Cozytown houses; door blocks.

- [ ] **Step 5: Commit**

```bash
git add game/world/jungle_map_data.gd game/world/world_map.gd game/tests/autopilot/world_player.gd
git commit -m "feat: rebuild jungle with licensed 16px tiles"
```

---

### Task 4: Add the beach map

**Files:**
- Create: `game/world/beach_map_data.gd`
- Modify: `game/world/map_registry.gd`
- Modify: `game/world/world_map.gd`
- Test: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Produces: `beach` definition with the approved crescent-shore layout
- Produces: regions `boardwalk_arrival`, `jungle_checkpoint`, `dock_shelter`, `crescent_lookout`
- Produces: HUD zone text `DUNE GRASS` when beach encounter metadata is true

- [ ] **Step 1: Add failing beach-load assertions**

```gdscript
world.setup(&"beach")
if world.map_id() != &"beach" or world.map_size_px() != Vector2(400, 240):
	report("error", "beach map must be 400x240")
	finish()
	return
if world.region_position("boardwalk_arrival") == Vector2.ZERO:
	report("error", "missing beach arrival")
	finish()
	return
```

- [ ] **Step 2: Run the probe and confirm it fails**

Expected: missing beach definition.

- [ ] **Step 3: Author beach data and register it**

Follow the spec ocean mask, boardwalk `Rect2i(0,7,10,2)`, shelter collision `Rect2i(18,10,6,4)`, promenade, tide pools, and dune-grass pockets. Reciprocal trigger is `Rect2i(0,14,2,2)`; arrival `(4,15)` is outside that rect. Ocean, dunes, rocks, and the shelter door are blocked. Sand, boardwalk, and promenade are walkable.

- [ ] **Step 4: Capture beach frames and rerun probes**

Expected: boardwalk, shelter, crescent, tide pools, and dune grass are readable; water blocks.

- [ ] **Step 5: Commit**

```bash
git add game/world/beach_map_data.gd game/world/map_registry.gd game/world/world_map.gd game/tests/autopilot/world_player.gd
git commit -m "feat: add licensed beach world"
```

---

### Task 5: Reciprocal fade transition and session restore

**Files:**
- Modify: `game/states/overworld.gd`
- Modify: `game/world/player_actor.gd`
- Modify: `game/world/world_map.gd`
- Modify: `game/core/player_data.gd`
- Test: `game/tests/autopilot/world_player.gd`

**Interfaces:**
- Consumes: `Events.player_moved(position)`
- Produces: `WorldMap.transition_at(tile: Vector2i) -> Dictionary`
- Produces: `PlayerActor.set_movement_enabled(enabled: bool)`
- Produces: jungle `(48,15) → beach (4,15)` facing east; beach `(1,15) → jungle (46,15)` facing west
- Produces: 0.15s fade out, replace, 0.15s fade in; no synthetic `player_moved`

- [ ] **Step 1: Add failing transition assertions**

```gdscript
actor.position = world.tile_center(Vector2i(47, 15)) - actor.BODY * 0.5
Game.player.position = actor.position
await press(InputManager.MOVE_RIGHT, 80)
for _i in 30:
	await get_tree().physics_frame
await get_tree().create_timer(0.4).timeout
if Game.player.map_id != &"beach":
	report("error", "east bridge must fade into the beach")
	finish()
	return
```

- [ ] **Step 2: Run the probe and confirm it stays in jungle**

Expected: map_id remains jungle.

- [ ] **Step 3: Implement transition ownership in Overworld**

```gdscript
func _on_player_moved(position: Vector2) -> void:
	if _transitioning:
		return
	var record: Dictionary = _world.transition_at(_player.current_tile())
	if record.is_empty():
		return
	_begin_transition(record)
```

At fade-black midpoint: persist `map_id` and destination position together, free map/player/camera, construct destination, snap camera, then fade in. Lock movement and menu for the full fade. Invalid destination keeps the current map, fades back in, and reports an error. Restore from `Game.player.map_id` on enter; invalid positions BFS-resolve down, left, right, up.

- [ ] **Step 4: Prove both directions, no retrigger, and menu restore**

Expected: reciprocal travel works; destination is not a trigger; menu round-trip keeps the active map and tile.

- [ ] **Step 5: Commit**

```bash
git add game/states/overworld.gd game/world/player_actor.gd game/world/world_map.gd game/core/player_data.gd game/tests/autopilot/world_player.gd
git commit -m "feat: fade between jungle and beach"
```

---

### Task 6: Integration captures and documentation

**Files:**
- Modify: `game/tests/autopilot/world_player.gd`
- Modify: `game/tests/autopilot/phase1_core.gd` only if display/state assertions need map_id tolerance
- Modify: `docs/world.md`
- Modify: `docs/architecture.md`
- Modify: `README.md`
- Test: both autopilot probes

**Interfaces:**
- Verifies all Task 5–6 acceptance checks
- Does not emit `Events.encounter_triggered`

- [ ] **Step 1: Add visual checkpoints**

```gdscript
save_frame("00_jungle_spawn")
save_frame("01_jungle_station")
save_frame("02_jungle_bridge")
save_frame("03_beach_arrival")
save_frame("04_beach_shelter")
save_frame("05_beach_dunes")
```

- [ ] **Step 2: Run both probes with absolute paths**

```bash
bash /Users/mrq/Projects/gok-mon/game/tests/autopilot/run.sh /Users/mrq/Projects/gok-mon/game/tests/autopilot/phase1_core.gd
bash /Users/mrq/Projects/gok-mon/game/tests/autopilot/run.sh /Users/mrq/Projects/gok-mon/game/tests/autopilot/world_player.gd
```

Expected: exit 0, empty `errors_seen`, all frames present.

- [ ] **Step 3: Verify through Summer MCP**

Open `game/`, play, capture jungle and beach, confirm 0 errors / 0 warnings.

- [ ] **Step 4: Update docs**

`docs/world.md` and `docs/architecture.md` record two maps, licensed atlas paths, 16×16 visual / 8×8 nav, fade contract, and Person 3 encounter-zone handoff. `README.md` uses 800×480, not 480×800.

- [ ] **Step 5: Commit**

```bash
git add game/tests/autopilot/world_player.gd docs/world.md docs/architecture.md README.md
git commit -m "docs: document jungle and beach worlds"
```
