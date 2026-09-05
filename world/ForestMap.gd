extends TileMapLayer
## 16x16 forest ground. Open this scene (or OverworldState) and paint with ForestTileset.
## Demo cells are already stored on the layer; paint_demo() runs only if the layer is empty.

const Catalog := preload("res://world/tiles/ForestTileCatalog.gd")

func _ready() -> void:
	if tile_set == null:
		tile_set = load(Catalog.TILESET_PATH) as TileSet
	if get_used_cells().is_empty():
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


func paint_demo() -> void:
	for y in 8:
		for x in 13:
			paint_named(Vector2i(x, y), "grass")
	_stamp3(Vector2i(3, 0), "forest", "grass")
	paint_named(Vector2i(1, 1), "tree_nw")
	paint_named(Vector2i(2, 1), "tree_ne")
	paint_named(Vector2i(1, 2), "tree_sw")
	paint_named(Vector2i(2, 2), "tree_se")
	_stamp3(Vector2i(7, 2), "path", "path")
	paint_named(Vector2i(8, 3), "path_grass_nw")
	paint_named(Vector2i(8, 4), "path_grass_sw")
	paint_named(Vector2i(9, 3), "path_pebbles_a")
	_stamp3(Vector2i(3, 5), "farm", "farmland")
	_stamp3(Vector2i(8, 5), "pond", "water")
	paint_named(Vector2i(0, 5), "grass_tuft_a")
	paint_named(Vector2i(0, 6), "grass_tuft_b")
	paint_named(Vector2i(1, 6), "grass_tuft_c")


func _stamp3(origin: Vector2i, prefix: String, center: String) -> void:
	var names: Array[String] = [
		"%s_nw" % prefix, "%s_n" % prefix, "%s_ne" % prefix,
		"%s_w" % prefix, center, "%s_e" % prefix,
		"%s_sw" % prefix, "%s_s" % prefix, "%s_se" % prefix,
	]
	for y in 3:
		for x in 3:
			paint_named(origin + Vector2i(x, y), names[y * 3 + x])
