extends GameStateBase
## Overworld: 16x16 forest tiles (visual) on an 8px movement grid.
## Person 2 owns player, camera, collision, and encounter zones.
## Keep: menu key opens MENU; emit EventBus.player_moved when the tile changes.

const SPEED := 60.0
const TILE := 8
const SPRITE := 16
const BOUNDS := Rect2(0, 0, 200, 120)

@onready var _player = $Player

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
	next.x = clampf(next.x, BOUNDS.position.x, BOUNDS.end.x - SPRITE)
	next.y = clampf(next.y, BOUNDS.position.y, BOUNDS.end.y - SPRITE)
	_player.position = next
	var tile := Vector2i((next / TILE).floor())
	if tile != GameData.player_tile:
		GameData.player_tile = tile
		EventBus.player_moved.emit(tile, false)
