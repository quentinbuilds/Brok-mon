extends Node2D
## Draws Person 2 jungle/beach atlases. Collision stays on BiomeSession / GrassMap.

const BiomeSession := preload("res://world/BiomeSession.gd")

var ground_layer: Node2D
var encounter_layer: Node2D
var props_back: Node2D
var props_front: Node2D
var tiles: Array = []
var tile_atlas: Texture2D
var prop_atlas: Texture2D
var _map_id: StringName = &""
var _data: Dictionary = {}
var _ground_regions: Dictionary = {}
var _ground_from_props: Dictionary = {}
var _ground_atlas_overrides: Dictionary = {}
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


func setup(which: StringName) -> void:
	_clear_layers()
	_data = BiomeSession.load_map(which)
	if _data.is_empty():
		push_error("PlayableMap: missing map '%s'" % which)
		return
	_map_id = _data.id
	_nav_tile = int(_data.get("navigation_tile_size", 8))
	_visual_tile = int(_data.get("visual_tile_size", 16))
	_cols = int(_data.get("width", 50))
	_rows = int(_data.get("height", 30))
	tiles = _data.ground
	var assets: Dictionary = _data.get("assets", {})
	_ground_regions = assets.get("ground_regions", {})
	tile_atlas = _load_atlas(str(assets.get("tile_atlas", "")))
	prop_atlas = _load_atlas(str(assets.get("prop_atlas", "")))
	_ground_from_props.clear()
	for ground_id in assets.get("prop_ground_ids", []):
		_ground_from_props[int(ground_id)] = true
	_ground_atlas_overrides = {}
	var overrides: Dictionary = assets.get("ground_atlases", {})
	for ground_id in overrides.keys():
		_ground_atlas_overrides[int(ground_id)] = _load_atlas(str(overrides[ground_id]))
	if not is_inside_tree():
		return
	_build_layers()


func current_map_id() -> StringName:
	return _map_id


func _resolve_atlas_path(path: String) -> String:
	if path.is_empty():
		return ""
	if ResourceLoader.exists(path):
		return path
	var alt := path.replace("res://assets/", "res://game/assets/")
	if ResourceLoader.exists(alt):
		return alt
	return path


func _load_atlas(path: String) -> Texture2D:
	var resolved := _resolve_atlas_path(path)
	if resolved.is_empty():
		push_error("Missing required runtime atlas: %s" % path)
		return null
	if ResourceLoader.exists(resolved):
		var loaded = load(resolved)
		if loaded is Texture2D:
			return loaded
	var image := Image.new()
	if image.load(resolved) != OK:
		push_error("Missing required runtime atlas: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


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
			if not (_data.get("encounters", {}) as Dictionary).has(nav):
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
		var destination := Rect2(Vector2(cell * _nav_tile) + record.offset, record.size)
		layer.draw_texture_rect_region(texture, destination, record.source)
