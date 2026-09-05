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
	save_frame("00_overworld")

	actor.try_step(Vector2.RIGHT)
	await settle(2)
	save_frame("00_step_right")
	for _i in 12:
		await get_tree().physics_frame
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
	var start_tile: Vector2i = actor.current_tile()
	await press(InputManager.MOVE_RIGHT, 80)
	if move_events[0] != 0:
		report("error", "player_moved emitted before the step completed")
		finish()
		return
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
	if move_events[0] != 1:
		report("error", "one completed step must emit player_moved exactly once")
		finish()
		return

	var before_short_hold: Vector2i = actor.current_tile()
	await press(InputManager.MOVE_RIGHT, 250)
	for _i in 12:
		await get_tree().physics_frame
	if actor.current_tile() != before_short_hold + Vector2i.RIGHT:
		report("error", "movement repeated before the hold delay")
		finish()
		return

	var events_before_hold: int = move_events[0]
	var before_hold: Vector2i = actor.current_tile()
	await press(InputManager.MOVE_RIGHT, 350)
	for _i in 12:
		await get_tree().physics_frame
	if actor.current_tile() != before_hold + Vector2i.RIGHT * 2:
		report("error", "held movement must repeat after the hold delay")
		finish()
		return
	if move_events[0] != events_before_hold + 2:
		report("error", "held movement emitted the wrong number of completed steps")
		finish()
		return

	var blocked_attempt := _find_blocked_attempt(world)
	if blocked_attempt.is_empty():
		report("error", "could not find a blocked movement fixture")
		finish()
		return
	actor.position = blocked_attempt.position
	Game.player.position = actor.position
	var blocked_start: Vector2 = actor.position
	var blocked_events: int = move_events[0]
	if actor.try_step(blocked_attempt.direction):
		report("error", "blocked step unexpectedly started")
		finish()
		return
	if actor.position != blocked_start:
		report("error", "blocked step changed player position")
		finish()
		return
	if Game.player.direction != blocked_attempt.direction:
		report("error", "blocked step did not update facing")
		finish()
		return
	if move_events[0] != blocked_events:
		report("error", "blocked step emitted player_moved")
		finish()
		return

	actor.position = world.spawn_position()
	Game.player.position = actor.position

	var start: Vector2 = actor.position
	await press(InputManager.MOVE_UP, 280)
	await settle(2)
	var after_path: Vector2 = actor.position
	report("moved_north", after_path.y < start.y)
	save_frame("01_path")

	if after_path.y >= start.y:
		report("error", "player did not walk north on the path")
		finish()
		return

	# Walk left long enough to hit the west tree wall; must stay on walkable tiles.
	await press(InputManager.MOVE_LEFT, 1100)
	await settle(2)
	var after_block: Vector2 = actor.position
	report("blocked_center_is_walkable", not world.is_blocked(after_block + Vector2(6, 6)))
	save_frame("02_collision")

	if world.is_blocked(after_block + Vector2(6, 6)):
		report("error", "player center is inside a blocked tile")
		finish()
		return

	actor.position = world.spawn_position()
	Game.player.position = actor.position
	await press(InputManager.MOVE_RIGHT, 1800)
	await settle(2)
	report("in_grass", actor.is_in_encounter_zone())
	save_frame("03_grass")

	if not actor.is_in_encounter_zone():
		report("error", "expected to be in tall grass after walking east of the spawn path")
		finish()
		return

	var camera: Camera2D = null
	for child in actor.get_children():
		if child is Camera2D:
			camera = child
			break
	if camera == null or camera.position_smoothing_enabled or camera.limit_smoothed:
		report("error", "camera must be pixel-snapped without smoothing")
		finish()
		return
	for landmark in [
		["04_fossil_clearing", "fossil_clearing", Vector2(12, 12)],
		["05_pond", "pond", Vector2(52, 12)],
	]:
		actor.position = world.region_position(landmark[1]) - landmark[2]
		Game.player.position = actor.position
		if camera != null:
			camera.reset_smoothing()
		await settle(3)
		save_frame(landmark[0])

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
	finish()


func _find_blocked_attempt(world: Node) -> Dictionary:
	var body := Vector2(24, 24)
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var size: Vector2i = Vector2i(world.map_size_px())
	for y in range(0, size.y - int(body.y) + 1, GameConfig.TILE_SIZE):
		for x in range(0, size.x - int(body.x) + 1, GameConfig.TILE_SIZE):
			var position := Vector2(x, y)
			if not world.can_stand(position, body):
				continue
			for direction in directions:
				if not world.can_stand(
						position + direction * GameConfig.TILE_SIZE, body):
					return {"position": position, "direction": direction}
	return {}


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
