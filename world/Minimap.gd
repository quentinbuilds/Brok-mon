extends CanvasLayer
class_name Minimap
## Corner minimap: one pixel per tile, windowed on the player.
##
## Terrain is read straight from the map data rather than rendered from the TileMapLayer, so
## this costs one small Image instead of a second viewport pass, and it works headlessly in
## tests. The window follows the player, so the widget stays the same size however big the
## world gets.
##
## Lives on its own CanvasLayer because the overworld it belongs to is a Node2D that gets
## hidden, and a CanvasLayer does not inherit visibility from a Node2D parent. Visibility is
## therefore driven off GameState instead: the map belongs to the overworld and to nothing
## else, so it goes away for battles, the menu, catching and the title.

const GrassMap := preload("res://world/GrassMap.gd")
const MapCycle := preload("res://world/MapCycle.gd")

## Tiles shown across and down. Chosen so the widget stays legible at 200x120.
const VIEW := Vector2i(44, 32)

## Gap from the bottom-right corner of the screen, in pixels.
const MARGIN := 3

const SCREEN := Vector2i(200, 120)

## Under TalkHud (20) so an open dialogue covers the map rather than fighting it.
const LAYER := 15

const BLINK_SECONDS := 0.4

const EDGE := Color("101c33")
const FRAME := Color("e8c883")
const OFF_MAP := Color("0d1526")
const PLAYER_DOT := Color("fff4d0")
const NPC_DOT := Color("c4413f")

## Glyph -> minimap colour, keyed the same way GrassMap paints its tileset.
const TERRAIN := {
	".": Color("76ad50"),
	":": Color("4e7d35"),
	"=": Color("e8c883"),
	"T": Color("2f5d34"),
	"o": Color("8a8f98"),
	"~": Color("2d4d73"),
	",": Color("d98fb0"),
	"#": Color("1b2a1c"),
}

## Interior floors have no glyphs; walkability is the only thing to colour by.
const INTERIOR_FLOOR := Color("a9793f")
const INTERIOR_WALL := Color("3a2a1c")

var map_mode: int = MapCycle.Mode.DEFAULT
var player_tile: Vector2i = Vector2i.ZERO

var _npc_tiles: Dictionary = {}
var _view: TextureRect
var _image: Image
var _texture: ImageTexture
var _blink := 0.0
var _blink_on := true


## Starts visible and lets state_changed take it away. The overworld scene is only ever built
## on the way into OVERWORLD, so "visible until told otherwise" is right whichever order the
## node and the transition happen in.
func _ready() -> void:
	layer = LAYER
	_build_view()
	if not GameState.state_changed.is_connected(_on_state_changed):
		GameState.state_changed.connect(_on_state_changed)
	refresh()


func _process(delta: float) -> void:
	_blink += delta
	if _blink < BLINK_SECONDS:
		return
	_blink = 0.0
	_blink_on = not _blink_on
	refresh()


## Only the overworld gets a minimap. Battles, the menu and the title screen do not, and the
## overworld being a hidden Node2D is not enough to take this layer off screen by itself.
func _on_state_changed(_from: int, to: int) -> void:
	visible = to == GameState.State.OVERWORLD


## Called by OverworldState whenever the map or the cast changes underfoot.
func set_source(mode: int, npc_tiles: Dictionary) -> void:
	map_mode = mode
	_npc_tiles = npc_tiles.duplicate()
	refresh()


func track(tile: Vector2i) -> void:
	player_tile = tile
	refresh()


## Repaints the window. Cheap: VIEW is about 1400 pixels.
## Top-left tile of the window. A map smaller than the window is centred in it; a bigger one
## scrolls with the player but stops at its edges, so the widget never fills up with void the
## way a window centred blindly on the player does in a corner.
func window_origin() -> Vector2i:
	var map := MapCycle.map_tiles(map_mode)
	var origin := player_tile - VIEW / 2
	for axis in 2:
		if map[axis] <= VIEW[axis]:
			origin[axis] = -(VIEW[axis] - map[axis]) / 2
		else:
			origin[axis] = clampi(origin[axis], 0, map[axis] - VIEW[axis])
	return origin


func refresh() -> void:
	if _image == null:
		return
	var origin := window_origin()
	for y in VIEW.y:
		for x in VIEW.x:
			_image.set_pixel(x + 1, y + 1, _color_at(origin + Vector2i(x, y)))
	for npc_tile in _npc_tiles:
		_plot(npc_tile - origin, NPC_DOT)
	if _blink_on:
		_plot(player_tile - origin, PLAYER_DOT)
	_texture.update(_image)


func _plot(at: Vector2i, color: Color) -> void:
	if at.x < 0 or at.y < 0 or at.x >= VIEW.x or at.y >= VIEW.y:
		return
	_image.set_pixel(at.x + 1, at.y + 1, color)


func _color_at(tile: Vector2i) -> Color:
	match map_mode:
		MapCycle.Mode.DEFAULT:
			if tile.x < 0 or tile.y < 0 or tile.x >= GrassMap.WIDTH or tile.y >= GrassMap.HEIGHT:
				return OFF_MAP
			return TERRAIN.get(GrassMap.glyph(tile), OFF_MAP)
		MapCycle.Mode.BEACH:
			if tile.x < 0 or tile.y < 0 \
					or tile.x >= MapCycle.BEACH_WIDTH or tile.y >= MapCycle.BEACH_HEIGHT:
				return OFF_MAP
			return TERRAIN["="] if MapCycle.beach_glyph(tile) == "." else TERRAIN["~"]
		MapCycle.Mode.INTERIOR:
			if not MapCycle.is_walkable(MapCycle.Mode.INTERIOR, tile):
				return INTERIOR_WALL
			return INTERIOR_FLOOR
	return OFF_MAP


func _build_view() -> void:
	var size := VIEW + Vector2i.ONE * 2
	_image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	_image.fill(EDGE)
	# One-pixel frame so the map reads as a widget rather than a smear of pixels on the world.
	for x in size.x:
		_image.set_pixel(x, 0, FRAME)
		_image.set_pixel(x, size.y - 1, FRAME)
	for y in size.y:
		_image.set_pixel(0, y, FRAME)
		_image.set_pixel(size.x - 1, y, FRAME)
	_texture = ImageTexture.create_from_image(_image)

	_view = TextureRect.new()
	_view.name = "View"
	_view.texture = _texture
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.position = Vector2(SCREEN - size - Vector2i.ONE * MARGIN)
	_view.size = Vector2(size)
	add_child(_view)
