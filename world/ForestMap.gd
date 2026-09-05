extends TileMapLayer
## 16x16 forest ground. Open this scene (or OverworldState) and paint with ForestTileset.
## Demo cells may be stored on the layer; paint_demo() fills a 4x-larger map if empty or small.

const Catalog := preload("res://world/tiles/ForestTileCatalog.gd")

const CHUNK := Vector2i(13, 8)
const DEMO_SIZE := Vector2i(52, 32) ## 4x CHUNK in each dimension


func _ready() -> void:
	if tile_set == null:
		tile_set = load(Catalog.TILESET_PATH) as TileSet
	if get_used_cells().is_empty() or get_used_rect().size.x < DEMO_SIZE.x or get_used_rect().size.y < DEMO_SIZE.y:
		paint_demo()


func paint_named(cell: Vector2i, tile_name: String) -> void:
	var t: Vector3i = Catalog.TILES[tile_name]
	set_cell(cell, t.x, Vector2i(t.y, t.z))


func is_water_cell(cell: Vector2i) -> bool:
	var sid := get_cell_source_id(cell)
	if sid < 0:
		return false
	var coords := get_cell_atlas_coords(cell)
	for tile_name in Catalog.WATER_TILES:
		if Catalog.source_id(tile_name) == sid and Catalog.atlas(tile_name) == coords:
			return true
	var data := get_cell_tile_data(cell)
	if data == null:
		return false
	return Catalog.is_water(str(data.get_custom_data("name")))


func pixel_rect() -> Rect2:
	var used := get_used_rect()
	var ts := Vector2(Catalog.TILE_SIZE, Catalog.TILE_SIZE)
	if tile_set != null:
		ts = Vector2(tile_set.tile_size)
	return Rect2(Vector2(used.position) * ts, Vector2(used.size) * ts)


func paint_demo() -> void:
	for y in DEMO_SIZE.y:
		for x in DEMO_SIZE.x:
			paint_named(Vector2i(x, y), "grass")
	var tiles_x := int(DEMO_SIZE.x / CHUNK.x)
	var tiles_y := int(DEMO_SIZE.y / CHUNK.y)
	for cy in tiles_y:
		for cx in tiles_x:
			_stamp_chunk(Vector2i(cx * CHUNK.x, cy * CHUNK.y))


func _stamp_chunk(o: Vector2i) -> void:
	_stamp3(o + Vector2i(3, 0), "forest", "grass")
	paint_named(o + Vector2i(1, 1), "tree_nw")
	paint_named(o + Vector2i(2, 1), "tree_ne")
	paint_named(o + Vector2i(1, 2), "tree_sw")
	paint_named(o + Vector2i(2, 2), "tree_se")
	_stamp3(o + Vector2i(7, 2), "path", "path")
	paint_named(o + Vector2i(8, 3), "path_grass_nw")
	paint_named(o + Vector2i(8, 4), "path_grass_sw")
	paint_named(o + Vector2i(9, 3), "path_pebbles_a")
	_stamp3(o + Vector2i(3, 5), "farm", "farmland")
	_stamp3(o + Vector2i(8, 5), "pond", "water")
	paint_named(o + Vector2i(0, 5), "grass_tuft_a")
	paint_named(o + Vector2i(0, 6), "grass_tuft_b")
	paint_named(o + Vector2i(1, 6), "grass_tuft_c")


func _stamp3(origin: Vector2i, prefix: String, center: String) -> void:
	var names: Array[String] = [
		"%s_nw" % prefix, "%s_n" % prefix, "%s_ne" % prefix,
		"%s_w" % prefix, center, "%s_e" % prefix,
		"%s_sw" % prefix, "%s_s" % prefix, "%s_se" % prefix,
	]
	for y in 3:
		for x in 3:
			paint_named(origin + Vector2i(x, y), names[y * 3 + x])
