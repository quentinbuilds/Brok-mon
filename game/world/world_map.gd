extends Node2D
## Expedition Trail map. Visual IDs never determine collision or encounters.

const MapData = preload("res://world/jungle_map_data.gd")
const TILE := MapData.TILE
const COLS := MapData.WIDTH
const ROWS := MapData.HEIGHT
const PLAYER_BODY := Vector2(24, 24)

var ground_layer: Node2D
var encounter_layer: Node2D
var props_back: Node2D
var props_front: Node2D
var blocked: Dictionary = {}
var encounter_tiles: Dictionary = {}
var regions: Dictionary = {}
var door_tiles: Dictionary = {}
var tiles: Array = []
var props: Array = []
var spawn_tile := Vector2i(5, 25)
var tile_atlas: Texture2D
var prop_atlas: Texture2D


class AtlasLayer extends Node2D:
	enum Kind { GROUND, ENCOUNTERS, PROPS_BACK, PROPS_FRONT }

	var kind: Kind
	var ground: Array
	var props: Array
	var tile_texture: Texture2D
	var prop_texture: Texture2D

	func setup(
			layer_kind: Kind,
			ground_data: Array,
			prop_data: Array,
			ground_atlas: Texture2D,
			props_atlas: Texture2D) -> void:
		kind = layer_kind
		ground = ground_data
		props = prop_data
		tile_texture = ground_atlas
		prop_texture = props_atlas
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		queue_redraw()

	func _draw() -> void:
		for y in MapData.HEIGHT:
			for x in MapData.WIDTH:
				var tile := Vector2i(x, y)
				match kind:
					Kind.GROUND:
						_draw_ground(tile, ground[y][x])
					Kind.ENCOUNTERS:
						if ground[y][x] == MapData.Ground.TALL_GRASS:
							_draw_atlas(tile_texture, tile, Rect2(16, 16, 8, 8))
					Kind.PROPS_BACK:
						_draw_prop_back(tile, props[y][x])
					Kind.PROPS_FRONT:
						_draw_prop_front(tile, props[y][x])

	func _draw_ground(tile: Vector2i, ground_id: int) -> void:
		var alternate := (tile.x + tile.y) % 2
		var source := Rect2(0, 0, 8, 8)
		match ground_id:
			MapData.Ground.LAWN:
				source = Rect2(alternate * 8, 0, 8, 8)
			MapData.Ground.PATH:
				source = Rect2(16 + alternate * 8, 0, 8, 8)
			MapData.Ground.TALL_GRASS:
				source = Rect2(32 + alternate * 8, 0, 8, 8)
			MapData.Ground.WATER:
				source = Rect2(48 + alternate * 8, 0, 8, 8)
		_draw_atlas(tile_texture, tile, source)

	func _draw_prop_back(tile: Vector2i, prop_id: int) -> void:
		var source := Rect2()
		match prop_id:
			MapData.Prop.TREE:
				_draw_atlas(
					tile_texture, tile,
					Rect2(((tile.x + tile.y) % 2) * 8, 8, 8, 8))
				return
			MapData.Prop.FERN:
				source = Rect2(0, 0, 16, 16)
			MapData.Prop.CYCAD:
				source = Rect2(16, 0, 16, 16)
			MapData.Prop.PALM:
				source = Rect2(16, 0, 16, 24)
			MapData.Prop.ROCK:
				source = Rect2(58, 10, 14, 16)
			MapData.Prop.BONE:
				source = Rect2(72, 12, 16, 12)
			MapData.Prop.FOOTPRINT:
				source = Rect2(90, 10, 10, 14)
			MapData.Prop.EGGSHELL:
				source = Rect2(102, 8, 14, 16)
			MapData.Prop.HUT_WALL:
				if tile in [Vector2i(14, 17), Vector2i(22, 17)]:
					var destination := Rect2(
						Vector2(tile * MapData.TILE) - Vector2(0, 8), Vector2(32, 32))
					draw_texture_rect_region(
						prop_texture, destination, Rect2(0, 32, 32, 32))
				return
			MapData.Prop.HUT_DOOR:
				return
			MapData.Prop.FOSSIL_SHRINE:
				var destination := Rect2(
					Vector2(tile * MapData.TILE) - Vector2(8, 16), Vector2(24, 24))
				draw_texture_rect_region(
					prop_texture, destination, Rect2(56, 32, 32, 32))
				return
			MapData.Prop.EXIT_MARKER:
				source = Rect2(88, 40, 16, 16)
			_:
				return
		var destination := Rect2(Vector2(tile * MapData.TILE), Vector2(8, 8))
		draw_texture_rect_region(prop_texture, destination, source)

	func _draw_prop_front(tile: Vector2i, prop_id: int) -> void:
		if prop_id == MapData.Prop.TREE and (tile.x + tile.y * 3) % 4 == 0:
			var destination := Rect2(
				Vector2(tile * MapData.TILE) + Vector2(-4, -8), Vector2(16, 16))
			draw_texture_rect_region(
				prop_texture, destination, Rect2(32, 0, 32, 24))
		elif prop_id == MapData.Prop.PALM:
			var destination := Rect2(
				Vector2(tile * MapData.TILE) + Vector2(0, -8), Vector2(8, 16))
			draw_texture_rect_region(
				prop_texture, destination, Rect2(16, 0, 16, 24))

	func _draw_atlas(texture: Texture2D, tile: Vector2i, source: Rect2) -> void:
		var destination := Rect2(Vector2(tile * MapData.TILE), Vector2(8, 8))
		draw_texture_rect_region(texture, destination, source)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile_atlas = _texture_from_png("res://assets/tiles/jungle_tiles.png")
	prop_atlas = _texture_from_png("res://assets/sprites/jungle_props.png")
	var data := MapData.build()
	tiles = data.ground
	props = data.props
	blocked = data.blocked
	encounter_tiles = data.encounters
	regions = data.regions
	door_tiles = data.doors
	spawn_tile = regions.player_start

	ground_layer = _make_layer(
		"GroundLayer", AtlasLayer.Kind.GROUND, -20, tiles, props)
	encounter_layer = _make_layer(
		"EncounterLayer", AtlasLayer.Kind.ENCOUNTERS, -15, tiles, props)
	props_back = _make_layer(
		"PropsBack", AtlasLayer.Kind.PROPS_BACK, -5, tiles, props)
	props_front = _make_layer(
		"PropsFront", AtlasLayer.Kind.PROPS_FRONT, 20, tiles, props)


