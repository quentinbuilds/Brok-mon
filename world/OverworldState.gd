extends GameStateBase
class_name OverworldState
## Overworld: ForestMap (16x16 art) on an 8px movement grid.
## Player is the Person 6 walker (OverworldCharacter). Grid-step like Player.gd;
## walkability is ForestMap water + NPC rects, not GrassMap glyphs.
## A talks to a nearby node in group "npc" (NpcTalk lines). Menu still opens MENU.

const TILE := 8
const SPRITE := 16
const NPC_GROUP := "npc"
## Same cadence as world/Player.gd (one 8px tile per step).
const STEP_TIME := 0.14

@onready var _player = $Player
@onready var _map: TileMapLayer = $ForestMap
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _talk: Label = get_node_or_null("TalkHud/TalkBox")
@onready var _talk_panel: ColorRect = get_node_or_null("TalkHud/Panel")

var talking: bool = false
var _stepping := false
var _step_from := Vector2.ZERO
var _step_to := Vector2.ZERO
var _step_elapsed := 0.0
var _step_dir := Vector2i.ZERO

func _ready() -> void:
	_apply_camera_limits()

func _on_enter() -> void:
	_apply_camera_limits()
	if GameData.player_tile == Vector2i.ZERO:
		GameData.player_tile = _fresh_spawn_tile()
	_player.position = Vector2(GameData.player_tile * TILE)
	_stepping = false
	if _player.has_method("apply_move_dir"):
		_player.apply_move_dir(Vector2i.ZERO)
	_close_talk()

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
	if _stepping:
		_advance_step(delta)
		_sync_walker()
		return
	var dir := InputManager.direction()
	if dir != Vector2i.ZERO:
		_try_grid_step(dir)
	_sync_walker()

func try_talk() -> bool:
	if not is_inside_tree() or _player == null:
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
	if _talk_panel:
		_talk_panel.visible = true


func _close_talk() -> void:
	talking = false
	if _talk:
		_talk.visible = false
		_talk.text = ""
	if _talk_panel:
		_talk_panel.visible = false


func _sync_walker() -> void:
	if _player == null or not _player.has_method("apply_move_dir"):
		return
	_player.apply_move_dir(_step_dir if _stepping else Vector2i.ZERO)

func _try_grid_step(dir: Vector2i) -> bool:
	if _stepping or dir == Vector2i.ZERO:
		return false
	_step_dir = dir
	var dest: Vector2 = _player.position + Vector2(dir) * TILE
	if not can_walk(dest):
		_sync_walker()
		return false
	_step_from = _player.position
	_step_to = dest
	_step_elapsed = 0.0
	_stepping = true
	return true

func _advance_step(delta: float) -> void:
	_step_elapsed += delta
	var t := clampf(_step_elapsed / STEP_TIME, 0.0, 1.0)
	_player.position = _step_from.lerp(_step_to, t).round()
	if t < 1.0:
		return
	_player.position = _step_to
	_stepping = false
	_step_dir = Vector2i.ZERO
	var tile := Vector2i((_player.position / TILE).floor())
	if tile != GameData.player_tile:
		GameData.player_tile = tile
		EventBus.player_moved.emit(tile, is_in_encounter_zone())

func can_walk(pos: Vector2) -> bool:
	return not is_blocked(_footprint(pos))

func is_blocked(rect: Rect2) -> bool:
	return _water_blocks(rect) or _npc_blocks(rect)

func walk_bounds() -> Rect2:
	if _map != null:
		return _map.pixel_rect()
	return Rect2(0, 0, 200, 120)

## True while the player stands on a grass-tuft encounter tile.
func is_in_encounter_zone() -> bool:
	if _map == null or _player == null:
		return false
	var center: Vector2 = _player.position + Vector2(SPRITE * 0.5, SPRITE * 0.5)
	return _map.is_encounter_cell(_map.local_to_map(center))

func try_move(next: Vector2) -> bool:
	var b := walk_bounds()
	next.x = clampf(next.x, b.position.x, b.end.x - SPRITE)
	next.y = clampf(next.y, b.position.y, b.end.y - SPRITE)
	if is_blocked(_footprint(next)):
		return false
	_player.position = next
	_stepping = false
	var tile := Vector2i((next / TILE).floor())
	if tile != GameData.player_tile:
		GameData.player_tile = tile
		EventBus.player_moved.emit(tile, is_in_encounter_zone())
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
