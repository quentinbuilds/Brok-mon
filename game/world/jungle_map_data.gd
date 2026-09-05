extends RefCounted
## Deterministic tile, collision, encounter, and landmark data for Expedition Trail.

const WIDTH := 50
const HEIGHT := 30
const TILE := 8

enum Ground { LAWN, PATH, TALL_GRASS, WATER }
enum Prop {
	NONE,
	TREE,
	FERN,
	CYCAD,
	PALM,
	ROCK,
	BONE,
	FOOTPRINT,
	EGGSHELL,
	HUT_WALL,
	HUT_DOOR,
	FOSSIL_SHRINE,
	EXIT_MARKER,
}


static func build() -> Dictionary:
	var ground := _build_ground()
	var props := _build_props()
	return {
		"ground": ground,
		"props": props,
		"blocked": _build_blocked(ground, props),
		"encounters": _build_encounters(ground),
		"doors": _collect_prop_tiles(props, Prop.HUT_DOOR),
		"regions": {
			"player_start": Vector2i(5, 25),
			"research_outpost": Vector2i(16, 19),
			"fossil_clearing": Vector2i(34, 14),
			"pond": Vector2i(42, 7),
			"north_meadow": Vector2i(25, 7),
			"south_meadow": Vector2i(28, 23),
			"west_thicket": Vector2i(7, 11),
			"volcanic_exit": Vector2i(48, 15),
			"snow_exit": Vector2i(25, 2),
			"desert_exit": Vector2i(2, 15),
			"forest_exit": Vector2i(25, 28),
		},
	}


static func _build_ground() -> Array:
	var ground := _filled_grid(Ground.LAWN)

	# Three distinct tall-grass encounter areas.
	_stamp_rect(ground, Rect2i(19, 5, 13, 6), Ground.TALL_GRASS)
	_stamp_rect(ground, Rect2i(15, 22, 18, 5), Ground.TALL_GRASS)
	_stamp_rect(ground, Rect2i(3, 8, 9, 7), Ground.TALL_GRASS)

	# Pond with an irregular lawn bank.
	_stamp_rect(ground, Rect2i(39, 4, 7, 7), Ground.WATER)
	_carve(ground, Vector2i(39, 4), Ground.LAWN)
	_carve(ground, Vector2i(45, 4), Ground.LAWN)
	_carve(ground, Vector2i(39, 10), Ground.LAWN)
	_carve(ground, Vector2i(45, 10), Ground.LAWN)

	# A three-tile-wide S trail supports the current free-movement actor.
	_carve_path_segment(ground, Vector2i(5, 27), Vector2i(5, 19), 3)
	_carve_path_segment(ground, Vector2i(5, 19), Vector2i(17, 19), 3)
	_carve_path_segment(ground, Vector2i(17, 19), Vector2i(17, 14), 3)
	_carve_path_segment(ground, Vector2i(17, 14), Vector2i(34, 14), 3)
	_carve_path_segment(ground, Vector2i(34, 14), Vector2i(34, 8), 3)
	_carve_path_segment(ground, Vector2i(34, 8), Vector2i(38, 8), 3)
	_carve_path_segment(ground, Vector2i(38, 8), Vector2i(38, 7), 3)

	# Landmark clearings stay readable against the surrounding vegetation.
	_stamp_rect(ground, Rect2i(13, 16, 14, 6), Ground.LAWN)
	_stamp_rect(ground, Rect2i(30, 11, 9, 7), Ground.LAWN)
	_carve_path_segment(ground, Vector2i(17, 19), Vector2i(17, 14), 3)
	_carve_path_segment(ground, Vector2i(25, 7), Vector2i(25, 10), 3)
	_carve_path_segment(ground, Vector2i(5, 25), Vector2i(8, 25), 3)
	return ground


