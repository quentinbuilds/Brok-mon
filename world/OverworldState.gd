extends GameStateBase
## Overworld: 16x16 forest tiles (visual) on an 8px movement grid.
## Person 2 owns player, camera, collision, and encounter zones.
## Keep: menu key opens MENU; emit EventBus.player_moved when the tile changes.

const SPEED := 60.0
const TILE := 8
const SPRITE := 16
const NPC_GROUP := "npc"

@onready var _player = $Player
@onready var _map: TileMapLayer = $ForestMap
@onready var _camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	_apply_camera_limits()

func _on_enter() -> void:
	_apply_camera_limits()
	if GameData.player_tile == Vector2i.ZERO:
		GameData.player_tile = _fresh_spawn_tile()
	_player.position = Vector2(GameData.player_tile * TILE)

func _apply_camera_limits() -> void:
	if _camera == null:
		return
	var r := walk_bounds()
	_camera.limit_enabled = true
	_camera.limit_left = int(r.position.x)
	_camera.limit_top = int(r.position.y)
	_camera.limit_right = int(r.end.x)
	_camera.limit_bottom = int(r.end.y)
	_camera.limit_smoothed = false
	_camera.position_smoothing_enabled = false

func _fresh_spawn_tile() -> Vector2i:
	var half := Vector2(SPRITE * 0.5, SPRITE * 0.5)
	var preferred := Vector2i(((walk_bounds().get_center() - half) / TILE).floor())
	if _can_spawn_at(preferred):
		return preferred
	for radius in range(1, 20):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if maxi(absi(x), absi(y)) != radius:
					continue
				var t := preferred + Vector2i(x, y)
				if _can_spawn_at(t):
					return t
	return preferred

func _can_spawn_at(tile: Vector2i) -> bool:
	var pos := Vector2(tile * TILE)
	var b := walk_bounds()
	if pos.x < b.position.x or pos.y < b.position.y:
		return false
	if pos.x > b.end.x - SPRITE or pos.y > b.end.y - SPRITE:
		return false
	return can_walk(pos)

func update(delta: float) -> void:
	if InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.MENU)
		return
	var dir := InputManager.direction()
	_player.apply_move_dir(dir)
	if dir == Vector2i.ZERO:
		return
	var next: Vector2 = _player.position + Vector2(dir) * SPEED * delta
	try_move(next)

func can_walk(pos: Vector2) -> bool:
	return not is_blocked(_footprint(pos))

func is_blocked(rect: Rect2) -> bool:
	return _water_blocks(rect) or _npc_blocks(rect)

func walk_bounds() -> Rect2:
	if _map != null:
		return _map.pixel_rect()
	return Rect2(0, 0, 200, 120)


func try_move(next: Vector2) -> bool:
	var b := walk_bounds()
	next.x = clampf(next.x, b.position.x, b.end.x - SPRITE)
	next.y = clampf(next.y, b.position.y, b.end.y - SPRITE)
	if is_blocked(_footprint(next)):
		return false
	_player.position = next
	var tile := Vector2i((next / TILE).floor())
	if tile != GameData.player_tile:
		GameData.player_tile = tile
		EventBus.player_moved.emit(tile, false)
	return true

func _footprint(pos: Vector2) -> Rect2:
	return Rect2(pos, Vector2(SPRITE, SPRITE))

func _water_blocks(rect: Rect2) -> bool:
	if _map == null:
		return false
	var first: Vector2i = _map.local_to_map(rect.position)
	var last: Vector2i = _map.local_to_map(rect.position + rect.size - Vector2.ONE)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			if _map.is_water_cell(Vector2i(x, y)):
				return true
	return false

func _npc_blocks(rect: Rect2) -> bool:
	if not is_inside_tree():
		return false
	for n in get_tree().get_nodes_in_group(NPC_GROUP):
		if n == _player or not (n is Node2D):
			continue
		var npc_rect := Rect2((n as Node2D).position, Vector2(SPRITE, SPRITE))
		if rect.intersects(npc_rect):
			return true
	return false
