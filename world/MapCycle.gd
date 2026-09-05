extends RefCounted
## World-owned data for the two alternate overworld presentations.

const GrassMap := preload("res://world/GrassMap.gd")

enum Mode { DEFAULT, INTERIOR, BEACH }

const TILE := 16
const DEFAULT_DOOR := Vector2i(30, 10)
const DEFAULT_RETURN := Vector2i(30, 13)
const INTERIOR_SPAWN := Vector2i(10, 9)
const INTERIOR_EXIT := Vector2i(10, 10)
const BEACH_DOOR := Vector2i(15, 6)
const BEACH_RETURN := Vector2i(15, 7)

const INTERIOR_BLOCKED := {
	Vector2i(6, 3): true, Vector2i(7, 3): true,
	Vector2i(6, 4): true, Vector2i(7, 4): true,
	Vector2i(9, 4): true, Vector2i(10, 4): true,
	Vector2i(9, 5): true, Vector2i(10, 5): true,
	Vector2i(13, 3): true, Vector2i(13, 4): true,
	Vector2i(13, 5): true, Vector2i(13, 8): true,
	Vector2i(11, 9): true, Vector2i(12, 9): true,
}

const BEACH_BLOCKED := {
	Vector2i(5, 2): true, Vector2i(6, 2): true,
	Vector2i(5, 3): true, Vector2i(6, 3): true,
	Vector2i(5, 8): true, Vector2i(6, 8): true,
	Vector2i(14, 3): true, Vector2i(15, 3): true, Vector2i(16, 3): true,
	Vector2i(14, 4): true, Vector2i(15, 4): true, Vector2i(16, 4): true,
	Vector2i(14, 5): true, Vector2i(15, 5): true, Vector2i(16, 5): true,
}

static func is_walkable(mode: Mode, tile: Vector2i) -> bool:
	match mode:
		Mode.DEFAULT:
			var doorway := tile.x == DEFAULT_DOOR.x and tile.y >= DEFAULT_DOOR.y and tile.y <= 12
			return doorway or GrassMap.is_walkable(tile)
		Mode.INTERIOR:
			return tile.x >= 6 and tile.x <= 13 and tile.y >= 3 and tile.y <= 10 \
				and not INTERIOR_BLOCKED.has(tile)
		Mode.BEACH:
			return tile.x >= 5 and tile.x <= 17 and tile.y >= 2 and tile.y <= 9 \
				and (tile == BEACH_DOOR or not BEACH_BLOCKED.has(tile))
	return false

static func is_encounter_zone(mode: Mode, tile: Vector2i) -> bool:
	if mode == Mode.DEFAULT:
		return GrassMap.is_encounter_zone(tile)
	if mode == Mode.BEACH:
		return tile.y >= 7 and tile.x >= 10 and tile.x <= 13
	return false

static func pixel_size(mode: Mode) -> Vector2i:
	if mode == Mode.DEFAULT:
		return GrassMap.pixel_size()
	return Vector2i(320, 180)
