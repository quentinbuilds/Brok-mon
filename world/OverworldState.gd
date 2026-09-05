extends GameStateBase
class_name OverworldState
## Grassland overworld: map, player, camera and encounter-zone reporting (PRD §6).
## A talks to a nearby node in group "npc" (NpcTalk lines). Menu still opens MENU.

const GrassMap := preload("res://world/GrassMap.gd")
const PlayerScript := preload("res://world/Player.gd")
const MapCycle := preload("res://world/MapCycle.gd")
const NPC_GROUP := "npc"

@onready var _tiles: TileMapLayer = $Tiles
@onready var _player: PlayerScript = $Player
@onready var _camera: Camera2D = $Camera
@onready var _walker: Node = get_node_or_null("Player/Walker")
@onready var _talk: Label = get_node_or_null("TalkHud/TalkBox")
@onready var _talk_panel: TextureRect = get_node_or_null("TalkHud/Panel")
@onready var _portrait: TextureRect = get_node_or_null("TalkHud/Portrait")
@onready var _prompt: Node2D = get_node_or_null("InteractPrompt")
@onready var _minimap: Minimap = get_node_or_null("Minimap")
@onready var _beach: Sprite2D = $BeachBackground
@onready var _interior: Sprite2D = $InteriorBackground
@onready var _house: Sprite2D = $House
@onready var _beach_house: Sprite2D = $BeachHouse

var talking: bool = false
var map_mode: MapCycle.Mode = MapCycle.Mode.DEFAULT
var next_exterior: MapCycle.Mode = MapCycle.Mode.BEACH
var _map_transition_locked: bool = false

## Tiles standing NPCs occupy, refreshed whenever the presentation changes. The overworld has
## no physics bodies -- collision is a glyph lookup -- so an NPC is made solid by removing its
## tile from the walk query rather than by giving it a collider.
var _npc_tiles: Dictionary = {}

## How many times the player has talked to each NPC, so repeat visits rotate through that
## NPC's variations instead of replaying the opener.
var _talk_counts: Dictionary = {}

## Where the "A TALK" badge sits relative to an NPC's top-left corner: centred on a 16 px
## sprite and lifted clear of its head.
const PROMPT_OFFSET := Vector2(-7, -13)


func _on_enter() -> void:
	if _tiles.get_used_cells().is_empty():
		_paint_map()
	_apply_map_presentation()
	_player.set_walkable_query(_is_active_tile_walkable)
	# GameData.reset() zeroes the stored tile, and tile 0,0 is border hedge, so fall back to
	# the start tile whenever the stored one is not somewhere we can stand.
	var tile := GameData.player_tile
	if not _is_active_tile_walkable(tile):
		tile = _spawn_for_mode(map_mode)
	GameData.player_tile = tile
	_player.place(tile)
	# Person 6 owns the walkable character sprite. Hide the Person 2 sheet so we do not
	# draw a second walker on top of theirs.
	_player.texture = null
	_sync_walker()
	_follow_camera()
	if _minimap:
		_minimap.track(tile)
	_close_talk()


func update(delta: float) -> void:
	# Cheap enough to re-evaluate every frame, and doing it here means the badge is correct
	# after a step, a map switch, or a closed dialogue without wiring it into each of those.
	_refresh_prompt()
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
	if _map_transition_locked:
		if InputManager.direction() == Vector2i.ZERO:
			_map_transition_locked = false
		else:
			_sync_walker()
			_follow_camera()
			return
	if _player.advance(delta):
		_on_step_finished()
		if _map_transition_locked:
			_sync_walker()
			_follow_camera()
			return
	# Starting the next step in the same frame a step lands keeps a held direction smooth.
	# Movement stays on Player.gd (try_step / advance). Do not add a second walk loop.
	if not _player.is_stepping():
		_player.try_step(InputManager.direction())
	_sync_walker()
	_follow_camera()


func try_talk() -> bool:
	if not is_inside_tree() or _player == null:
		return false
	var npc := NpcTalk.nearest(_player.position, get_tree().get_nodes_in_group(NPC_GROUP))
	if npc == null:
		return false
	var id := NpcTalk.id_of(npc)
	var seen := int(_talk_counts.get(id, 0))
	_talk_counts[id] = seen + 1
	_open_talk(NpcTalk.line_at(id, seen), NpcTalk.portrait_path(id))
	return true


## The NPC the player is close enough to talk to, or null. Wider than the talk radius so the
## badge appears a step before A does anything.
func prompt_target() -> Node:
	if not is_inside_tree() or _player == null or talking:
		return null
	return NpcTalk.nearest_in_prompt_range(_player.position, get_tree().get_nodes_in_group(NPC_GROUP))


## Floats the "A TALK" badge over whoever is in range, and hides it otherwise.
func _refresh_prompt() -> void:
	if _prompt == null:
		return
	var npc := prompt_target()
	_prompt.visible = npc != null
	if npc != null:
		_prompt.position = (NpcTalk.position_of(npc) + PROMPT_OFFSET).round()


