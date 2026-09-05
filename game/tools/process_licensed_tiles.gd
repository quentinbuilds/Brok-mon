extends SceneTree
## Build runtime atlases from licensed source sheets. Nearest-neighbor only.

const SOURCE := "res://assets/source"
const TILES := "res://assets/tiles"
const SPRITES := "res://assets/sprites"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TILES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPRITES))

	var jungle_a1 := _require_size("%s/tf_jungle_a1.png" % SOURCE, Vector2i(256, 192))
	var jungle_a2 := _require_size("%s/tf_jungle_a2.png" % SOURCE, Vector2i(256, 192))
	var jungle_b := _require_size("%s/tf_jungle_b.png" % SOURCE, Vector2i(256, 256))
	var jungle_a5 := _require_size("%s/tf_jungle_a5.png" % SOURCE, Vector2i(128, 256))
	var beach_a1 := _require_size("%s/tf_beach_tileA1.png" % SOURCE, Vector2i(768, 576))
	var beach_b := _require_size("%s/tf_beach_tileB.png" % SOURCE, Vector2i(768, 768))

	var jungle_tiles := Image.create(256, 384, false, Image.FORMAT_RGBA8)
	jungle_tiles.fill(Color(0, 0, 0, 0))
	jungle_tiles.blit_rect(jungle_a2, Rect2i(0, 0, 256, 192), Vector2i.ZERO)
	jungle_tiles.blit_rect(jungle_a1, Rect2i(0, 0, 256, 192), Vector2i(0, 192))
	_save(jungle_tiles, "%s/jungle_tiles.png" % TILES)

	var jungle_props := Image.create(256, 512, false, Image.FORMAT_RGBA8)
	jungle_props.fill(Color(0, 0, 0, 0))
	jungle_props.blit_rect(jungle_b, Rect2i(0, 0, 256, 256), Vector2i.ZERO)
	jungle_props.blit_rect(jungle_a5, Rect2i(0, 0, 128, 256), Vector2i(0, 256))
	_save(jungle_props, "%s/jungle_props.png" % SPRITES)

	var beach_tiles := _downsample3(beach_a1)
	if beach_tiles.get_size() != Vector2i(256, 192):
		_fail("beach tiles must downsample to 256x192")
	_save(beach_tiles, "%s/beach_tiles.png" % TILES)

	var beach_props := _downsample3(beach_b)
	if beach_props.get_size() != Vector2i(256, 256):
		_fail("beach props must downsample to 256x256")
	_save(beach_props, "%s/beach_props.png" % SPRITES)

	_require_size("%s/jungle_tiles.png" % TILES, Vector2i(256, 384))
	_require_size("%s/jungle_props.png" % SPRITES, Vector2i(256, 512))
	_require_size("%s/beach_tiles.png" % TILES, Vector2i(256, 192))
	_require_size("%s/beach_props.png" % SPRITES, Vector2i(256, 256))
	quit(0)


func _downsample3(image: Image) -> Image:
	if image.get_width() % 3 != 0 or image.get_height() % 3 != 0:
		_fail("source is not an exact 3x nearest export")
	var out := Image.create(image.get_width() / 3, image.get_height() / 3, false, Image.FORMAT_RGBA8)
	for y in out.get_height():
		for x in out.get_width():
			out.set_pixel(x, y, image.get_pixel(x * 3, y * 3))
	return out


func _require_size(path: String, size: Vector2i) -> Image:
	var image := Image.load_from_file(path)
	if image == null:
		_fail("missing image: %s" % path)
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	if image.get_size() != size:
		_fail("%s must be %sx%s, got %s" % [path, size.x, size.y, image.get_size()])
	return image


func _save(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		_fail("failed to save %s (%s)" % [path, error])


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
