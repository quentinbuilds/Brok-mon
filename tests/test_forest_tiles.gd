extends TestCase
## Forest overworld tiles: 16x16 TileSet, named catalog, and a loadable demo map.

const Catalog := preload("res://world/tiles/ForestTileCatalog.gd")

const KEY_TILES := [
	"grass", "path", "path_n", "path_e", "path_s", "path_w", "path_nw",
	"water", "pond_n", "farmland", "tree_top", "tree_base",
	"grass_tuft_a", "beach_sand",
]

const SHEETS := [
	"res://assets/tiles/grass_middle.png",
	"res://assets/tiles/path_middle.png",
	"res://assets/tiles/path.png",
	"res://assets/tiles/water_middle.png",
	"res://assets/tiles/water.png",
	"res://assets/tiles/farmland.png",
	"res://assets/tiles/forest.png",
	"res://assets/tiles/beach.png",
]


func test_tile_pngs_exist() -> void:
	for path in SHEETS:
		assert_true(FileAccess.file_exists(path), path)


func test_tileset_exists_and_is_16px() -> void:
	var ts := load(Catalog.TILESET_PATH) as TileSet
	assert_true(ts != null, "ForestTileset.tres must load")
	if ts == null:
		return
	assert_eq(ts.tile_size, Vector2i(16, 16))
	assert_eq(Catalog.TILE_SIZE, 16)
	assert_eq(ts.get_source_count(), 8)


func test_key_tile_names_exist() -> void:
	var ts := load(Catalog.TILESET_PATH) as TileSet
	assert_true(ts != null, "ForestTileset.tres must load")
	if ts == null:
		return
	for tile_name in KEY_TILES:
		assert_true(Catalog.has_tile(tile_name), "catalog missing %s" % tile_name)
		var sid: int = Catalog.source_id(tile_name)
		var atlas: Vector2i = Catalog.atlas(tile_name)
		var src := ts.get_source(sid) as TileSetAtlasSource
		assert_true(src != null, "no atlas source for %s" % tile_name)
		if src == null:
			continue
		assert_eq(src.texture_region_size, Vector2i(16, 16), tile_name)
		assert_true(src.has_tile(atlas), "%s missing atlas cell %s" % [tile_name, atlas])
		var data := src.get_tile_data(atlas, 0)
		assert_true(data != null, "no TileData for %s" % tile_name)
		if data == null:
			continue
		var stored: String = str(data.get_custom_data("name"))
		assert_true(stored != "", "custom data name empty for %s" % tile_name)


func test_map_scene_loads() -> void:
	var packed := load(Catalog.MAP_PATH) as PackedScene
	assert_true(packed != null, "ForestMap.tscn must load")
	if packed == null:
		return
	var map: Node = packed.instantiate()
	tree.root.add_child(map)
	await tree.process_frame
	assert_true(map is TileMapLayer, "ForestMap root is TileMapLayer")
	if not (map is TileMapLayer):
		map.queue_free()
		return
	var layer := map as TileMapLayer
	assert_true(layer.tile_set != null, "map has a TileSet")
	if layer.tile_set != null:
		assert_eq(layer.tile_set.tile_size, Vector2i(16, 16))
	assert_true(layer.get_used_cells().size() > 0, "demo map has painted tiles")
	map.queue_free()