func _open_talk(text: String, portrait_path: String = "") -> void:
	talking = true
	if _talk:
		_talk.text = text
		_talk.visible = true
	if _talk_panel:
		_talk_panel.visible = true
	if _portrait:
		var art: Texture2D = load(portrait_path) if ResourceLoader.exists(portrait_path) else null
		_portrait.texture = art
		_portrait.visible = art != null
	_refresh_prompt()


func _close_talk() -> void:
	talking = false
	if _talk:
		_talk.visible = false
		_talk.text = ""
	if _talk_panel:
		_talk_panel.visible = false
	if _portrait:
		_portrait.visible = false
		_portrait.texture = null
	_refresh_prompt()


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
	return MapCycle.is_encounter_zone(map_mode, GameData.player_tile)


func _on_step_finished() -> void:
	GameData.player_tile = _player.tile
	if _minimap:
		_minimap.track(_player.tile)
	if _try_map_transition(_player.tile):
		return
	EventBus.player_moved.emit(_player.tile, is_in_encounter_zone())


func _try_map_transition(tile: Vector2i) -> bool:
	if map_mode == MapCycle.Mode.INTERIOR and tile == MapCycle.INTERIOR_EXIT:
		var destination := next_exterior
		next_exterior = MapCycle.Mode.DEFAULT if destination == MapCycle.Mode.BEACH else MapCycle.Mode.BEACH
		_switch_map(destination, _spawn_for_mode(destination))
		return true
	if map_mode == MapCycle.Mode.DEFAULT and tile == MapCycle.DEFAULT_DOOR:
		_switch_map(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_SPAWN)
		return true
	if map_mode == MapCycle.Mode.BEACH and tile == MapCycle.BEACH_DOOR:
		_switch_map(MapCycle.Mode.INTERIOR, MapCycle.INTERIOR_SPAWN)
		return true
	return false


func _switch_map(mode: MapCycle.Mode, spawn: Vector2i) -> void:
	map_mode = mode
	_map_transition_locked = true
	_apply_map_presentation()
	_player.place(spawn)
	GameData.player_tile = spawn
	_sync_walker()
	_follow_camera()
	_refresh_prompt()
	if _minimap:
		_minimap.track(spawn)


func _spawn_for_mode(mode: MapCycle.Mode) -> Vector2i:
	match mode:
		MapCycle.Mode.INTERIOR:
			return MapCycle.INTERIOR_SPAWN
		MapCycle.Mode.BEACH:
			return MapCycle.BEACH_RETURN
	return MapCycle.DEFAULT_RETURN if map_mode != MapCycle.Mode.DEFAULT else GrassMap.START_TILE


func _is_active_tile_walkable(tile: Vector2i) -> bool:
	if _npc_tiles.has(tile):
		return false
	return MapCycle.is_walkable(map_mode, tile)


## The tile an NPC stands on, from its top-left position. NPC art is one tile wide, so this is
## the whole of its footprint.
static func tile_of(node: Node2D) -> Vector2i:
	return Vector2i((node.position / float(GrassMap.TILE)).floor())


## Only NPCs currently on screen block movement; the map cycle hides them away from the
## default map, and a hidden NPC has no business stopping the player on a different island.
func _refresh_npc_tiles() -> void:
	_npc_tiles.clear()
	for npc in get_tree().get_nodes_in_group(NPC_GROUP):
		if npc is Node2D and (npc as CanvasItem).visible:
			_npc_tiles[tile_of(npc as Node2D)] = true


func _apply_map_presentation() -> void:
	var on_default := map_mode == MapCycle.Mode.DEFAULT
	_tiles.visible = on_default
	_house.visible = on_default
	_beach.visible = map_mode == MapCycle.Mode.BEACH
	_beach_house.visible = map_mode == MapCycle.Mode.BEACH
	_interior.visible = map_mode == MapCycle.Mode.INTERIOR
	for npc in get_tree().get_nodes_in_group(NPC_GROUP):
		if npc is CanvasItem:
			npc.visible = on_default
	_refresh_npc_tiles()
	if _minimap:
		_minimap.set_source(map_mode, _npc_tiles)
	_setup_camera()


func _paint_map() -> void:
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var t := Vector2i(x, y)
			_tiles.set_cell(t, 0, GrassMap.atlas_coords(t))


func _setup_camera() -> void:
	# Limits stop the camera showing anything outside the map on a 200x120 viewport.
	var size := MapCycle.pixel_size(map_mode)
	_camera.limit_left = 0
	_camera.limit_top = MapCycle.camera_top(map_mode)
	_camera.limit_right = size.x
	_camera.limit_bottom = size.y


func _follow_camera() -> void:
	_camera.position = (_player.position + Vector2.ONE * GrassMap.TILE * 0.5).round()
