extends RefCounted
## Live jungle/beach session for the root overworld. Player.gd still asks GrassMap;
## this is bound only while OverworldState is in the tree.

const Jungle = preload("res://game/world/jungle_map_data.gd")
const Beach = preload("res://game/world/beach_map_data.gd")

const WORLD_JUNGLE := &"jungle"
const WORLD_BEACH := &"beach"
const WORLD_GRASSLAND := &"grassland"

static var preferred: StringName = WORLD_JUNGLE
static var _active: bool = false
static var _map_id: StringName = WORLD_JUNGLE
static var _def: Dictionary = {}


static func choose(which: StringName) -> void:
	if which == WORLD_BEACH:
		preferred = WORLD_JUNGLE
	elif which == WORLD_GRASSLAND or which == WORLD_JUNGLE:
		preferred = which
	else:
		preferred = WORLD_JUNGLE


static func is_grassland() -> bool:
	return preferred == WORLD_GRASSLAND


static func is_active() -> bool:
	return _active


static func map_id() -> StringName:
	return _map_id


static func definition(which: StringName = &"") -> Dictionary:
	var requested: StringName = which if which != &"" else _map_id
	match requested:
		&"jungle":
			return Jungle.build()
		&"beach":
			return Beach.build()
		_:
			return {}


static func bind(which: StringName = &"") -> Dictionary:
	var requested: StringName = which if which != &"" else preferred
	if requested == WORLD_GRASSLAND:
		_active = false
		_def = {}
		_map_id = WORLD_GRASSLAND
		preferred = WORLD_GRASSLAND
		return {}
	return load_map(requested)


static func load_map(which: StringName) -> Dictionary:
	_def = definition(which)
	if _def.is_empty():
		_def = Jungle.build()
	_map_id = _def.id
	_active = true
	return _def


static func unbind() -> void:
	_active = false
	_def = {}
	_map_id = preferred


static func reset_choice() -> void:
	preferred = WORLD_JUNGLE
	unbind()
	_map_id = WORLD_JUNGLE


static func current() -> Dictionary:
	return _def


static func is_walkable(tile: Vector2i) -> bool:
	if _def.is_empty():
		return false
	var width := int(_def.get("width", 0))
	var height := int(_def.get("height", 0))
	if tile.x < 0 or tile.y < 0 or tile.x >= width or tile.y >= height:
		return false
	return not (_def.blocked as Dictionary).has(tile)


static func is_encounter_zone(tile: Vector2i) -> bool:
	if _def.is_empty():
		return false
	return (_def.encounters as Dictionary).has(tile)


static func start_tile() -> Vector2i:
	var regions: Dictionary = _def.get("regions", {})
	var spawn: StringName = _def.get("spawn_region", &"player_start")
	if regions.has(spawn):
		return regions[spawn]
	if regions.has("player_start"):
		return regions.player_start
	return Vector2i(5, 25)


static func pixel_size() -> Vector2i:
	var tile := int(_def.get("navigation_tile_size", 8))
	return Vector2i(int(_def.get("width", 50)), int(_def.get("height", 30))) * tile


static func transition_at(tile: Vector2i) -> Dictionary:
	for record in _def.get("transitions", []):
		var rect: Rect2i = record.source_rect
		if rect.has_point(tile):
			return record
	return {}


static func region_tile(region_name: StringName) -> Vector2i:
	var regions: Dictionary = _def.get("regions", {})
	if regions.has(region_name):
		return regions[region_name]
	return Vector2i.ZERO
