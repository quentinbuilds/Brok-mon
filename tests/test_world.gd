extends TestCase
## World: map integrity, tile collision, encounter zones, and the player's stepping rules.

const GrassMap := preload("res://world/GrassMap.gd")
const PlayerScript := preload("res://world/Player.gd")

const CARDINALS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

func after_each() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right", "menu"]:
		Input.action_release(a)

# --- map data ---

func test_map_is_rectangular() -> void:
	assert_eq(GrassMap.MAP.size(), GrassMap.HEIGHT)
	for y in GrassMap.MAP.size():
		assert_eq(GrassMap.MAP[y].length(), GrassMap.WIDTH, "row %d width" % y)

func test_every_glyph_has_an_atlas_column() -> void:
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var g := GrassMap.glyph(Vector2i(x, y))
			assert_true(GrassMap.ATLAS_COLUMN.has(g), "unknown glyph '%s' at %d,%d" % [g, x, y])

func test_border_is_solid_so_the_player_cannot_leave() -> void:
	for x in GrassMap.WIDTH:
		assert_false(GrassMap.is_walkable(Vector2i(x, 0)), "top edge %d" % x)
		assert_false(GrassMap.is_walkable(Vector2i(x, GrassMap.HEIGHT - 1)), "bottom edge %d" % x)
	for y in GrassMap.HEIGHT:
		assert_false(GrassMap.is_walkable(Vector2i(0, y)), "left edge %d" % y)
		assert_false(GrassMap.is_walkable(Vector2i(GrassMap.WIDTH - 1, y)), "right edge %d" % y)

func test_out_of_bounds_reads_as_blocked() -> void:
	assert_false(GrassMap.is_walkable(Vector2i(-1, 5)))
	assert_false(GrassMap.is_walkable(Vector2i(GrassMap.WIDTH, 5)))
	assert_false(GrassMap.is_walkable(Vector2i(5, -1)))
	assert_false(GrassMap.is_walkable(Vector2i(5, GrassMap.HEIGHT)))

func test_start_tile_is_walkable() -> void:
	assert_true(GrassMap.is_walkable(GrassMap.START_TILE))

func test_obstacles_block_and_ground_does_not() -> void:
	assert_false(GrassMap.is_walkable(Vector2i(26, 4)), "tree")
	assert_false(GrassMap.is_walkable(Vector2i(4, 16)), "water")
	assert_false(GrassMap.is_walkable(Vector2i(16, 5)), "rock")
	assert_true(GrassMap.is_walkable(Vector2i(6, 4)), "tall grass")
	assert_true(GrassMap.is_walkable(Vector2i(3, 2)), "path")

func test_map_has_a_usable_amount_of_tall_grass() -> void:
	var n := 0
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			if GrassMap.is_encounter_zone(Vector2i(x, y)):
				n += 1
	assert_true(n >= 30, "expected real encounter fields, got %d tiles" % n)

func test_encounter_zones_are_walkable() -> void:
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var t := Vector2i(x, y)
			if GrassMap.is_encounter_zone(t):
				assert_true(GrassMap.is_walkable(t), "unreachable grass at %d,%d" % [x, y])

func test_every_walkable_tile_is_reachable_from_start() -> void:
	var seen := {GrassMap.START_TILE: true}
	var stack: Array[Vector2i] = [GrassMap.START_TILE]
	while not stack.is_empty():
		var t: Vector2i = stack.pop_back()
		for d in CARDINALS:
			var n: Vector2i = t + d
			if not seen.has(n) and GrassMap.is_walkable(n):
				seen[n] = true
				stack.append(n)
	var walkable := 0
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			if GrassMap.is_walkable(Vector2i(x, y)):
				walkable += 1
	assert_eq(seen.size(), walkable, "every walkable tile must be reachable from the start")

# --- player stepping ---

func test_place_snaps_position_to_the_tile_grid() -> void:
	var p := PlayerScript.new()
	p.place(Vector2i(3, 3))
	assert_eq(p.tile, Vector2i(3, 3))
	assert_eq(p.position, Vector2(24, 24))
	assert_false(p.is_stepping())
	p.free()

func test_step_onto_open_ground_commits_the_tile_immediately() -> void:
	var p := PlayerScript.new()
	p.place(Vector2i(3, 3))
	assert_true(p.try_step(Vector2i.DOWN))
	assert_true(p.is_stepping())
	assert_eq(p.tile, Vector2i(3, 4))
	p.free()

func test_step_into_an_obstacle_only_turns() -> void:
	var p := PlayerScript.new()
	p.place(Vector2i(1, 3))
	assert_false(p.try_step(Vector2i.LEFT), "hedge at 0,3 blocks")
	assert_eq(p.tile, Vector2i(1, 3), "tile unchanged")
	assert_eq(p.facing, Vector2i.LEFT, "still faces the obstacle")
	assert_false(p.is_stepping())
	p.free()

