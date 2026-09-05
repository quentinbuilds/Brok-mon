extends SceneTree
## Generates the original overworld art: assets/tiles/overworld.png (8x8 tile atlas,
## one row of 8 tiles) and assets/sprites/player.png (8 frames of 8x12).
##
## Run:  Summer --headless --disable-crash-handler --path . -s res://world/tools/gen_art.gd
## Then: Summer --headless --path . --import        (so the PNGs become Texture2D)
##
## Art is code so the palette stays consistent and Person 6 can retune it in one place.
## Four-shade palette in the spirit of the original handheld LCD.

const TILE := 8
const PLAYER_W := 8
const PLAYER_H := 12

const PAL := {
	"0": Color8(15, 56, 15),    # darkest  - outlines, tree canopy shadow
	"1": Color8(48, 98, 48),    # dark     - foliage, water, player body
	"2": Color8(139, 172, 15),  # light    - grass
	"3": Color8(155, 188, 15),  # lightest - path, highlights
}

## Atlas column order. GrassMap.gd maps map characters to these columns.
const TILES := [
	# 0 grass
	["22222222",
	 "22322232",
	 "22222222",
	 "23222322",
	 "22222222",
	 "22222222",
	 "32223222",
	 "22222222"],
	# 1 tall grass (encounter zone) - deliberately high contrast against plain grass
	["22222222",
	 "21222122",
	 "11121112",
	 "21112111",
	 "22222222",
	 "22122212",
	 "21112111",
	 "12111121"],
	# 2 path
	["33333333",
	 "33233333",
	 "33333333",
	 "32333323",
	 "33333333",
	 "33333233",
	 "33333333",
	 "32333333"],
	# 3 tree (blocked)
	["22000022",
	 "20111102",
	 "01110110",
	 "01011110",
	 "01111010",
	 "20111102",
	 "22200222",
	 "22200222"],
	# 4 rock (blocked)
	["22222222",
	 "22000022",
	 "20111102",
	 "01131110",
	 "01111110",
	 "01111110",
	 "20000002",
	 "22222222"],
	# 5 water (blocked)
	["11111111",
	 "11221111",
	 "11111122",
	 "11111111",
	 "12211111",
	 "11111221",
	 "11111111",
	 "21111111"],
	# 6 flowers (walkable decoration)
	["22222222",
	 "22232222",
	 "22303222",
	 "22232222",
	 "22212222",
	 "22222222",
	 "32222232",
	 "22222222"],
	# 7 hedge (blocked) - map border
	["20020022",
	 "01101102",
	 "01111110",
	 "20111102",
	 "20011002",
	 "01111110",
	 "01111110",
	 "20000002"],
]

## "." is transparent. Frame order must stay DOWN, UP, LEFT, RIGHT with 2 frames each,
## because Player.gd indexes the sheet as dir * 2 + step.
##
## The player is deliberately the lightest thing on screen inside a hard darkest-shade
## outline: light shirt reads against grass, the outline reads against the pale path, so the
## PRD's "player always visible" holds on every tile in the map.
const PLAYER_FRAMES := [
	# DOWN idle / step
	["..0000..", ".000000.", ".033330.", ".003300.", ".033330.", "..0000..",
	 ".033330.", "03333330", "03333330", ".011110.", ".010010.", ".00..00."],
	["..0000..", ".000000.", ".033330.", ".003300.", ".033330.", "..0000..",
	 ".033330.", "03333330", "03333330", ".011110.", "..0110..", "..0000.."],
	# UP idle / step
	["..0000..", ".000000.", ".000000.", ".000000.", ".000000.", "..0000..",
	 ".033330.", "03333330", "03333330", ".011110.", ".010010.", ".00..00."],
	["..0000..", ".000000.", ".000000.", ".000000.", ".000000.", "..0000..",
	 ".033330.", "03333330", "03333330", ".011110.", "..0110..", "..0000.."],
	# LEFT idle / step (RIGHT is mirrored from these at build time)
	["..0000..", ".00000..", ".03300..", ".00330..", ".03330..", "..0000..",
	 "..0330..", ".033330.", ".033330.", "..0110..", "..0110..", "..00.0.."],
	["..0000..", ".00000..", ".03300..", ".00330..", ".03330..", "..0000..",
	 "..0330..", ".033330.", ".033330.", "..0110..", "..0110..", "..0.00.."],
]

func _initialize() -> void:
	var ok := true
	ok = _write_tiles() and ok
	ok = _write_player() and ok
	quit(0 if ok else 1)

func _write_tiles() -> bool:
	if not _validate(TILES, TILE, TILE, "tile"):
		return false
	var img := Image.create(TILE * TILES.size(), TILE, false, Image.FORMAT_RGBA8)
	for i in TILES.size():
		_blit(img, TILES[i], i * TILE, 0, false)
	return _save(img, "res://assets/tiles/overworld.png")

func _write_player() -> bool:
	if not _validate(PLAYER_FRAMES, PLAYER_W, PLAYER_H, "player frame"):
		return false
	# 4 directions x 2 frames; RIGHT mirrors LEFT so the two profiles cannot drift apart.
	var img := Image.create(PLAYER_W * 8, PLAYER_H, false, Image.FORMAT_RGBA8)
	for i in 6:
		_blit(img, PLAYER_FRAMES[i], i * PLAYER_W, 0, false)
	_blit(img, PLAYER_FRAMES[4], 6 * PLAYER_W, 0, true)
	_blit(img, PLAYER_FRAMES[5], 7 * PLAYER_W, 0, true)
	return _save(img, "res://assets/sprites/player.png")

func _blit(img: Image, rows: Array, ox: int, oy: int, mirror: bool) -> void:
	var w: int = rows[0].length()
	for y in rows.size():
		var row: String = rows[y]
		for x in w:
			var ch := row[w - 1 - x] if mirror else row[x]
			if ch == ".":
				continue
			img.set_pixel(ox + x, oy + y, PAL[ch])

## Catches a mistyped row before it silently becomes garbled art.
func _validate(frames: Array, w: int, h: int, label: String) -> bool:
	var ok := true
	for i in frames.size():
		var rows: Array = frames[i]
		if rows.size() != h:
			push_error("%s %d has %d rows, expected %d" % [label, i, rows.size(), h])
			ok = false
		for y in rows.size():
			if rows[y].length() != w:
				push_error("%s %d row %d is %d wide, expected %d" % [label, i, y, rows[y].length(), w])
				ok = false
	return ok

func _save(img: Image, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("could not write %s (%d)" % [path, err])
		return false
	print("wrote %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	return true
