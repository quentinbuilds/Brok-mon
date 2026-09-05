extends TestCase

const MapCycle := preload("res://world/MapCycle.gd")
const GrassMap := preload("res://world/GrassMap.gd")


func _overworld() -> OverworldState:
	var world := load("res://world/OverworldState.tscn").instantiate() as OverworldState
	tree.root.add_child(world)
	GameData.player_tile = GrassMap.START_TILE
	world.enter({})
	return world


func test_alternate_map_assets_ship_and_load() -> void:
	for path in [
		"res://assets/backgrounds/beach_map.png",
		"res://assets/backgrounds/house_interior_map.png",
	]:
		assert_true(ResourceLoader.exists(path), path)
		assert_eq((load(path) as Texture2D).get_size(), Vector2(1280, 720))


func test_interior_has_walkable_floor_and_no_encounters() -> void:
	assert_true(MapCycle.is_walkable(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_SPAWN))
	assert_true(MapCycle.is_walkable(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_EXIT))
	assert_false(MapCycle.is_walkable(MapCycle.Mode.INTERIOR, Vector2i(9, 5)))
	assert_false(MapCycle.is_encounter_zone(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_SPAWN))
	assert_true(MapCycle.is_walkable(MapCycle.Mode.DEFAULT, MapCycle.DEFAULT_RETURN))


func test_player_uses_active_map_walkability() -> void:
	var player := preload("res://world/Player.gd").new()
	player.place(Vector2i(10, 9))
	player.set_walkable_query(func(tile: Vector2i) -> bool: return tile == Vector2i(10, 10))
	assert_true(player.try_step(Vector2i.DOWN))
	player.place(Vector2i(10, 9))
	assert_false(player.try_step(Vector2i.LEFT))
	player.free()


func test_house_exit_cycles_beach_then_default() -> void:
	var world := _overworld()
	assert_eq(world.map_mode, MapCycle.Mode.DEFAULT)
	assert_true(world._try_map_transition(MapCycle.DEFAULT_DOOR))
	assert_eq(world.map_mode, MapCycle.Mode.INTERIOR)
	assert_eq(GameData.player_tile, MapCycle.INTERIOR_SPAWN)

	assert_true(world._try_map_transition(MapCycle.INTERIOR_EXIT))
	assert_eq(world.map_mode, MapCycle.Mode.BEACH)
	assert_eq(GameData.player_tile, MapCycle.BEACH_RETURN)
	assert_true(world._try_map_transition(MapCycle.BEACH_DOOR))
	assert_eq(world.map_mode, MapCycle.Mode.INTERIOR)

	assert_true(world._try_map_transition(MapCycle.INTERIOR_EXIT))
	assert_eq(world.map_mode, MapCycle.Mode.DEFAULT)
	assert_eq(GameData.player_tile, MapCycle.DEFAULT_RETURN)
	assert_eq(world.next_exterior, MapCycle.Mode.BEACH)
	world.free()


func test_scene_visibility_follows_map_mode() -> void:
	var world := _overworld()
	world._switch_map(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_SPAWN)
	assert_true(world.get_node("InteriorBackground").visible)
	assert_false(world.get_node("Tiles").visible)
	assert_false(world.get_node("House").visible)
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	assert_true(world.get_node("BeachBackground").visible)
	assert_true(world.get_node("BeachHouse").visible)
	assert_false(world.is_in_encounter_zone())
	world.free()


func test_transition_requires_direction_release_before_another_step() -> void:
	var world := _overworld()
	world._switch_map(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_SPAWN)
	Input.action_press("move_down")
	world.update(0.02)
	assert_eq(GameData.player_tile, MapCycle.INTERIOR_SPAWN)
	Input.action_release("move_down")
	world.update(0.02)
	assert_false(world._map_transition_locked)
	world.free()
