extends Node2D
## Compact grassland. Collision and encounter-zone queries live here.
## Tall grass is the only encounter zone. Do not start battles from this file.

const TILE := 32

const PATH := 0
const LAWN := 1
const TALL := 2
const TREE := 3
const ROCK := 4
const WATER := 5

const COLS := 20
const ROWS := 26

var tiles: Array = []
var spawn_tile: Vector2i = Vector2i(4, 22)
var regions := {}


func _ready() -> void:
	_build_map()
	_build_regions()
	queue_redraw()


func map_size_px() -> Vector2:
	return Vector2(COLS * TILE, ROWS * TILE)


func spawn_position() -> Vector2:
	return Vector2(spawn_tile.x * TILE + 4, spawn_tile.y * TILE + 4)


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / TILE)), int(floor(world_pos.y / TILE)))


func tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE + TILE * 0.5, tile.y * TILE + TILE * 0.5)


func in_bounds_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < COLS and tile.y < ROWS


func tile_at(tile: Vector2i) -> int:
	if not in_bounds_tile(tile):
		return TREE
	return tiles[tile.y][tile.x]


func is_blocked_tile(tile: Vector2i) -> bool:
	var kind: int = tile_at(tile)
	return kind == TREE or kind == ROCK or kind == WATER


func is_blocked(world_pos: Vector2) -> bool:
	return is_blocked_tile(world_to_tile(world_pos))


func is_encounter_zone_tile(tile: Vector2i) -> bool:
	return tile_at(tile) == TALL


func is_encounter_zone(world_pos: Vector2) -> bool:
	return is_encounter_zone_tile(world_to_tile(world_pos))


func can_stand(world_pos: Vector2, body: Vector2 = Vector2(24, 24)) -> bool:
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


func _draw() -> void:
	for y in ROWS:
		for x in COLS:
			var origin := Vector2(x * TILE, y * TILE)
			var kind: int = tiles[y][x]
			_draw_tile(origin, kind, x, y)


func _draw_tile(origin: Vector2, kind: int, x: int, y: int) -> void:
	var checker: bool = ((x + y) % 2) == 0
	match kind:
		PATH:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color("e0c48a") if checker else Color("c9a86c"))
			draw_rect(Rect2(origin + Vector2(10, 14), Vector2(4, 2)), Color("b0894a"))
		LAWN:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color("74c69d") if checker else Color("52b788"))
			draw_rect(Rect2(origin + Vector2(6, 10), Vector2(3, 5)), Color("40916c"))
			draw_rect(Rect2(origin + Vector2(18, 18), Vector2(3, 5)), Color("2d6a4f"))
		TALL:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color("2d6a4f") if checker else Color("1b4332"))
			for i in 4:
				var gx: float = origin.x + 4 + i * 7
				draw_rect(Rect2(gx, origin.y + 6, 3, 22), Color("95d5b2") if i % 2 == 0 else Color("52b788"))
		TREE:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color("1b4332"))
			draw_rect(Rect2(origin + Vector2(13, 18), Vector2(6, 12)), Color("6f4518"))
			draw_rect(Rect2(origin + Vector2(4, 2), Vector2(24, 20)), Color("2d6a4f"))
			draw_rect(Rect2(origin + Vector2(8, 0), Vector2(16, 10)), Color("40916c"))
		ROCK:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color("74c69d"))
			draw_rect(Rect2(origin + Vector2(4, 10), Vector2(24, 16)), Color("4a4e69"))
			draw_rect(Rect2(origin + Vector2(8, 8), Vector2(14, 8)), Color("9a8c98"))
		WATER:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color("0077b6") if checker else Color("023e8a"))
			draw_rect(Rect2(origin + Vector2(4, 10), Vector2(20, 3)), Color("90e0ef"))
			draw_rect(Rect2(origin + Vector2(8, 20), Vector2(16, 3)), Color("48cae4"))
		_:
			draw_rect(Rect2(origin, Vector2(TILE, TILE)), Color.BLACK)
	if Vector2i(x, y) == spawn_tile:
		draw_rect(Rect2(origin + Vector2(8, 8), Vector2(16, 16)), Color("ffe8a3"), false, 2.0)


func _build_map() -> void:
	tiles.clear()
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			row.append(LAWN)
		tiles.append(row)

	for x in COLS:
		tiles[0][x] = TREE
		tiles[1][x] = TREE
		tiles[ROWS - 1][x] = TREE
		tiles[ROWS - 2][x] = TREE
	for y in ROWS:
		tiles[y][0] = TREE
		tiles[y][1] = TREE
		tiles[y][COLS - 1] = TREE
		tiles[y][COLS - 2] = TREE

	_stamp_rect(12, 3, 6, 5, WATER)
	_stamp_rect(13, 2, 4, 2, WATER)

	_stamp_rect(2, 2, 3, 4, TREE)
	_stamp_rect(14, 12, 4, 3, TREE)
	_stamp_rect(8, 16, 3, 3, TREE)

	_stamp_rect(5, 10, 2, 2, ROCK)
	_stamp_rect(15, 18, 2, 2, ROCK)
	_stamp_rect(3, 17, 2, 1, ROCK)

	# Tall-grass meadows — these are the encounter zones.
	_stamp_rect(8, 8, 5, 5, TALL)
	_stamp_rect(7, 20, 5, 4, TALL)
	_stamp_rect(3, 6, 3, 4, TALL)

	_carve_path()
	tiles[spawn_tile.y][spawn_tile.x] = PATH


func _build_regions() -> void:
	regions = {
		"player_start": spawn_position(),
		"pond": tile_center(Vector2i(14, 5)),
		"north_meadow": tile_center(Vector2i(10, 10)),
		"south_meadow": tile_center(Vector2i(9, 22)),
		"west_thicket": tile_center(Vector2i(4, 8)),
	}


func _stamp_rect(x: int, y: int, w: int, h: int, kind: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if not in_bounds_tile(Vector2i(xx, yy)):
				continue
			if xx <= 1 or yy <= 1 or xx >= COLS - 2 or yy >= ROWS - 2:
				continue
			tiles[yy][xx] = kind


func _carve_path() -> void:
	for y in range(8, 24):
		tiles[y][4] = PATH
		tiles[y][5] = PATH
	for x in range(4, 15):
		tiles[11][x] = PATH
		tiles[12][x] = PATH
	for y in range(4, 12):
		tiles[y][13] = PATH
		tiles[y][14] = PATH
	for x in range(5, 10):
		tiles[19][x] = PATH
