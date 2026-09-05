extends GameStateBase
## Grassland overworld: map, player, camera and encounter-zone reporting (PRD §6).
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

@onready var _tiles: TileMapLayer = $Tiles
@onready var _player: PlayerScript = $Player
@onready var _camera: Camera2D = $Camera

func _on_enter() -> void:
	if _tiles.get_used_cells().is_empty():
		_paint_map()
	_setup_camera()
	# GameData.reset() zeroes the stored tile, and tile 0,0 is border hedge, so fall back to
	# the start tile whenever the stored one is not somewhere we can stand.
	var tile := GameData.player_tile
	if not GrassMap.is_walkable(tile):
		tile = GrassMap.START_TILE
	GameData.player_tile = tile
	_player.place(tile)
	_follow_camera()

func update(delta: float) -> void:
	if InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.MENU)
		return
	if _player.advance(delta):
		_on_step_finished()
	# Starting the next step in the same frame a step lands keeps a held direction smooth.
	if not _player.is_stepping():
		_player.try_step(InputManager.direction())
	_follow_camera()

## True while the player stands in tall grass. Person 3 may poll this, but the
## in_encounter_zone flag on player_moved is the interface to prefer.
func is_in_encounter_zone() -> bool:
	return GrassMap.is_encounter_zone(GameData.player_tile)

func _on_step_finished() -> void:
	GameData.player_tile = _player.tile
	EventBus.player_moved.emit(_player.tile, GrassMap.is_encounter_zone(_player.tile))

func _paint_map() -> void:
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var t := Vector2i(x, y)
			_tiles.set_cell(t, 0, GrassMap.atlas_coords(t))

func _setup_camera() -> void:
	# Limits stop the camera showing anything outside the map on a 200x120 viewport.
	var size := GrassMap.pixel_size()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = size.x
	_camera.limit_bottom = size.y

func _follow_camera() -> void:
	_camera.position = (_player.position + Vector2.ONE * GrassMap.TILE * 0.5).round()
