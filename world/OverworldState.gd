extends GameStateBase
## Overworld: 16x16 forest tiles (visual) on an 8px movement grid.
## Person 2 owns player, camera, collision, and encounter zones.
## Keep: menu key opens MENU; emit EventBus.player_moved when the tile changes.

const SPEED := 60.0
const TILE := 8
const SPRITE := 16
const BOUNDS := Rect2(0, 0, 200, 120)
const NPC_GROUP := "npc"

@onready var _player = $Player
@onready var _map: TileMapLayer = $ForestMap

func _on_enter() -> void:
	_player.position = Vector2(GameData.player_tile * TILE)

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

func try_move(next: Vector2) -> bool:
	next.x = clampf(next.x, BOUNDS.position.x, BOUNDS.end.x - SPRITE)
	next.y = clampf(next.y, BOUNDS.position.y, BOUNDS.end.y - SPRITE)
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
