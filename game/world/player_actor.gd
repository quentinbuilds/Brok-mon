extends Node2D
## Overworld actor. Reads InputManager only. Emits Events.player_moved.

const BODY := Vector2(24, 24)
const STEP_PIXELS := 8.0
const STEP_SECONDS := 0.10
const HOLD_DELAY := 0.18

var world: Node = null
var player_atlas: Texture2D = preload("res://assets/sprites/player.png")
var _step_start := Vector2.ZERO
var _step_target := Vector2.ZERO
var _step_elapsed := 0.0
var _moving: bool = false
var _held_time := 0.0
var _last_direction := Vector2.ZERO
var _frame: int = 0


func setup(world_map: Node, start: Vector2) -> void:
	world = world_map
	position = start
	Game.player.position = position
	if Game.player.direction == Vector2.ZERO:
		Game.player.direction = Vector2.DOWN
	z_index = 10
	queue_redraw()


func is_moving() -> bool:
	return _moving


func current_tile() -> Vector2i:
	return world.world_to_tile(position + BODY * 0.5)


func is_in_encounter_zone() -> bool:
	if world == null:
		return false
	return world.is_encounter_zone(position + BODY * 0.5)


func try_step(direction: Vector2) -> bool:
	if _moving:
		return false
	Game.player.direction = direction
	var target := position + direction * STEP_PIXELS
	if not world.can_stand(target, BODY):
		queue_redraw()
		return false
	_step_start = position
	_step_target = target
	_step_elapsed = 0.0
	_moving = true
	_frame = 1
	queue_redraw()
	return true


func tick(delta: float) -> void:
	if _moving:
		_step_elapsed += delta
		var weight := minf(_step_elapsed / STEP_SECONDS, 1.0)
		position = _step_start.lerp(_step_target, weight).round()
		if weight >= 1.0:
			position = _step_target.round()
			_moving = false
			_frame = 0
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


func _draw() -> void:
	var direction: Vector2 = Game.player.direction
	var column := 0
	if direction == Vector2.UP:
		column = 1
	elif direction == Vector2.LEFT:
		column = 2
	elif direction == Vector2.RIGHT:
		column = 3
	var source := Rect2(column * 16, _frame * 20, 16, 20)
	var destination := Rect2(Vector2(4, 4), Vector2(16, 20))
	draw_texture_rect_region(player_atlas, destination, source)
