extends SceneTree
## Generates the five original grassland creature sprites into creatures/sprites/.
##
## Run:  Summer --headless --disable-crash-handler --path . -s res://creatures/tools/gen_creature_art.gd
## Then: Summer --headless --path . --import
##
## 16x16 in the same four shades as the overworld, because the game is monochrome-green by
## design: a creature is told apart by silhouette and shading, not by hue. Person 4 can
## scale these 2x for the battle screen; Person 6 owns any final restyle.

const SIZE := 16

const PAL := {
	"0": Color8(15, 56, 15),    # darkest  - outline
	"1": Color8(48, 98, 48),    # dark     - shadow / underside
	"2": Color8(139, 172, 15),  # light    - body
	"3": Color8(155, 188, 15),  # lightest - highlight
}

## Silhouettes are deliberately bold and different from each other: round, angular,
## pointed-eared, finned, spiky.
const CREATURES := {
	"mossbug": [
		"................",
		".......00.......",
		"......0330......",
		".....03330......",
		"....000000000...",
		"...01111111110..",
		"..011333311110..",
		".01133113311110.",
		".01133113311110.",
		".01113311111110.",
		".01111111111110.",
		"..011111111110..",
		"...0000000000...",
		"..0..0....0..0..",
		".0...0....0...0.",
		"................",
	],
	"emberfox": [
		"................",
		"..0..........0..",
		".030........030.",
		".0330......0330.",
		".03330....03330.",
		"..0333300333330.",
		"...033333333330.",
		"..03303333033330",
		"..03303333033330",
		"..0333333333330.",
		"...03300003330..",
		"....033333300...",
		".....0333300....",
		"......03300.....",
		".....00..00.....",
		"................",
	],
	"aquafin": [
		"................",
		"................",
		".........0......",
		"........030....0",
		"....00000330..00",
		"...0111133330.0.",
		"..011111333303..",
		".01130111133330.",
		".01130111133330.",
		"..011111333303..",
		"...0111133330.0.",
		"....00000330..00",
		"........030....0",
		".........0......",
		"................",
		"................",
	],
	# Angular and flat-topped so it never reads as a blob: rock is the only hard-edged
	# silhouette in the pool.
	"pebblit": [
		"................",
		"................",
		"..000000000000..",
		"..033333333330..",
		"..033333333330..",
		"..030033300330..",
		"..030033300330..",
		"..033333333330..",
		"..022222222220..",
		"..022222222220..",
		"..022222222220..",
		"..022222222220..",
		"..000000000000..",
		"...00......00...",
		"................",
		"................",
	],
	# A four-legged body with the tail swept up and to the right, so it cannot be confused
	# with emberfox's symmetric big-eared head.
	"voltkit": [
		"................",
		"..00........000.",
		".0330......03330",
		".03330....0330..",
		"..0333000330....",
		"..033303330.....",
		".0330303330.....",
		".03333333330....",
		".033333333330...",
		"..03333333330...",
		"..03333333330...",
		"..0330..03330...",
		"..0330..03330...",
		"..000....000....",
		"................",
		"................",
	],
}

func _initialize() -> void:
	var ok := true
	var names := CREATURES.keys()
	names.sort()
	for name in names:
		ok = _write(name, CREATURES[name]) and ok
	if ok:
		_write_review_sheet(names)
	quit(0 if ok else 1)

func _write(name: String, rows: Array) -> bool:
	if not _validate(name, rows):
		return false
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	_blit(img, rows, 0, 0)
	var path := "res://creatures/sprites/%s.png" % name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	if img.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("could not write %s" % path)
		return false
	print("wrote %s" % path)
	return true

## Contact sheet at 6x outside the project, purely so the art can be eyeballed.
func _write_review_sheet(names: Array) -> void:
	var k := 6
	var sheet := Image.create(SIZE * names.size() * k, SIZE * k, false, Image.FORMAT_RGBA8)
	sheet.fill(Color8(60, 60, 60))
	for i in names.size():
		var rows: Array = CREATURES[names[i]]
		for y in SIZE:
			for x in SIZE:
				var ch: String = rows[y][x]
				if ch == ".":
					continue
				for dy in k:
					for dx in k:
						sheet.set_pixel((i * SIZE + x) * k + dx, y * k + dy, PAL[ch])
	sheet.save_png("/tmp/creature_review.png")
	print("review sheet /tmp/creature_review.png order=%s" % str(names))

func _blit(img: Image, rows: Array, ox: int, oy: int) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			img.set_pixel(ox + x, oy + y, PAL[ch])

func _validate(name: String, rows: Array) -> bool:
	var ok := true
	if rows.size() != SIZE:
		push_error("%s has %d rows, expected %d" % [name, rows.size(), SIZE])
		ok = false
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != SIZE:
			push_error("%s row %d is %d wide, expected %d" % [name, y, row.length(), SIZE])
			ok = false
		for x in row.length():
			if row[x] != "." and not PAL.has(row[x]):
				push_error("%s row %d has bad char '%s'" % [name, y, row[x]])
				ok = false
	return ok
