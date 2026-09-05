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

## Beach walkability, one character per 16 px tile of the scaled background.
##   "." dry land the player may stand on    "~" sea, wet sand, pond or scenery
##
## The beach is presentation art, not a tileset, so there are no glyphs to query the way
## GrassMap has. This mask was traced off assets/backgrounds/beach_map.png at the scale the
## sprite actually renders (source pixel = tile * 64) and then reduced to the single region
## reachable from BEACH_RETURN, so the palm islet on the left stays scenery instead of a
## place the player can be stranded. tests/test_collision.gd re-checks both properties.
##
## Row 0 is the Studio palette swatch bar baked into the top of the source image. It is never
## walkable and camera_top() keeps it off screen.
const BEACH_WIDTH := 20
const BEACH_HEIGHT := 11

const BEACH_MAP := [
	"~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~..~......~~~",
	"~~~~~............~~~",
	"~~~~~............~~~",
	"~~~~~........~~.~~~~",
	"~~~~~~~~.........~~~",
	"~~~~~~~~.........~~~",
	"~~~~~~~~~~.......~~~",
	"~~~~~~~~~~........~.",
	"~~~~~~~~~~..........",
	"~~~~~~~~~~~.~~~~~~~.",
]

## Screen rows hidden behind the camera's top limit, so the swatch bar never shows.
const BEACH_TOP_MARGIN := 16

static func is_walkable(mode: Mode, tile: Vector2i) -> bool:
	match mode:
		Mode.DEFAULT:
			var doorway := tile.x == DEFAULT_DOOR.x and tile.y >= DEFAULT_DOOR.y and tile.y <= 12
			return doorway or GrassMap.is_walkable(tile)
		Mode.INTERIOR:
			return tile.x >= 6 and tile.x <= 13 and tile.y >= 3 and tile.y <= 10 \
				and not INTERIOR_BLOCKED.has(tile)
		Mode.BEACH:
			return beach_glyph(tile) == "."
	return false


## Out-of-bounds reads as sea, so callers never need their own bounds check.
static func beach_glyph(tile: Vector2i) -> String:
	if tile.x < 0 or tile.y < 0 or tile.x >= BEACH_WIDTH or tile.y >= BEACH_HEIGHT:
		return "~"
	return BEACH_MAP[tile.y][tile.x]

## Encounters only ever roll on a tile the player can stand on, so the zone is intersected
## with the walk mask rather than trusted on its own.
static func is_encounter_zone(mode: Mode, tile: Vector2i) -> bool:
	if mode == Mode.DEFAULT:
		return GrassMap.is_encounter_zone(tile)
	if mode == Mode.BEACH:
		return tile.y >= 7 and tile.x >= 10 and tile.x <= 13 and is_walkable(mode, tile)
	return false

static func pixel_size(mode: Mode) -> Vector2i:
	if mode == Mode.DEFAULT:
		return GrassMap.pixel_size()
	return Vector2i(320, 180)

## Topmost pixel row the camera may show. Non-zero only on the beach, whose source image
## carries the Studio palette swatch bar across its first few rows.
static func camera_top(mode: Mode) -> int:
	return BEACH_TOP_MARGIN if mode == Mode.BEACH else 0
