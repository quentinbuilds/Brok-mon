extends "res://core/game_state.gd"
## Person 2 overworld. Hosts the map/player and owns map transitions.

const FADE_SECONDS := 0.15

var _world: Node2D
var _player: Node2D
var _zone_label: Label
var _fade: ColorRect
var _transitioning: bool = false
var _moved_bound: Callable = Callable()


func enter() -> void:
	_moved_bound = _on_player_moved
	Events.player_moved.connect(_moved_bound)
	_build_world(_restored_map_id(), Game.player.position, Game.player.direction, false)
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	_zone_label = Label.new()
	_zone_label.position = Vector2(3, 108)
	_zone_label.add_theme_font_size_override("font_size", 8)
	_zone_label.add_theme_color_override("font_color", Color("f8f9fa"))
	_zone_label.add_theme_color_override("font_shadow_color", Color("000000"))
	_zone_label.add_theme_constant_override("shadow_offset_x", 1)
	_zone_label.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(_zone_label)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 80
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	_refresh_hud()


func exit() -> void:
	if _moved_bound.is_valid() and Events.player_moved.is_connected(_moved_bound):
		Events.player_moved.disconnect(_moved_bound)


func update(delta: float) -> void:
	if _transitioning:
		return
	if InputManager.button_menu_just_pressed():
		Events.menu_opened.emit()
		Game.change_state(Game.GS.Id.MENU)
		return
	if _player != null:
		_player.tick(delta)
		_refresh_hud()


func _build_world(map_id: StringName, start: Vector2, facing: Vector2, persist: bool) -> void:
	if _world != null:
		_world.queue_free()
		_world = null
		_player = null
	_world = preload("res://world/world_map.tscn").instantiate()
	add_child(_world)
	_world.setup(map_id)
	if _world.map_id() == &"":
		push_error("Failed to construct map '%s'" % map_id)
		return
	_player = preload("res://world/player_actor.gd").new()
	_world.add_child(_player)
	var resolved := _resolve_start(start)
	if facing != Vector2.ZERO:
		Game.player.direction = facing
	_player.setup(_world, resolved)
	Game.player.map_id = _world.map_id()
	if persist:
		Game.player.position = resolved
	var cam := Camera2D.new()
	cam.enabled = true
	cam.position_smoothing_enabled = false
	var map_size: Vector2 = _world.map_size_px()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(map_size.x)
	cam.limit_bottom = int(map_size.y)
	cam.limit_smoothed = false
	_player.add_child(cam)
	cam.position = cam.position.round()
	cam.make_current()


func _resolve_start(start: Vector2) -> Vector2:
	if start != Vector2.ZERO and _is_valid_position(start):
		return start.round()
	if start != Vector2.ZERO:
		var recovered := _nearest_walkable(start)
		if recovered != Vector2.ZERO:
			Game.player.position = recovered
			return recovered
	return _world.spawn_position()


func _is_valid_position(position: Vector2) -> bool:
	if int(position.x) % 8 != 0 or int(position.y) % 8 != 0:
		return false
	return _world.can_stand(position)


func _nearest_walkable(from_position: Vector2) -> Vector2:
	var start_tile: Vector2i = _world.world_to_tile(from_position + Vector2(4, 4))
	var seen := {}
	var queue: Array[Vector2i] = [start_tile]
	seen[start_tile] = true
	var order := [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		var candidate: Vector2 = _world.tile_center(tile) - Vector2(4, 4)
		if _world.can_stand(candidate):
			return candidate
		for step in order:
			var next_tile: Vector2i = tile + step
			if seen.has(next_tile) or not _world.in_bounds_tile(next_tile):
				continue
			seen[next_tile] = true
			queue.append(next_tile)
	return Vector2.ZERO


func _restored_map_id() -> StringName:
	if Game.player.map_id == &"":
		return &"jungle"
	return Game.player.map_id


func _on_player_moved(_position: Vector2) -> void:
	if _transitioning or _world == null or _player == null:
		return
	var record: Dictionary = _world.transition_at(_player.current_tile())
	if record.is_empty():
		return
	_begin_transition(record)


func _begin_transition(record: Dictionary) -> void:
	_transitioning = true
	if _player != null:
		_player.set_movement_enabled(false)
	var destination_id: StringName = record.destination_map_id
	var destination_region: StringName = record.destination_region
	var facing: Vector2 = record.destination_facing
	await _fade_to(1.0)
	var previous_id: StringName = _world.map_id()
	var previous_position: Vector2 = _player.position
	var previous_facing: Vector2 = Game.player.direction
	var destination := preload("res://world/world_map.gd").new()
	destination.setup(destination_id)
	if destination.map_id() != destination_id or destination.region_position(String(destination_region)) == Vector2.ZERO:
		push_error("Invalid transition destination %s/%s" % [destination_id, destination_region])
		destination.free()
		Game.player.map_id = previous_id
		Game.player.position = previous_position
		Game.player.direction = previous_facing
		await _fade_to(0.0)
		if _player != null:
			_player.set_movement_enabled(true)
		_transitioning = false
		return
	var dest_pos: Vector2 = destination.region_position(String(destination_region)) - _player.BODY * 0.5
	destination.free()
	Game.player.map_id = destination_id
	Game.player.position = dest_pos
	Game.player.direction = facing
	_build_world(destination_id, dest_pos, facing, true)
	if _player != null:
		_player.set_movement_enabled(false)
	await _fade_to(0.0)
	if _player != null:
		_player.set_movement_enabled(true)
	_transitioning = false
	_refresh_hud()


func _fade_to(alpha: float) -> void:
	if _fade == null:
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished


func _refresh_hud() -> void:
	if _zone_label == null or _player == null or _world == null:
		return
	var zone := "SAFE"
	if _player.is_in_encounter_zone():
		zone = _world.encounter_label()
	_zone_label.text = "ZONE: %s" % zone
