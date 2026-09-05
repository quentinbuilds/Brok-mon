extends RefCounted
## Named 16x16 forest tiles. Visual tile size is 16; OverworldState movement stays on TILE := 8.

const TILE_SIZE := 16
const TILESET_PATH := "res://world/tiles/ForestTileset.tres"
const MAP_PATH := "res://world/ForestMap.tscn"

## name -> Vector3i(source_id, atlas_x, atlas_y)
const TILES := {
	"grass": Vector3i(0, 0, 0),
	"path": Vector3i(2, 0, 0),
	"water": Vector3i(3, 0, 0),
	"path_nw": Vector3i(1, 0, 0),
	"path_n": Vector3i(1, 1, 0),
	"path_ne": Vector3i(1, 2, 0),
	"path_w": Vector3i(1, 0, 1),
	"path_e": Vector3i(1, 2, 1),
	"path_sw": Vector3i(1, 0, 2),
	"path_s": Vector3i(1, 1, 2),
	"path_se": Vector3i(1, 2, 2),
	"path_grass_nw": Vector3i(1, 0, 3),
	"path_grass_ne": Vector3i(1, 1, 3),
	"path_grass_sw": Vector3i(1, 0, 4),
	"path_grass_se": Vector3i(1, 1, 4),
	"path_pebbles_a": Vector3i(1, 0, 5),
	"path_pebbles_b": Vector3i(1, 1, 5),
	"path_pebbles_c": Vector3i(1, 2, 5),
	"pond_nw": Vector3i(4, 0, 0),
	"pond_n": Vector3i(4, 1, 0),
	"pond_ne": Vector3i(4, 2, 0),
	"pond_w": Vector3i(4, 0, 1),
	"pond_e": Vector3i(4, 2, 1),
	"pond_sw": Vector3i(4, 0, 2),
	"pond_s": Vector3i(4, 1, 2),
	"pond_se": Vector3i(4, 2, 2),
	"island_nw": Vector3i(4, 0, 3),
	"island_ne": Vector3i(4, 1, 3),
	"island_sw": Vector3i(4, 0, 4),
	"island_se": Vector3i(4, 1, 4),
	"water_ripple_a": Vector3i(4, 0, 5),
	"water_ripple_b": Vector3i(4, 1, 5),
	"water_ripple_c": Vector3i(4, 2, 5),
	"farm_nw": Vector3i(5, 0, 0),
	"farm_n": Vector3i(5, 1, 0),
	"farm_ne": Vector3i(5, 2, 0),
	"farm_w": Vector3i(5, 0, 1),
	"farmland": Vector3i(5, 1, 1),
	"farm_e": Vector3i(5, 2, 1),
	"farm_sw": Vector3i(5, 0, 2),
	"farm_s": Vector3i(5, 1, 2),
	"farm_se": Vector3i(5, 2, 2),
	"forest_nw": Vector3i(6, 0, 0),
	"forest_n": Vector3i(6, 1, 0),
	"forest_ne": Vector3i(6, 2, 0),
	"forest_w": Vector3i(6, 0, 1),
	"forest_e": Vector3i(6, 2, 1),
	"forest_sw": Vector3i(6, 0, 2),
	"forest_s": Vector3i(6, 1, 2),
	"forest_se": Vector3i(6, 2, 2),
	"tree_nw": Vector3i(6, 0, 3),
	"tree_ne": Vector3i(6, 1, 3),
	"tree_sw": Vector3i(6, 0, 4),
	"tree_se": Vector3i(6, 1, 4),
	"tree_top": Vector3i(6, 0, 3),
	"tree_base": Vector3i(6, 0, 4),
	"grass_tuft_a": Vector3i(6, 0, 5),
	"grass_tuft_b": Vector3i(6, 1, 5),
	"grass_tuft_c": Vector3i(6, 2, 5),
	"beach_island_nw": Vector3i(7, 0, 0),
	"beach_island_n": Vector3i(7, 1, 0),
	"beach_island_ne": Vector3i(7, 2, 0),
	"beach_island_w": Vector3i(7, 0, 1),
	"beach_sand": Vector3i(7, 1, 1),
	"beach_island_e": Vector3i(7, 2, 1),
	"beach_island_sw": Vector3i(7, 0, 2),
	"beach_island_s": Vector3i(7, 1, 2),
	"beach_island_se": Vector3i(7, 2, 2),
	"pond_sand_nw": Vector3i(7, 3, 0),
	"pond_sand_ne": Vector3i(7, 4, 0),
	"pond_sand_sw": Vector3i(7, 3, 1),
	"pond_sand_se": Vector3i(7, 4, 1),
}

const WATER_TILES := [
	"water",
	"pond_nw",
	"pond_n",
	"pond_ne",
	"pond_w",
	"pond_e",
	"pond_sw",
	"pond_s",
	"pond_se",
	"island_nw",
	"island_ne",
	"island_sw",
	"island_se",
	"water_ripple_a",
	"water_ripple_b",
	"water_ripple_c",
	"beach_island_nw",
	"beach_island_n",
	"beach_island_ne",
	"beach_island_w",
	"beach_island_e",
	"beach_island_sw",
	"beach_island_s",
	"beach_island_se",
	"pond_sand_nw",
	"pond_sand_ne",
	"pond_sand_sw",
	"pond_sand_se",
]

static func has_tile(tile_name: String) -> bool:
	return TILES.has(tile_name)


static func atlas(tile_name: String) -> Vector2i:
	var t: Vector3i = TILES[tile_name]
	return Vector2i(t.y, t.z)


static func source_id(tile_name: String) -> int:
	return TILES[tile_name].x


static func is_water(tile_name: String) -> bool:
	return tile_name in WATER_TILES
