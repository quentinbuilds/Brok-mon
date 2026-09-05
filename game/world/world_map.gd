extends Node2D
## Active map façade. Visual IDs never determine collision or encounters.

const Registry = preload("res://world/map_registry.gd")
const PLAYER_BODY := Vector2(8, 8)

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
var _map_id: StringName = &""
var _data: Dictionary = {}
var _transitions: Array = []
var _ground_regions: Dictionary = {}
var _ground_from_props: Dictionary = {}
var _ground_atlas_overrides: Dictionary = {}
var _encounter_label := "TALL GRASS"
var _nav_tile := 8
var _visual_tile := 16
var _cols := 50
var _rows := 30


class AtlasLayer extends Node2D:
	enum Kind { GROUND, ENCOUNTERS, PROPS_BACK, PROPS_FRONT }

	var kind: Kind
	var host: Node2D

	func setup(layer_kind: Kind, owner_map: Node2D) -> void:
		kind = layer_kind
		host = owner_map
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		queue_redraw()

	func _draw() -> void:
		if host == null:
			return
		match kind:
			Kind.GROUND:
				host.draw_ground(self)
			Kind.ENCOUNTERS:
				host.draw_encounters(self)
			Kind.PROPS_BACK:
				host.draw_props(self, host._data.get("props_back", []))
			Kind.PROPS_FRONT:
				host.draw_props(self, host._data.get("props_front", []))


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _map_id == &"":
		setup(Game.player.map_id)


func setup(map_id: StringName) -> void:
	_clear_layers()
	var requested := map_id
	_data = Registry.definition(requested)
	if _data.is_empty():
		push_error("Unknown map_id '%s'; falling back to jungle" % requested)
		requested = &"jungle"
		_data = Registry.definition(requested)
	if _data.is_empty():
		push_error("Jungle map definition is missing")
		return
	_map_id = _data.id
	_nav_tile = int(_data.get("navigation_tile_size", 8))
	_visual_tile = int(_data.get("visual_tile_size", 16))
	_cols = int(_data.get("width", 50))
	_rows = int(_data.get("height", 30))
	tiles = _data.ground
	blocked = _data.blocked
	encounter_tiles = _data.encounters
	regions = _data.regions
	door_tiles = _data.doors
	_transitions = _data.get("transitions", [])
	var assets: Dictionary = _data.get("assets", {})
	_ground_regions = assets.get("ground_regions", {})
	_encounter_label = str(assets.get("encounter_label", "TALL GRASS"))
	tile_atlas = _load_atlas(str(assets.get("tile_atlas", "")))
	prop_atlas = _load_atlas(str(assets.get("prop_atlas", "")))
	_ground_from_props.clear()
	for ground_id in assets.get("prop_ground_ids", []):
		_ground_from_props[int(ground_id)] = true
	_ground_atlas_overrides = {}
	var overrides: Dictionary = assets.get("ground_atlases", {})
	for ground_id in overrides.keys():
		_ground_atlas_overrides[int(ground_id)] = _load_atlas(str(overrides[ground_id]))
	var spawn_name: StringName = _data.get("spawn_region", &"player_start")
	if regions.has(spawn_name):
		spawn_tile = regions[spawn_name]
	elif regions.has("player_start"):
		spawn_tile = regions.player_start
	if not is_inside_tree():
		return
	_build_layers()


