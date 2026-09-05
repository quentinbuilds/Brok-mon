extends GameStateBase
class_name OverworldState
## Placeholder overworld: a square that moves 4-way inside the 200x120 viewport.
## Person 2 replaces this with the real map, player, camera and encounter zones.
## Keep: menu key opens MENU; emit EventBus.player_moved when the tile changes.
## A talks to a nearby node in group "npc" (NpcTalk lines).

const SPEED := 60.0
const TILE := 8
const BOUNDS := Rect2(0, 0, 200, 120)
const NPC_GROUP := "npc"

@onready var _player: ColorRect = $Player
@onready var _talk: Label = $TalkBox

var talking: bool = false


func _on_enter() -> void:
	_player.position = Vector2(GameData.player_tile * TILE)
	_close_talk()


func update(delta: float) -> void:
	if talking:
		if InputManager.button_a_just_pressed() \
				or InputManager.button_b_just_pressed() \
				or InputManager.button_menu_just_pressed():
			_close_talk()
		return
	if InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.MENU)
		return
	if InputManager.button_a_just_pressed():
		if try_talk():
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


func try_talk() -> bool:
	if not is_inside_tree():
		return false
	var npc := NpcTalk.nearest(_player.position, get_tree().get_nodes_in_group(NPC_GROUP))
	if npc == null:
		return false
	_open_talk(NpcTalk.line_for_node(npc))
	return true


func _open_talk(text: String) -> void:
	talking = true
	if _talk:
		_talk.text = text
		_talk.visible = true


func _close_talk() -> void:
	talking = false
	if _talk:
		_talk.visible = false
		_talk.text = ""
