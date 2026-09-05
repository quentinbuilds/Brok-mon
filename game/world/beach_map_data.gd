extends RefCounted
## Licensed 16×16 crescent-shore beach. Navigation stays 8px.

const Util = preload("res://world/map_util.gd")

const ID := &"beach"
const WIDTH := 50
const HEIGHT := 30
const TILE := 8
const VISUAL := 16

enum Ground { SAND, BOARDWALK, DUNE_GRASS, WATER, ROCK }

const TILE_ATLAS := "res://assets/tiles/beach_auto_water.png"
const PROP_ATLAS := "res://assets/tiles/beach_objects.png"

const SRC_WATER := Rect2(32, 16, 16, 16)
const SRC_SAND := Rect2(128, 112, 16, 16)
const SRC_BOARDWALK := Rect2(16, 0, 16, 16)
const SRC_DUNE := Rect2(0, 64, 16, 16)
const SRC_ROCK := Rect2(176, 80, 16, 16)
const SRC_PALM := Rect2(0, 64, 48, 64)
const SRC_DOCK := Rect2(16, 0, 48, 32)
const SRC_SHELTER := Rect2(32, 0, 48, 32)


static func build() -> Dictionary:
	var ground := _build_ground()
	var blocked := {}
	var encounters := {}
	var doors := {}
	_apply_collision(ground, blocked, encounters, doors)
	return {
		"id": ID,
		"visual_tile_size": VISUAL,
		"navigation_tile_size": TILE,
		"width": WIDTH,
		"height": HEIGHT,
		"ground": ground,
		"props_back": _props_back(),
		"props_front": _props_front(),
		"blocked": blocked,
		"encounters": encounters,
		"doors": doors,
		"regions": {
			"boardwalk_arrival": Vector2i(4, 15),
			"jungle_checkpoint": Vector2i(1, 15),
			"jungle_checkpoint_return": Vector2i(3, 15),
			"dock_shelter": Vector2i(20, 16),
			"dock_shelter_door": Vector2i(20, 14),
			"crescent_lookout": Vector2i(36, 15),
			"north_tide_pool": Vector2i(31, 9),
			"south_tide_pool": Vector2i(39, 21),
			"west_dunes": Vector2i(10, 23),
			"south_dunes": Vector2i(26, 25),
		},
		"transitions": [
			{
				"source_rect": Rect2i(0, 14, 2, 2),
				"destination_map_id": &"jungle",
				"destination_region": &"beach_checkpoint_return",
				"destination_facing": Vector2.LEFT,
			},
		],
		"assets": {
			"tile_atlas": TILE_ATLAS,
			"prop_atlas": PROP_ATLAS,
			"ground_regions": {
				Ground.SAND: SRC_SAND,
				Ground.BOARDWALK: SRC_BOARDWALK,
				Ground.DUNE_GRASS: SRC_DUNE,
				Ground.WATER: SRC_WATER,
				Ground.ROCK: SRC_ROCK,
			},
			"encounter_label": "DUNE GRASS",
			"prop_ground_ids": [Ground.SAND, Ground.BOARDWALK, Ground.DUNE_GRASS, Ground.ROCK],
		},
		"spawn_region": &"boardwalk_arrival",
	}


static func _build_ground() -> Array:
	var ground := Util.filled_grid(WIDTH, HEIGHT, Ground.SAND)
	_stamp_ocean(ground)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(0, 7, 10, 2)), Ground.BOARDWALK)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(8, 5, 5, 4)), Ground.BOARDWALK)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(10, 7, 9, 2)), Ground.SAND)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(14, 4, 4, 2)), Ground.ROCK)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(18, 9, 4, 3)), Ground.ROCK)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(3, 10, 5, 3)), Ground.DUNE_GRASS)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(10, 11, 7, 3)), Ground.DUNE_GRASS)
	Util.carve_path(ground, Vector2i(10, 23), Vector2i(26, 23), 2, Ground.SAND)
	Util.carve_path(ground, Vector2i(4, 15), Vector2i(36, 15), 2, Ground.SAND)
	Util.stamp_rect(ground, Rect2i(0, 14, 10, 4), Ground.BOARDWALK)
	return ground


static func _stamp_ocean(ground: Array) -> void:
	for y in range(0, 6):
		Util.stamp_rect(ground, Rect2i(0, y, WIDTH, 1), Ground.WATER)
	# Visual-row ocean mask from the spec, converted to navigation cells.
	_stamp_visual_water(ground, 3, 0, 5)
	_stamp_visual_water(ground, 3, 17, 25)
	_stamp_visual_water(ground, 4, 0, 3)
	_stamp_visual_water(ground, 4, 19, 25)
	_stamp_visual_water(ground, 5, 0, 2)
	_stamp_visual_water(ground, 5, 21, 25)
	_stamp_visual_water(ground, 6, 22, 25)
	_stamp_visual_water(ground, 7, 23, 25)
	for visual_y in range(8, 13):
		_stamp_visual_water(ground, visual_y, 24, 25)
	for visual_y in range(13, 15):
		_stamp_visual_water(ground, visual_y, 22, 25)


static func _stamp_visual_water(ground: Array, visual_y: int, x0: int, x1: int) -> void:
	Util.stamp_rect(ground, Rect2i(x0 * 2, visual_y * 2, (x1 - x0) * 2, 2), Ground.WATER)


static func _apply_collision(
		ground: Array, blocked: Dictionary, encounters: Dictionary, doors: Dictionary) -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var tile := Vector2i(x, y)
			var id: int = ground[y][x]
			if id == Ground.WATER or id == Ground.ROCK:
				blocked[tile] = true
			elif id == Ground.DUNE_GRASS:
				encounters[tile] = true
	Util.block_rect(blocked, Rect2i(18, 10, 6, 4))
	doors[Vector2i(20, 14)] = true
	for y in range(HEIGHT - 2, HEIGHT):
		for x in WIDTH:
			if ground[y][x] != Ground.BOARDWALK:
				blocked[Vector2i(x, y)] = true
	for y in range(14, 16):
		for x in range(0, 8):
			blocked.erase(Vector2i(x, y))
			encounters.erase(Vector2i(x, y))


static func _props_back() -> Array:
	return [
		_prop(Vector2i(18, 10), SRC_SHELTER, Vector2(48, 32), Vector2(0, -8)),
		_prop(Vector2i(0, 14), SRC_DOCK, Vector2(48, 32), Vector2(0, -8)),
		_prop(Vector2i(28, 8), SRC_ROCK, Vector2(16, 16), Vector2.ZERO),
		_prop(Vector2i(36, 18), SRC_ROCK, Vector2(16, 16), Vector2.ZERO),
	]


static func _props_front() -> Array:
	return [
		_prop(Vector2i(8, 18), SRC_PALM, Vector2(48, 64), Vector2(-8, -40)),
		_prop(Vector2i(22, 20), SRC_PALM, Vector2(48, 64), Vector2(-8, -40)),
		_prop(Vector2i(34, 10), SRC_PALM, Vector2(48, 64), Vector2(-8, -40)),
	]


static func _prop(cell: Vector2i, source: Rect2, size: Vector2, offset: Vector2) -> Dictionary:
	return {
		"cell": cell,
		"source": source,
		"size": size,
		"offset": offset,
	}