func _load_atlas(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("Missing required runtime atlas: %s" % path)
		return null
	return load(path) as Texture2D


func _clear_layers() -> void:
	for layer in [ground_layer, encounter_layer, props_back, props_front]:
		if layer != null and is_instance_valid(layer):
			layer.queue_free()
	ground_layer = null
	encounter_layer = null
	props_back = null
	props_front = null


func _build_layers() -> void:
	ground_layer = _make_layer("GroundLayer", AtlasLayer.Kind.GROUND, -20)
	encounter_layer = _make_layer("EncounterLayer", AtlasLayer.Kind.ENCOUNTERS, -15)
	props_back = _make_layer("PropsBack", AtlasLayer.Kind.PROPS_BACK, -5)
	props_front = _make_layer("PropsFront", AtlasLayer.Kind.PROPS_FRONT, 20)


func _make_layer(layer_name: String, kind: AtlasLayer.Kind, layer_z: int) -> AtlasLayer:
	var layer := AtlasLayer.new()
	layer.name = layer_name
	layer.z_index = layer_z
	layer.setup(kind, self)
	add_child(layer)
	return layer


func draw_ground(layer: AtlasLayer) -> void:
	if tile_atlas == null and prop_atlas == null:
		return
	var visual_cols := _cols * _nav_tile / _visual_tile
	var visual_rows := _rows * _nav_tile / _visual_tile
	for vy in visual_rows:
		for vx in visual_cols:
			var nav := Vector2i(vx * 2, vy * 2)
			if nav.y >= tiles.size() or nav.x >= (tiles[nav.y] as Array).size():
				continue
			var ground_id: int = tiles[nav.y][nav.x]
			if not _ground_regions.has(ground_id):
				continue
			var texture := _texture_for_ground(ground_id)
			if texture == null:
				continue
			var destination := Rect2(Vector2(vx * _visual_tile, vy * _visual_tile), Vector2(_visual_tile, _visual_tile))
			layer.draw_texture_rect_region(texture, destination, _ground_regions[ground_id])


func _texture_for_ground(ground_id: int) -> Texture2D:
	if _ground_atlas_overrides.has(ground_id):
		return _ground_atlas_overrides[ground_id]
	if _ground_from_props.has(ground_id):
		return prop_atlas
	return tile_atlas


func draw_encounters(layer: AtlasLayer) -> void:
	if tile_atlas == null and prop_atlas == null:
		return
	var visual_cols := _cols * _nav_tile / _visual_tile
	var visual_rows := _rows * _nav_tile / _visual_tile
	for vy in visual_rows:
		for vx in visual_cols:
			var nav := Vector2i(vx * 2, vy * 2)
			if not encounter_tiles.has(nav):
				continue
			var ground_id: int = tiles[nav.y][nav.x]
			if not _ground_regions.has(ground_id):
				continue
			var texture := _texture_for_ground(ground_id)
			if texture == null:
				continue
			var destination := Rect2(Vector2(vx * _visual_tile, vy * _visual_tile), Vector2(_visual_tile, _visual_tile))
			layer.draw_texture_rect_region(texture, destination, _ground_regions[ground_id])


func draw_props(layer: AtlasLayer, records: Array) -> void:
	for record in records:
		var texture := prop_atlas
		if record.has("atlas"):
			texture = _load_atlas(str(record.atlas))
		if texture == null:
			continue
		var cell: Vector2i = record.cell
		var destination := Rect2(
			Vector2(cell * _nav_tile) + record.offset,
			record.size)
		layer.draw_texture_rect_region(texture, destination, record.source)


func map_id() -> StringName:
	return _map_id


func encounter_label() -> String:
	return _encounter_label


func transition_at(tile: Vector2i) -> Dictionary:
	for record in _transitions:
		var rect: Rect2i = record.source_rect
		if rect.has_point(tile):
			return record
	return {}


func map_size_px() -> Vector2:
	return Vector2(_cols * _nav_tile, _rows * _nav_tile)


func spawn_position() -> Vector2:
	return tile_center(spawn_tile) - PLAYER_BODY * 0.5


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / _nav_tile), floori(world_pos.y / _nav_tile))


func tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * _nav_tile) + Vector2(_nav_tile, _nav_tile) * 0.5


func in_bounds_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < _cols and tile.y < _rows


func tile_at(tile: Vector2i) -> int:
	if not in_bounds_tile(tile):
		return 0
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
