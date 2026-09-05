extends RefCounted
## World-owned data for the two alternate overworld presentations.

const GrassMap := preload("res://world/GrassMap.gd")

enum Mode { DEFAULT, INTERIOR, BEACH }

const TILE := 16
const DEFAULT_DOOR := Vector2i(30, 10)
const DEFAULT_RETURN := Vector2i(30, 11)
const INTERIOR_SPAWN := Vector2i(10, 9)
const INTERIOR_EXIT := Vector2i(10, 10)
## Solid body of the beach house, matching where its sprite is drawn: pinned at tile (14, 3),
## three tiles wide, with its door at the bottom of the middle column on BEACH_DOOR. The beach
## mask is traced off the background art and knows nothing about props placed on top of it, so
## without this the player walks through the house here too.
const BEACH_HOUSE_FOOTPRINT := Rect2i(14, 3, 3, 3)
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
			# The door is carved back out of the house body so it can be stepped on.
			return tile == DEFAULT_DOOR or GrassMap.is_walkable(tile)
		Mode.INTERIOR:
			return tile.x >= 6 and tile.x <= 13 and tile.y >= 3 and tile.y <= 10 \
				and not INTERIOR_BLOCKED.has(tile)
		Mode.BEACH:
			if BEACH_HOUSE_FOOTPRINT.has_point(tile) and tile != BEACH_DOOR:
				return false
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

## Which map the player is standing on, published so the battle can build its backdrop out of
## the terrain the encounter actually happened in. This is map data, not a node reference:
## GrassMap's header already invites any system to ask it about a tile, and battle/ asking here
## is the same thing one level up. OverworldState keeps it current.
static var active_mode: Mode = Mode.DEFAULT

## Sky behind the battle, per biome.
const BATTLE_SKY := {
	Mode.DEFAULT: Color("74b8dd"),
	Mode.BEACH: Color("8fd4ea"),
	Mode.INTERIOR: Color("2f2118"),
}


static func battle_sky() -> Color:
	return BATTLE_SKY.get(active_mode, BATTLE_SKY[Mode.DEFAULT])


## Glyph the battle tiles its floor with: whatever the player last stood on, so a fight started
## in tall grass is fought in tall grass. OverworldState publishes it, because a static function
## here cannot reach the GameData autoload to look the tile up itself.
static var active_ground := "."


static func battle_ground_glyph() -> String:
	return active_ground


## Called by OverworldState as the player moves. Sand on the beach and indoors, otherwise
## whatever tile is underfoot, falling back to plain grass.
static func publish_ground(tile: Vector2i) -> void:
	if active_mode != Mode.DEFAULT:
		active_ground = "="
		return
	var here := GrassMap.glyph(tile)
	active_ground = here if GrassMap.WALKABLE.contains(here) else "."


## Size of a map in tiles, for anything that needs to frame the whole thing.
static func map_tiles(mode: Mode) -> Vector2i:
	match mode:
		Mode.BEACH:
			return Vector2i(BEACH_WIDTH, BEACH_HEIGHT)
		Mode.INTERIOR:
			return Vector2i(14, 11)
	return Vector2i(GrassMap.WIDTH, GrassMap.HEIGHT)


## Topmost pixel row the camera may show. Non-zero only on the beach, whose source image
## carries the Studio palette swatch bar across its first few rows.
static func camera_top(mode: Mode) -> int:
	return BEACH_TOP_MARGIN if mode == Mode.BEACH else 0
