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
	await press(InputManager.MOVE_RIGHT, 900)
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
