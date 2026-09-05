extends SceneTree
## Deterministically turns the large Summer Studio compositions into compact runtime
## atlases. Source images remain untouched; rerun this script whenever they are replaced.

const TILE_SOURCE := "res://assets/studio/overworld_tileset.png"
const TRAINER_SOURCE := "res://assets/studio/trainer_walk.png"
const TILE_OUTPUT := "res://assets/tiles/studio_overworld.png"
const TRAINER_OUTPUT := "res://assets/sprites/studio_trainer.png"

const TILE_SIZE := 16
const TRAINER_SIZE := Vector2i(16, 20)

func _initialize() -> void:
	var tile_source := Image.load_from_file(TILE_SOURCE)
	var trainer_source := Image.load_from_file(TRAINER_SOURCE)
	if tile_source == null or tile_source.is_empty():
		_fail("Could not load %s" % TILE_SOURCE)
		return
	if trainer_source == null or trainer_source.is_empty():
		_fail("Could not load %s" % TRAINER_SOURCE)
		return

	var tiles := Image.create(TILE_SIZE * 8, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var regions := [
		Rect2i(352, 96, 64, 64),  # grass
		Rect2i(512, 192, 64, 64), # tall grass
		Rect2i(288, 0, 48, 64),   # path
		Rect2i(48, 32, 80, 104),  # tree
		Rect2i(704, 640, 64, 64), # rock
		Rect2i(576, 0, 64, 64),   # water
		Rect2i(352, 96, 64, 64),  # flower base (decorated below)
		Rect2i(144, 40, 80, 80),  # hedge
	]
	for i in regions.size():
		var tile := tile_source.get_region(regions[i])
		tile.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
		# The Studio composition leaves transparency around isolated trees. Since the
		# runtime map uses one layer, ground-fill those pixels before atlas packing.
		if i in [3, 4, 7]:
			var ground := tile_source.get_region(regions[0])
			ground.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
			ground.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i.ZERO)
			tile = ground
		tiles.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(i * TILE_SIZE, 0))
	# A tiny palette-matched flower cluster keeps the map's decorative glyph distinct.
	for p in [Vector2i(4, 6), Vector2i(11, 10), Vector2i(7, 13)]:
		tiles.set_pixel(6 * TILE_SIZE + p.x, p.y, Color("f8e8a4"))
		tiles.set_pixel(6 * TILE_SIZE + p.x + 1, p.y, Color("f09068"))

	if tiles.save_png(TILE_OUTPUT) != OK:
		_fail("Could not save %s" % TILE_OUTPUT)
		return

	var trainer := Image.create(TRAINER_SIZE.x * 8, TRAINER_SIZE.y, false, Image.FORMAT_RGBA8)
	trainer.fill(Color.TRANSPARENT)
	# down 0/1, up 0/1, left 0/1 (mirrored at runtime), right 0/1
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 0), Vector2i(3, 0)]
	var cell_size := Vector2i(trainer_source.get_width() / 4, trainer_source.get_height() / 4)
	for i in cells.size():
		var origin: Vector2i = cells[i] * cell_size
		var source_frame := trainer_source.get_region(Rect2i(origin, cell_size))
		_remove_white_background(source_frame)
		var bounds := source_frame.get_used_rect()
		if bounds.size == Vector2i.ZERO:
			_fail("Trainer frame %d has no visible pixels" % i)
			return
		var cropped := source_frame.get_region(bounds)
		var scale := minf(14.0 / cropped.get_width(), 19.0 / cropped.get_height())
		var target := Vector2i(maxi(1, roundi(cropped.get_width() * scale)), maxi(1, roundi(cropped.get_height() * scale)))
		cropped.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
		var dest := Vector2i(i * TRAINER_SIZE.x + (TRAINER_SIZE.x - target.x) / 2, TRAINER_SIZE.y - target.y)
		trainer.blend_rect(cropped, Rect2i(Vector2i.ZERO, target), dest)

	if trainer.save_png(TRAINER_OUTPUT) != OK:
		_fail("Could not save %s" % TRAINER_OUTPUT)
		return
	print("Prepared Studio runtime atlases: ", TILE_OUTPUT, " and ", TRAINER_OUTPUT)
	quit()

func _remove_white_background(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.r > 0.965 and color.g > 0.965 and color.b > 0.965:
				color.a = 0.0
				image.set_pixel(x, y, color)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