func _make_layer(
		layer_name: String,
		kind: AtlasLayer.Kind,
		layer_z: int,
		ground_data: Array,
		prop_data: Array) -> AtlasLayer:
	var layer := AtlasLayer.new()
	layer.name = layer_name
	layer.z_index = layer_z
	layer.setup(kind, ground_data, prop_data, tile_atlas, prop_atlas)
	add_child(layer)
	return layer


func _texture_from_png(resource_path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		push_error("Could not load atlas: " + resource_path)
		return null
	return ImageTexture.create_from_image(image)


func map_size_px() -> Vector2:
	return Vector2(COLS * TILE, ROWS * TILE)


func spawn_position() -> Vector2:
	return tile_center(spawn_tile) - PLAYER_BODY * 0.5


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / TILE), floori(world_pos.y / TILE))


func tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * TILE) + Vector2(TILE, TILE) * 0.5


func in_bounds_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < COLS and tile.y < ROWS


func tile_at(tile: Vector2i) -> int:
	if not in_bounds_tile(tile):
		return MapData.Ground.WATER
	return tiles[tile.y][tile.x]


func is_blocked_tile(tile: Vector2i) -> bool:
	return not in_bounds_tile(tile) or blocked.has(tile)


func is_blocked(world_pos: Vector2) -> bool:
	return is_blocked_tile(world_to_tile(world_pos))


func is_encounter_zone_tile(tile: Vector2i) -> bool:
	return encounter_tiles.has(tile)


func is_encounter_zone(world_pos: Vector2) -> bool:
	return is_encounter_zone_tile(world_to_tile(world_pos))


func can_stand(world_pos: Vector2, body: Vector2 = PLAYER_BODY) -> bool:
	var points: Array[Vector2] = [
		world_pos + Vector2(3, 3),
		world_pos + Vector2(body.x - 3, 3),
		world_pos + Vector2(3, body.y - 3),
		world_pos + Vector2(body.x - 3, body.y - 3),
		world_pos + body * 0.5,
	]
	for point in points:
		if is_blocked(point):
			return false
	return true


func region_position(name: String) -> Vector2:
	if not regions.has(name):
		return Vector2.ZERO
	return tile_center(regions[name])


func is_house_door(tile: Vector2i) -> bool:
	return door_tiles.has(tile)