static func _build_props() -> Array:
	var props := _filled_grid(Prop.NONE)

	# Dense, two-tile jungle bounds.
	for y in HEIGHT:
		for x in WIDTH:
			if x < 2 or y < 2 or x >= WIDTH - 2 or y >= HEIGHT - 2:
				props[y][x] = Prop.TREE

	# Interior foliage clusters make the bounds feel dense without closing paths.
	_stamp_foliage(props, Rect2i(2, 2, 6, 5))
	_stamp_foliage(props, Rect2i(42, 12, 6, 8))
	_stamp_foliage(props, Rect2i(2, 17, 4, 6))
	_stamp_foliage(props, Rect2i(35, 21, 7, 7))
	_stamp_foliage(props, Rect2i(12, 4, 5, 4))

	# Two 4x3 research huts. Doors are visible but intentionally blocked.
	_stamp_hut(props, Vector2i(14, 17), Vector2i(17, 19))
	_stamp_hut(props, Vector2i(22, 17), Vector2i(25, 19))

	# Fossil clearing details.
	props[13][34] = Prop.FOSSIL_SHRINE
	props[12][32] = Prop.BONE
	props[15][36] = Prop.BONE
	props[16][32] = Prop.FOOTPRINT
	props[12][37] = Prop.EGGSHELL
	props[16][37] = Prop.ROCK

	# Pond-bank and meadow accents.
	props[5][38] = Prop.CYCAD
	props[10][40] = Prop.FERN
	props[11][44] = Prop.PALM
	props[6][46] = Prop.ROCK
	props[4][18] = Prop.PALM
	props[11][13] = Prop.CYCAD
	props[21][30] = Prop.FERN

	# Future biome links remain blocked until their states exist.
	for marker in [
		Vector2i(48, 15),
		Vector2i(25, 2),
		Vector2i(2, 15),
		Vector2i(25, 28),
	]:
		props[marker.y][marker.x] = Prop.EXIT_MARKER
	return props


static func _build_blocked(ground: Array, props: Array) -> Dictionary:
	var result := {}
	for y in HEIGHT:
		for x in WIDTH:
			var tile := Vector2i(x, y)
			var prop: int = props[y][x]
			if ground[y][x] == Ground.WATER or prop in [
				Prop.TREE,
				Prop.ROCK,
				Prop.HUT_WALL,
				Prop.HUT_DOOR,
				Prop.FOSSIL_SHRINE,
				Prop.EXIT_MARKER,
			]:
				result[tile] = true
	return result


static func _build_encounters(ground: Array) -> Dictionary:
	var result := {}
	for y in HEIGHT:
		for x in WIDTH:
			if ground[y][x] == Ground.TALL_GRASS:
				result[Vector2i(x, y)] = true
	return result


static func _filled_grid(value: int) -> Array:
	var grid: Array = []
	for y in HEIGHT:
		var row: Array[int] = []
		row.resize(WIDTH)
		row.fill(value)
		grid.append(row)
	return grid


static func _stamp_rect(grid: Array, rect: Rect2i, value: int) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT:
				grid[y][x] = value


static func _carve(grid: Array, tile: Vector2i, value: int) -> void:
	if tile.x >= 0 and tile.y >= 0 and tile.x < WIDTH and tile.y < HEIGHT:
		grid[tile.y][tile.x] = value


static func _carve_path_segment(
		ground: Array, from_tile: Vector2i, to_tile: Vector2i, width: int) -> void:
	var cursor := from_tile
	var step := Vector2i(signi(to_tile.x - from_tile.x), signi(to_tile.y - from_tile.y))
	while true:
		for offset in range(-(width / 2), width - width / 2):
			var tile := cursor + (Vector2i(0, offset) if step.x != 0 else Vector2i(offset, 0))
			_carve(ground, tile, Ground.PATH)
		if cursor == to_tile:
			break
		cursor += step


static func _stamp_foliage(props: Array, rect: Rect2i) -> void:
	var accents := [Prop.TREE, Prop.FERN, Prop.TREE, Prop.CYCAD, Prop.PALM]
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if (x + y * 3) % 4 != 0:
				props[y][x] = accents[(x * 7 + y * 3) % accents.size()]


static func _stamp_hut(props: Array, origin: Vector2i, door: Vector2i) -> void:
	for y in range(origin.y, origin.y + 3):
		for x in range(origin.x, origin.x + 4):
			props[y][x] = Prop.HUT_WALL
	props[door.y][door.x] = Prop.HUT_DOOR


static func _collect_prop_tiles(props: Array, wanted: int) -> Dictionary:
	var result := {}
	for y in HEIGHT:
		for x in WIDTH:
			if props[y][x] == wanted:
				result[Vector2i(x, y)] = true
	return result
