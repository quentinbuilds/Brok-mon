extends GameStateBase
## Placeholder overworld: a square that moves 4-way inside the 200x120 viewport.
## Person 2 replaces this with the real map, player, camera and encounter zones.
## Keep: menu key opens MENU; emit EventBus.player_moved when the tile changes.

const SPEED := 60.0
const TILE := 8
const BOUNDS := Rect2(0, 0, 200, 120)

@onready var _player: ColorRect = $Player

func _on_enter() -> void:
	_player.position = Vector2(GameData.player_tile * TILE)

func update(delta: float) -> void:
	if InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.MENU)
		return
	var dir := InputManager.direction()
	if dir == Vector2i.ZERO:
		return
	var next := _player.position + Vector2(dir) * SPEED * delta
	next.x = clampf(next.x, BOUNDS.position.x, BOUNDS.end.x - TILE)
	next.y = clampf(next.y, BOUNDS.position.y, BOUNDS.end.y - TILE)
	_player.position = next
	var tile := Vector2i((next / TILE).floor())
	if tile != GameData.player_tile:
		GameData.player_tile = tile
		EventBus.player_moved.emit(tile, false)
