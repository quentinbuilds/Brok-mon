extends Node2D
## Overworld actor. Reads InputManager only. Emits Events.player_moved.

const BODY := Vector2(24, 24)

var world: Node = null
var _walk_phase: float = 0.0
var _moving: bool = false
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


func is_in_encounter_zone() -> bool:
	if world == null:
		return false
	return world.is_encounter_zone(position + BODY * 0.5)


func tick(delta: float) -> void:
	var move: Vector2 = InputManager.move_vector()
	_moving = move != Vector2.ZERO
	if _moving:
		Game.player.direction = move
		_walk_phase += delta * 10.0
		_frame = 1 if int(_walk_phase) % 2 == 0 else 0
		var next: Vector2 = position + move * Game.player.movement_speed * delta
		if world.can_stand(next, BODY):
			position = next
			Game.player.position = position
			Events.player_moved.emit(position)
	else:
		_walk_phase = 0.0
		_frame = 0
	queue_redraw()


func _draw() -> void:
	var bob := -2.0 if _moving and _frame == 1 else 0.0
	var o := Vector2(0, bob)
	var dir: Vector2 = Game.player.direction

	draw_rect(Rect2(o + Vector2(4, 20), Vector2(16, 4)), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(o + Vector2(5, 10), Vector2(14, 12)), Color("1d3557"))
	draw_rect(Rect2(o + Vector2(7, 2), Vector2(10, 10)), Color("f4d35e"))
	draw_rect(Rect2(o + Vector2(7, 2), Vector2(10, 4)), Color("6f1d1b"))

	if dir == Vector2.DOWN:
		draw_rect(Rect2(o + Vector2(9, 6), Vector2(2, 2)), Color("1d3557"))
		draw_rect(Rect2(o + Vector2(13, 6), Vector2(2, 2)), Color("1d3557"))
	elif dir == Vector2.UP:
		draw_rect(Rect2(o + Vector2(7, 2), Vector2(10, 8)), Color("6f1d1b"))
	elif dir == Vector2.LEFT:
		draw_rect(Rect2(o + Vector2(8, 6), Vector2(2, 2)), Color("1d3557"))
	elif dir == Vector2.RIGHT:
		draw_rect(Rect2(o + Vector2(14, 6), Vector2(2, 2)), Color("1d3557"))

	var foot_y := 20.0 + (2.0 if _moving and _frame == 1 else 0.0)
	if dir.x != 0.0 and _moving:
		draw_rect(Rect2(o + Vector2(6, foot_y), Vector2(4, 3)), Color("3d2b1f"))
		draw_rect(Rect2(o + Vector2(14, 20.0 + (0.0 if _frame == 1 else 2.0)), Vector2(4, 3)), Color("3d2b1f"))
	else:
		draw_rect(Rect2(o + Vector2(7, 20), Vector2(4, 3)), Color("3d2b1f"))
		draw_rect(Rect2(o + Vector2(13, foot_y), Vector2(4, 3)), Color("3d2b1f"))
