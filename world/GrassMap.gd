extends RefCounted
## Grassland map data and the queries built on it (PRD §6). Pure data: this script holds no
## node references, so any system can ask it about a tile.
##
## OverworldState paints these glyphs into a TileMapLayer and checks is_walkable() before
## every step. Collision is therefore a glyph lookup, not a physics body -- there are no
## CollisionShapes in the overworld at all.
##
## Glyph -> column in assets/tiles/studio_overworld.png:
##   "." grass 0    ":" tall grass 1    "=" path 2      "T" tree 3
##   "o" rock  4    "~" water      5    "," flowers 6   "#" hedge 7
##
## Editing the map: keep every row exactly WIDTH characters and keep the outer ring solid
## "#" so the player can never walk off the map. tests/test_world.gd asserts both, plus that
## every walkable tile is reachable from START_TILE.

const TILE := 16
const WIDTH := 40
const HEIGHT := 30

## Where a new game (or a stored tile that is no longer walkable) puts the player.
const START_TILE := Vector2i(3, 3)

const ATLAS_COLUMN := {
	".": 0, ":": 1, "=": 2, "T": 3, "o": 4, "~": 5, ",": 6, "#": 7,
}

## Glyphs the player may step onto. Everything else blocks movement.
const WALKABLE := ".:=,"

## Glyphs that count as tall grass. A step onto one of these is a valid encounter roll.
const ENCOUNTER := ":"

const MAP := [
	"########################################",
	"#....,.....TT.........o............T...#",
	"#..================================....#",
	"#..=.........,....................=....#",
	"#..=..:::::...............TTTTT...=....#",
	"#..=..:::::.....oo........T:::T...=....#",
	"#..=..:::::...............T:::T...=....#",
	"#..=..:::::......,........TT.TT...=....#",
	"#..=..:::::.......................=....#",
	"#..================...............=....#",
	"#.................=.,.............=....#",
	"#...TT............=...............=....#",
	"#...TTT...........=.....oo........=....#",
	"#...TT............=...............=....#",
	"#.................=...............=....#",
	"#...~~~~..........=.....,.........=....#",
	"#..~~~~~~.........=...............=....#",
	"#..~~~~~~.........=================....#",
	"#..~~~~~~.........=....................#",
	"#...~~~~..........=....................#",
	"#.................=......:::::.........#",
	"#....o............=......:::::.........#",
	"#.................=......:::::.........#",
	"#.................=......:::::.........#",
	"#.......TT........=.......oo...........#",
	"#......TTTT.......=....................#",
	"#.......TT........=....................#",
	"#....,............=.........,..........#",
	"#............T....................o....#",
	"########################################",
]

## Out-of-bounds reads as hedge so callers never need their own bounds check.
static func glyph(tile: Vector2i) -> String:
	if tile.x < 0 or tile.y < 0 or tile.x >= WIDTH or tile.y >= HEIGHT:
		return "#"
	return MAP[tile.y][tile.x]

static func is_walkable(tile: Vector2i) -> bool:
	return glyph(tile) in WALKABLE

## True when the tile is tall grass. Mirrored by the in_encounter_zone flag on
## EventBus.player_moved so the encounter system never has to reach into this script.
static func is_encounter_zone(tile: Vector2i) -> bool:
	return glyph(tile) in ENCOUNTER

static func atlas_coords(tile: Vector2i) -> Vector2i:
	return Vector2i(ATLAS_COLUMN[glyph(tile)], 0)

## Map size in pixels, used to clamp the camera.
static func pixel_size() -> Vector2i:
	return Vector2i(WIDTH, HEIGHT) * TILE
