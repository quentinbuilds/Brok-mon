extends "res://core/game_state.gd"
## Person 2 overworld. Hosts the map/player. Menu key stays a state concern.

var _world: Node2D
var _player: Node2D
var _zone_label: Label


func enter() -> void:
	Game.player.movement_speed = 140.0

	_world = preload("res://world/world_map.gd").new()
	add_child(_world)

	_player = preload("res://world/player_actor.gd").new()
	_world.add_child(_player)

	var start: Vector2 = Game.player.position
	if start == Vector2.ZERO:
		start = _world.spawn_position()
	_player.setup(_world, start)

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

	var hud := CanvasLayer.new()
	add_child(hud)
	_zone_label = Label.new()
	_zone_label.position = Vector2(8, 8)
	_zone_label.add_theme_font_size_override("font_size", 13)
	_zone_label.add_theme_color_override("font_color", Color("f8f9fa"))
	_zone_label.add_theme_color_override("font_shadow_color", Color("000000"))
	_zone_label.add_theme_constant_override("shadow_offset_x", 1)
	_zone_label.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(_zone_label)
	_refresh_hud()


func update(delta: float) -> void:
	if InputManager.button_menu_just_pressed():
		Events.menu_opened.emit()
		Game.change_state(Game.GS.Id.MENU)
		return
	if _player != null:
		_player.tick(delta)
		_refresh_hud()


func _refresh_hud() -> void:
	if _zone_label == null or _player == null:
		return
	var zone := "TALL GRASS" if _player.is_in_encounter_zone() else "SAFE"
	_zone_label.text = "WASD move   C menu\n%s" % zone