func test_advance_reports_completion_exactly_once() -> void:
	var p := PlayerScript.new()
	p.place(Vector2i(3, 3))
	p.try_step(Vector2i.DOWN)
	var completions := 0
	for i in 20:
		if p.advance(0.02):
			completions += 1
	assert_eq(completions, 1)
	assert_false(p.is_stepping())
	assert_eq(p.position, Vector2(24, 32), "lands exactly on the tile")
	p.free()

func test_only_one_step_at_a_time() -> void:
	var p := PlayerScript.new()
	p.place(Vector2i(3, 3))
	p.try_step(Vector2i.DOWN)
	assert_false(p.try_step(Vector2i.RIGHT), "cannot start a step mid-step")
	assert_eq(p.tile, Vector2i(3, 4))
	p.free()

func test_no_direction_does_nothing() -> void:
	var p := PlayerScript.new()
	p.place(Vector2i(3, 3))
	assert_false(p.try_step(Vector2i.ZERO))
	assert_false(p.is_stepping())
	p.free()

func test_facing_picks_the_sprite_row() -> void:
	var p := PlayerScript.new()
	for dir in CARDINALS:
		p.place(Vector2i(3, 3))
		p.try_step(dir)
		assert_eq(int(p.frame / 2), int(PlayerScript.DIR_ROW[dir]), "sprite row for %s" % dir)
	p.free()

# --- state wiring ---

func _overworld() -> Node:
	var ow = load("res://world/OverworldState.tscn").instantiate()
	tree.root.add_child(ow)
	return ow

func test_entering_snaps_an_invalid_stored_tile_to_the_start() -> void:
	GameData.player_tile = Vector2i.ZERO
	var ow := _overworld()
	ow.enter({})
	assert_eq(GameData.player_tile, GrassMap.START_TILE)
	ow.free()

func test_entering_keeps_a_valid_stored_tile() -> void:
	GameData.player_tile = Vector2i(6, 4)
	var ow := _overworld()
	ow.enter({})
	assert_eq(GameData.player_tile, Vector2i(6, 4), "returning from battle resumes in place")
	assert_true(ow.is_in_encounter_zone(), "6,4 is tall grass")
	ow.free()

## 0.02 x 8 = 0.16s, just past one STEP_TIME, so exactly one step lands.
const ONE_STEP_FRAMES := 8

func _walk(ow: Node, action: String, frames: int) -> Array:
	var seen: Array = []
	var handler := func(t, in_zone): seen.append([t, in_zone])
	EventBus.player_moved.connect(handler)
	Input.action_press(action)
	for i in frames:
		ow.update(0.02)
	EventBus.player_moved.disconnect(handler)
	return seen

func test_completed_step_emits_player_moved_with_the_zone_flag() -> void:
	# 6,4 and 7,4 are both tall grass, so the step lands inside an encounter zone.
	GameData.player_tile = Vector2i(6, 4)
	var ow := _overworld()
	ow.enter({})
	var seen := _walk(ow, "move_right", ONE_STEP_FRAMES)
	assert_eq(seen.size(), 1, "one signal per completed step")
	assert_eq(seen[0][0], Vector2i(7, 4))
	assert_true(seen[0][1], "in_encounter_zone must be true in tall grass")
	assert_eq(GameData.player_tile, Vector2i(7, 4), "GameData tracks the player")
	ow.free()

func test_step_onto_a_path_reports_no_encounter_zone() -> void:
	# 3,2 and 4,2 are path tiles.
	GameData.player_tile = Vector2i(3, 2)
	var ow := _overworld()
	ow.enter({})
	var seen := _walk(ow, "move_right", ONE_STEP_FRAMES)
	assert_eq(seen.size(), 1)
	assert_false(seen[0][1], "path steps are not encounter rolls")
	ow.free()

func test_holding_a_direction_keeps_stepping() -> void:
	GameData.player_tile = Vector2i(6, 4)
	var ow := _overworld()
	ow.enter({})
	var seen := _walk(ow, "move_right", ONE_STEP_FRAMES * 2)
	assert_eq(seen.size(), 2, "a held direction walks tile after tile")
	assert_eq(seen[0][0], Vector2i(7, 4))
	assert_eq(seen[1][0], Vector2i(8, 4))
	ow.free()

func test_walking_into_the_border_emits_nothing() -> void:
	GameData.player_tile = Vector2i(1, 3)
	var ow := _overworld()
	ow.enter({})
	var seen := _walk(ow, "move_left", ONE_STEP_FRAMES * 2)
	assert_eq(seen.size(), 0, "blocked by hedge, so no step completed")
	assert_eq(GameData.player_tile, Vector2i(1, 3))
	ow.free()
