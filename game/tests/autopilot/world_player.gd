extends "res://tests/autopilot/probe_base.gd"

const GS = preload("res://core/game_state.gd")


func _ready() -> void:
	await super._ready()
	await settle(3)

	if Game.current_id != GS.Id.OVERWORLD:
		await press(InputManager.BTN_A, 80)
		await settle(4)

	if Game.current_id != GS.Id.OVERWORLD:
		report("error", "did not reach OVERWORLD")
		finish()
		return

	var world := _find_world()
	var actor := _find_actor(world)
	if world == null or actor == null:
		report("error", "world or player missing")
		dump_tree()
		finish()
		return

	if (
			world.tile_atlas == null
			or world.tile_atlas.resource_path != "res://assets/tiles/jungle_tiles.png"
			or world.prop_atlas == null
			or world.prop_atlas.resource_path != "res://assets/sprites/jungle_props.png"
	):
		report("error", "jungle atlases must use imported Texture2D resources")
		finish()
		return

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

	report("map_size", world.map_size_px())
	report("spawn", world.spawn_position())
	save_frame("00_jungle_spawn")

	var reentrant_start: Vector2 = actor.position
	if not actor.try_step(Vector2.RIGHT):
		report("error", "initial reentrant-step fixture did not start")
		finish()
		return
	await settle(2)
	if not actor.is_moving():
		report("error", "reentrant-step fixture was not still interpolating")
		finish()
		return
	if actor.try_step(Vector2.DOWN):
		report("error", "try_step accepted a second call during interpolation")
		finish()
		return
	for _i in 12:
		await get_tree().physics_frame
	if actor.position != reentrant_start + Vector2.RIGHT * GameConfig.TILE_SIZE:
		report("error", "reentrant attempt changed the active step target")
		finish()
		return
	if (
			int(actor.position.x) % GameConfig.TILE_SIZE != 0
			or int(actor.position.y) % GameConfig.TILE_SIZE != 0
	):
		report("error", "reentrant attempt completed off the 8px grid")
		finish()
		return
	actor.position = world.spawn_position()
	Game.player.position = actor.position

	if (
			actor.player_atlas == null
			or actor.player_atlas.resource_path != "res://assets/sprites/player.png"
	):
		report("error", "player must use the imported player atlas")
		finish()
		return

	var move_events := [0]
	Events.player_moved.connect(func(_position): move_events[0] += 1)
	var camera: Camera2D = null
	for child in actor.get_children():
		if child is Camera2D:
			camera = child
			break
	if camera == null or camera.position_smoothing_enabled or camera.limit_smoothed:
		report("error", "camera must be pixel-snapped without smoothing")
		finish()
		return

	# Known research-hut fixture: the south approach attempts to enter door (17, 19).
	var hut_door := Vector2i(17, 19)
	if not world.is_house_door(hut_door) or not world.is_blocked_tile(hut_door):
		report("error", "known research hut door must be marked and blocked")
		finish()
		return
	_place_actor_on_tile(actor, world, Vector2i(17, 21))
	await settle(3)
	save_frame("01_research_huts")
	var hut_start: Vector2 = actor.position
	var hut_events: int = move_events[0]
	if actor.try_step(Vector2.UP):
		report("error", "blocked hut-door step unexpectedly started")
		finish()
		return
	if actor.position != hut_start or move_events[0] != hut_events:
		report("error", "blocked hut-door attempt changed position or emitted player_moved")
		finish()
		return
	if Game.player.direction != Vector2.UP:
		report("error", "blocked hut-door attempt did not update facing")
		finish()
		return
	await settle(2)
	save_frame("05_blocked_hut_door")
	report("hut_door_blocked", true)

	# Known pond fixture: approaching the water from the south must not start a step.
	_place_actor_on_tile(actor, world, Vector2i(42, 12))
	await settle(3)
	save_frame("04_pond")
	var water_start: Vector2 = actor.position
	var water_events: int = move_events[0]
	if not world.is_blocked_tile(Vector2i(42, 10)):
		report("error", "known pond water tile must be blocked")
		finish()
		return
	if actor.try_step(Vector2.UP):
		report("error", "blocked water step unexpectedly started")
		finish()
		return
	if actor.position != water_start or move_events[0] != water_events:
		report("error", "blocked water attempt changed position or emitted player_moved")
		finish()
		return
	report("water_blocked", true)

	# A lawn-to-grass step must change the encounter-zone state false -> true.
	_place_actor_on_tile(actor, world, Vector2i(14, 24))
	if actor.is_in_encounter_zone():
		report("error", "lawn fixture unexpectedly starts in tall grass")
		finish()
		return
	var lawn_tile: Vector2i = actor.current_tile()
	if not actor.try_step(Vector2.RIGHT):
		report("error", "lawn-to-tall-grass step did not start")
		finish()
		return
	for _i in 12:
		await get_tree().physics_frame
	if actor.current_tile() != lawn_tile + Vector2i.RIGHT or not actor.is_in_encounter_zone():
		report("error", "lawn-to-tall-grass transition did not change false -> true")
		finish()
		return
	await settle(3)
	save_frame("03_tall_grass")
	report("lawn_to_grass", true)

	# A tall-grass-to-path step must change the encounter-zone state true -> false.
	_place_actor_on_tile(actor, world, Vector2i(23, 7))
	if not actor.is_in_encounter_zone():
		report("error", "north-meadow fixture must start in tall grass")
		finish()
		return
	var grass_tile: Vector2i = actor.current_tile()
	if not actor.try_step(Vector2.RIGHT):
		report("error", "tall-grass-to-path step did not start")
		finish()
		return
	for _i in 12:
		await get_tree().physics_frame
	if actor.current_tile() != grass_tile + Vector2i.RIGHT or actor.is_in_encounter_zone():
		report("error", "tall-grass-to-path transition did not change true -> false")
		finish()
		return
	report("grass_to_path", true)

	# The central trail is walkable, safe, and preserves the 8px step contract.
	_place_actor_on_tile(actor, world, Vector2i(25, 9))
	var path_start: Vector2 = actor.position
	if not world.can_stand(path_start) or actor.is_in_encounter_zone():
		report("error", "known path fixture must be walkable and encounter-safe")
		finish()
		return
	if not actor.try_step(Vector2.DOWN):
		report("error", "safe path step did not start")
		finish()
		return
	for _i in 12:
		await get_tree().physics_frame
	if actor.position != path_start + Vector2.DOWN * GameConfig.TILE_SIZE:
		report("error", "safe path step did not move by exactly one grid step")
		finish()
		return
	if actor.is_in_encounter_zone() or not world.can_stand(actor.position):
		report("error", "safe path step ended blocked or inside an encounter zone")
		finish()
		return
	report("path_safe", true)

	_place_actor_at(actor, world.region_position("fossil_clearing") - Vector2(12, 12))
	await settle(3)
	save_frame("02_fossil_clearing")

	# Menu round-trip must preserve the session position and recreate the overworld.
	var before_menu: Vector2 = actor.position
	await press(InputManager.BTN_MENU, 80)
	await settle(3)
	if Game.current_id != GS.Id.MENU:
		report("error", "menu button did not open MENU from the jungle")
		finish()
		return
	await press(InputManager.BTN_B, 80)
	await settle(4)
	if Game.current_id != GS.Id.OVERWORLD:
		report("error", "B on menu did not return to OVERWORLD")
		finish()
		return
	world = _find_world()
	actor = _find_actor(world)
	if world == null or actor == null or actor.position != before_menu:
		report("error", "menu round-trip did not recreate the jungle at the saved position")
		finish()
		return
	report("menu_round_trip", true)

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
	if GameConfig.PIXEL_SCALE != 4:
		report("error", "pixel scale must be 4")
		finish()
		return
	finish()


func _place_actor_on_tile(actor: Node, world: Node, tile: Vector2i) -> void:
	_place_actor_at(actor, world.tile_center(tile) - Vector2(12, 12))


func _place_actor_at(actor: Node, position: Vector2) -> void:
	actor.position = position
	Game.player.position = position
	var camera: Camera2D = actor.get_viewport().get_camera_2d()
	if camera != null:
		camera.reset_smoothing()


func _find_world() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return _find_by_script(scene, "res://world/world_map.gd")


func _find_actor(world: Node) -> Node:
	if world == null:
		return null
	return _find_by_script(world, "res://world/player_actor.gd")


func _find_by_script(root: Node, path: String) -> Node:
	var want := load(path)
	if root.get_script() == want:
		return root
	for child in root.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null
