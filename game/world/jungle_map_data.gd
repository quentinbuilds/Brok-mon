extends RefCounted
## Licensed 16×16 jungle. Navigation stays 8px.

const Util = preload("res://world/map_util.gd")

const ID := &"jungle"
const WIDTH := 50
const HEIGHT := 30
const TILE := 8
const VISUAL := 16

enum Ground { LAWN, PATH, TALL_GRASS, WATER }

const TILE_ATLAS := "res://assets/tiles/jungle_auto_ground.png"
const FOLIAGE_ATLAS := "res://assets/tiles/jungle_auto_water.png"
const PROP_ATLAS := "res://assets/tiles/jungle_objects.png"
const WATER_ATLAS := "res://assets/tiles/beach_auto_water.png"

const SRC_LAWN := Rect2(16, 80, 16, 16)
const SRC_PATH := Rect2(80, 0, 16, 16)
const SRC_GRASS := Rect2(0, 48, 16, 16)
const SRC_WATER := Rect2(32, 16, 16, 16)
const SRC_TREE := Rect2(176, 16, 32, 48)
const SRC_BUSH := Rect2(80, 96, 32, 32)
const SRC_ROCK := Rect2(16, 64, 16, 16)
const SRC_STATION := Rect2(208, 0, 48, 32)
const SRC_STATION_ROOF := Rect2(80, 96, 32, 32)


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
			"player_start": Vector2i(5, 25),
			"research_outpost": Vector2i(17, 19),
			"field_station_door": Vector2i(17, 21),
			"fossil_clearing": Vector2i(34, 14),
			"pond": Vector2i(42, 8),
			"north_meadow": Vector2i(25, 7),
			"south_meadow": Vector2i(28, 24),
			"west_thicket": Vector2i(7, 11),
			"beach_checkpoint": Vector2i(48, 15),
			"beach_checkpoint_return": Vector2i(46, 15),
			"volcanic_exit": Vector2i(48, 15),
			"snow_exit": Vector2i(25, 2),
			"desert_exit": Vector2i(2, 15),
			"forest_exit": Vector2i(25, 28),
		},
		"transitions": [
			{
				"source_rect": Rect2i(48, 14, 2, 2),
				"destination_map_id": &"beach",
				"destination_region": &"boardwalk_arrival",
				"destination_facing": Vector2.RIGHT,
			},
		],
		"assets": {
			"tile_atlas": TILE_ATLAS,
			"prop_atlas": PROP_ATLAS,
			"ground_regions": {
				Ground.LAWN: SRC_LAWN,
				Ground.PATH: SRC_PATH,
				Ground.TALL_GRASS: SRC_GRASS,
				Ground.WATER: SRC_WATER,
			},
			"ground_atlases": {
				Ground.LAWN: FOLIAGE_ATLAS,
				Ground.TALL_GRASS: FOLIAGE_ATLAS,
				Ground.WATER: WATER_ATLAS,
			},
			"encounter_label": "TALL GRASS",
		},
		"spawn_region": &"player_start",
	}


static func _build_ground() -> Array:
	var ground := Util.filled_grid(WIDTH, HEIGHT, Ground.LAWN)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(9, 2, 7, 4)), Ground.TALL_GRASS)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(7, 11, 10, 3)), Ground.TALL_GRASS)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(1, 4, 5, 4)), Ground.TALL_GRASS)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(19, 2, 4, 5)), Ground.WATER)
	_carve_trail(ground)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(6, 8, 8, 4)), Ground.LAWN)
	Util.stamp_rect(ground, Util.visual_to_nav(Rect2i(15, 5, 5, 5)), Ground.LAWN)
	_carve_trail(ground)
	Util.stamp_rect(ground, Rect2i(46, 14, 4, 2), Ground.PATH)
	return ground


static func _carve_trail(ground: Array) -> void:
	var points := [
		Vector2i(5, 25), Vector2i(5, 19), Vector2i(17, 19), Vector2i(17, 14),
		Vector2i(34, 14), Vector2i(34, 8), Vector2i(38, 8), Vector2i(38, 15),
		Vector2i(46, 15),
	]
	for index in range(points.size() - 1):
		Util.carve_path(ground, points[index], points[index + 1], 3, Ground.PATH)


static func _apply_collision(
		ground: Array, blocked: Dictionary, encounters: Dictionary, doors: Dictionary) -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var tile := Vector2i(x, y)
			var on_border := x < 2 or y < 2 or x >= WIDTH - 2 or y >= HEIGHT - 2
			var bridge_opening := x >= 46 and y >= 14 and y <= 17
			if on_border and not bridge_opening:
				blocked[tile] = true
			if ground[y][x] == Ground.WATER:
				blocked[tile] = true
			if ground[y][x] == Ground.TALL_GRASS and not blocked.has(tile):
				encounters[tile] = true
	Util.block_rect(blocked, Rect2i(14, 16, 8, 6))
	doors[Vector2i(17, 21)] = true
	Util.block_rect(blocked, Rect2i(32, 12, 2, 2))
	for marker in [Vector2i(25, 2), Vector2i(2, 15), Vector2i(25, 28)]:
		blocked[marker] = true
	for y in range(14, 16):
		for x in range(46, 50):
			blocked.erase(Vector2i(x, y))
			encounters.erase(Vector2i(x, y))


static func _props_back() -> Array:
	var props: Array = []
	for y in range(0, HEIGHT, 4):
		for x in range(0, WIDTH, 4):
			var on_border := x < 2 or y < 2 or x >= WIDTH - 2 or y >= HEIGHT - 2
			var bridge_opening := x >= 46 and y >= 14 and y <= 17
			if on_border and not bridge_opening:
				props.append(_prop(Vector2i(x, y), SRC_TREE, Vector2(32, 48), Vector2(-8, -24)))
	props.append(_prop(Vector2i(14, 16), SRC_STATION, Vector2(48, 32), Vector2(8, 0)))
	props.append(_prop(Vector2i(12, 16), SRC_TREE, Vector2(32, 48), Vector2(-8, -24)))
	props.append(_prop(Vector2i(20, 16), SRC_TREE, Vector2(32, 48), Vector2(-8, -24)))
	props.append(_prop(Vector2i(32, 12), SRC_ROCK, Vector2(16, 16), Vector2.ZERO))
	props.append(_prop(Vector2i(36, 12), SRC_ROCK, Vector2(16, 16), Vector2.ZERO))
	props.append(_prop(Vector2i(30, 6), SRC_BUSH, Vector2(32, 32), Vector2(-8, -8)))
	props.append(_prop(Vector2i(8, 8), SRC_BUSH, Vector2(32, 32), Vector2(-8, -8)))
	return props


static func _props_front() -> Array:
	return [
		_prop(Vector2i(16, 14), SRC_STATION_ROOF, Vector2(32, 32), Vector2(0, -16)),
		_prop(Vector2i(40, 4), SRC_TREE, Vector2(32, 48), Vector2(-8, -24)),
		_prop(Vector2i(20, 4), SRC_TREE, Vector2(32, 48), Vector2(-8, -24)),
	]


static func _prop(cell: Vector2i, source: Rect2, size: Vector2, offset: Vector2, atlas := "") -> Dictionary:
	var record := {
		"cell": cell,
		"source": source,
		"size": size,
		"offset": offset,
	}
	if atlas != "":
		record.atlas = atlas
	return record
