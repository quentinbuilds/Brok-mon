extends GameStateBase
## Jungle/beach overworld: Person 2 map, Person 6 stepper + walker (PRD §6).
##
## What this state offers the rest of the game:
##   EventBus.player_moved(tile, in_encounter_zone)  once per completed tile step
##   is_in_encounter_zone()                          poll the player's current tile
##   GrassMap.is_encounter_zone(tile)                static, needs no node reference
##
## It owns no encounter rolls, no battle logic and no menu UI. The only transition it makes
## is opening the MENU; everything else reaches core through EventBus.

const GrassMap := preload("res://world/GrassMap.gd")
const PlayerScript := preload("res://world/Player.gd")
const BiomeSession := preload("res://world/BiomeSession.gd")
const PlayableMap := preload("res://world/PlayableMap.gd")

const FADE_SECONDS := 0.15

@onready var _tiles: TileMapLayer = $Tiles
@onready var _player: PlayerScript = $Player
@onready var _camera: Camera2D = $Camera
@onready var _walker: Node = get_node_or_null("Player/Walker")

var _playable: Node2D
var _fade: ColorRect
var _transitioning: bool = false


func _on_enter() -> void:
	BiomeSession.bind()
	if BiomeSession.is_grassland():
		_show_grassland()
	else:
		_show_expedition()
	_ensure_fade()
	_setup_camera()
	# GameData.reset() zeroes the stored tile, so fall back to the start whenever
	# the stored one is not somewhere we can stand.
	var tile := GameData.player_tile
	if not GrassMap.is_walkable(tile):
		tile = GrassMap.start_tile()
	GameData.player_tile = tile
	_player.place(tile)
	# Person 6 owns the walkable character sprite. Hide the Person 2 sheet so we do not
	# draw a second walker on top of theirs.
	_player.texture = null
	_sync_walker()
	_follow_camera()


func _show_grassland() -> void:
	_tiles.visible = true
	if _playable != null:
		_playable.visible = false
	if _tiles.get_used_cells().is_empty():
		_paint_map()


func _show_expedition() -> void:
	_tiles.visible = false
	if _playable == null:
		_playable = PlayableMap.new()
		_playable.name = "PlayableMap"
		add_child(_playable)
		move_child(_playable, 0)
	_playable.visible = true
	_playable.setup(BiomeSession.map_id())


func _paint_map() -> void:
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var t := Vector2i(x, y)
			_tiles.set_cell(t, 0, GrassMap.atlas_coords(t))


func exit() -> void:
	BiomeSession.unbind()


func _exit_tree() -> void:
	BiomeSession.unbind()


func update(delta: float) -> void:
	if _transitioning:
		_sync_walker()
		_follow_camera()
		return
	if InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.MENU)
		return
	if _player.advance(delta):
		_on_step_finished()
	# Starting the next step in the same frame a step lands keeps a held direction smooth.
	# Movement stays on Player.gd (try_step / advance). Do not add a second walk loop.
	if not _player.is_stepping() and not _transitioning:
		_player.try_step(InputManager.direction())
	_sync_walker()
	_follow_camera()


func _sync_walker() -> void:
	if _walker == null or not _walker.has_method("apply_move_dir"):
		return
	var dir := Vector2i.ZERO
	if _player.is_stepping():
		dir = _player.facing
	_walker.apply_move_dir(dir)

## True while the player stands in tall grass. Person 3 may poll this, but the
## in_encounter_zone flag on player_moved is the interface to prefer.
func is_in_encounter_zone() -> bool:
	return GrassMap.is_encounter_zone(GameData.player_tile)


func _on_step_finished() -> void:
	GameData.player_tile = _player.tile
	EventBus.player_moved.emit(_player.tile, GrassMap.is_encounter_zone(_player.tile))
	if BiomeSession.is_active():
		var record := BiomeSession.transition_at(_player.tile)
		if not record.is_empty():
			_begin_transition(record)


func _begin_transition(record: Dictionary) -> void:
	_transitioning = true
	var dest_id: StringName = record.destination_map_id
	var dest_region: StringName = record.destination_region
	var facing: Vector2 = record.get("destination_facing", Vector2.DOWN)
	await _fade_to(1.0)
	BiomeSession.load_map(dest_id)
	if _playable != null:
		_playable.setup(dest_id)
	var dest_tile := BiomeSession.region_tile(dest_region)
	if dest_tile == Vector2i.ZERO or not BiomeSession.is_walkable(dest_tile):
		dest_tile = BiomeSession.start_tile()
	_player.facing = Vector2i(signi(int(facing.x)), signi(int(facing.y)))
	if _player.facing == Vector2i.ZERO:
		_player.facing = Vector2i.DOWN
	_player.place(dest_tile)
	GameData.player_tile = dest_tile
	_setup_camera()
	_follow_camera()
	await _fade_to(0.0)
	_transitioning = false


func _ensure_fade() -> void:
	if _fade != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 80
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(200, 120)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	if _fade == null:
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished


func _setup_camera() -> void:
	# Limits stop the camera showing anything outside the map on a 200x120 viewport.
	var size := GrassMap.pixel_size()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = size.x
	_camera.limit_bottom = size.y


func _follow_camera() -> void:
	_camera.position = (_player.position + Vector2.ONE * GrassMap.TILE * 0.5).round()
