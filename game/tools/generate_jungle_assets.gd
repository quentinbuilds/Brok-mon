extends SceneTree

const CLEAR := Color(0, 0, 0, 0)
const JUNGLE_DEEP := Color("10271f")
const JUNGLE_DARK := Color("173b2b")
const JUNGLE_MID := Color("2f6b3f")
const JUNGLE_LIGHT := Color("67a84f")
const LEAF_GLOW := Color("9bc45a")
const PATH_LIGHT := Color("d4b06a")
const PATH_DARK := Color("a97942")
const EARTH := Color("654331")
const WATER := Color("247ba0")
const WATER_LIGHT := Color("55b8b1")
const STONE := Color("697386")
const STONE_LIGHT := Color("a2a7a2")
const BONE := Color("ead9a3")
const ROOF := Color("8b4a35")
const ROOF_LIGHT := Color("c16b45")
const SKIN := Color("c9855a")
const HAIR := Color("362a2a")
const SHIRT := Color("e3a638")
const SHORTS := Color("31526b")
const BOOT := Color("4b3428")

const TILE_PATH := "res://assets/tiles/jungle_tiles.png"
const PROP_PATH := "res://assets/sprites/jungle_props.png"
const PLAYER_PATH := "res://assets/sprites/player.png"
const PALETTE_PATH := "res://assets/backgrounds/jungle_palette.png"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tiles"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/backgrounds"))

	var outputs := {
		TILE_PATH: _build_tiles(),
		PROP_PATH: _build_props(),
		PLAYER_PATH: _build_player(),
		PALETTE_PATH: _build_palette(),
	}
	for path: String in outputs:
		var error := (outputs[path] as Image).save_png(path)
		if error != OK:
			push_error("Could not save %s (error %d)" % [path, error])
			quit(1)
			return

	if not _validate_outputs():
		quit(1)
		return

	print("Validated jungle atlases: tiles 64x32, props 128x64, player 64x40, palette 16x1")
	quit(0)


func _image(width: int, height: int) -> Image:
	return Image.create(width, height, false, Image.FORMAT_RGBA8)


func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)


func _build_tiles() -> Image:
	var image := _image(64, 32)
	image.fill(CLEAR)
	_draw_lawn(image, Vector2i(0, 0), 0)
	_draw_lawn(image, Vector2i(8, 0), 1)
	_draw_path(image, Vector2i(16, 0), 0)
	_draw_path(image, Vector2i(24, 0), 1)
	_draw_tall_grass(image, Vector2i(32, 0), 0)
	_draw_tall_grass(image, Vector2i(40, 0), 1)
	_draw_water(image, Vector2i(48, 0), 0)
	_draw_water(image, Vector2i(56, 0), 1)

	_draw_tree(image, Vector2i(0, 8), 0)
	_draw_tree(image, Vector2i(8, 8), 1)
	_draw_lawn_path_edge(image, Vector2i(16, 8), true)
	_draw_lawn_path_edge(image, Vector2i(24, 8), false)
	_draw_water_bank(image, Vector2i(32, 8), true)
	_draw_water_bank(image, Vector2i(40, 8), false)
	_draw_stone_ground(image, Vector2i(48, 8), 0)
	_draw_stone_ground(image, Vector2i(56, 8), 1)

	_draw_path(image, Vector2i(0, 16), 2)
	_draw_path(image, Vector2i(8, 16), 3)
	_draw_tall_grass(image, Vector2i(16, 16), 2)
	_draw_lawn(image, Vector2i(24, 16), 2)
	_draw_water(image, Vector2i(32, 16), 2)
	_draw_tree(image, Vector2i(40, 16), 2)
	_draw_hut(image, Vector2i(48, 16), 0)
	_draw_hut(image, Vector2i(56, 16), 1)

	_draw_fossil(image, Vector2i(0, 24), 0)
	_draw_fossil(image, Vector2i(8, 24), 1)
	_draw_mud(image, Vector2i(16, 24), 0)
	_draw_mud(image, Vector2i(24, 24), 1)
	_draw_water_bank(image, Vector2i(32, 24), true)
	_draw_water_bank(image, Vector2i(40, 24), false)
	_draw_lawn(image, Vector2i(48, 24), 3)
	_draw_path(image, Vector2i(56, 24), 4)
	return image


func _draw_lawn(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), JUNGLE_MID)
	if variant == 0:
		_rect(image, Rect2i(at + Vector2i(1, 1), Vector2i(1, 2)), JUNGLE_LIGHT)
		_rect(image, Rect2i(at + Vector2i(5, 5), Vector2i(2, 1)), JUNGLE_DARK)
	elif variant == 1:
		_rect(image, Rect2i(at + Vector2i(2, 6), Vector2i(1, 1)), LEAF_GLOW)
		_rect(image, Rect2i(at + Vector2i(6, 2), Vector2i(1, 2)), JUNGLE_DARK)
	elif variant == 2:
		_rect(image, Rect2i(at + Vector2i(2, 2), Vector2i(2, 1)), JUNGLE_LIGHT)
		_rect(image, Rect2i(at + Vector2i(6, 6), Vector2i(1, 1)), JUNGLE_DEEP)
	else:
		_rect(image, Rect2i(at + Vector2i(1, 5), Vector2i(1, 1)), JUNGLE_DARK)
		_rect(image, Rect2i(at + Vector2i(4, 1), Vector2i(1, 2)), JUNGLE_LIGHT)
		_rect(image, Rect2i(at + Vector2i(6, 4), Vector2i(1, 1)), LEAF_GLOW)


func _draw_path(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), PATH_LIGHT)
	if variant % 2 == 0:
		_rect(image, Rect2i(at + Vector2i(1, 2), Vector2i(2, 1)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(5, 6), Vector2i(1, 1)), EARTH)
	else:
		_rect(image, Rect2i(at + Vector2i(5, 1), Vector2i(2, 1)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(2, 5), Vector2i(1, 2)), EARTH)
	if variant >= 2:
		_rect(image, Rect2i(at + Vector2i(6, 3), Vector2i(1, 1)), PATH_DARK)


func _draw_tall_grass(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), JUNGLE_DARK)
	_rect(image, Rect2i(at + Vector2i(0, 5), Vector2i(8, 3)), JUNGLE_MID)
	_rect(image, Rect2i(at + Vector2i(1, 2), Vector2i(1, 5)), JUNGLE_LIGHT)
	_rect(image, Rect2i(at + Vector2i(3, 1), Vector2i(1, 6)), LEAF_GLOW)
	_rect(image, Rect2i(at + Vector2i(5, 3), Vector2i(1, 4)), JUNGLE_LIGHT)
	_rect(image, Rect2i(at + Vector2i(7, 2), Vector2i(1, 5)), JUNGLE_MID)
	if variant == 1:
		_rect(image, Rect2i(at + Vector2i(3, 1), Vector2i(1, 1)), JUNGLE_LIGHT)
	elif variant == 2:
		_rect(image, Rect2i(at + Vector2i(5, 3), Vector2i(1, 2)), LEAF_GLOW)


func _draw_water(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), WATER)
	if variant == 0:
		_rect(image, Rect2i(at + Vector2i(1, 2), Vector2i(3, 1)), WATER_LIGHT)
		_rect(image, Rect2i(at + Vector2i(5, 6), Vector2i(2, 1)), JUNGLE_DEEP)
	elif variant == 1:
		_rect(image, Rect2i(at + Vector2i(4, 1), Vector2i(3, 1)), WATER_LIGHT)
		_rect(image, Rect2i(at + Vector2i(1, 5), Vector2i(2, 1)), JUNGLE_DEEP)
	else:
		_rect(image, Rect2i(at + Vector2i(1, 3), Vector2i(2, 1)), WATER_LIGHT)
		_rect(image, Rect2i(at + Vector2i(5, 5), Vector2i(2, 1)), WATER_LIGHT)


func _draw_tree(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), JUNGLE_DEEP)
	_rect(image, Rect2i(at + Vector2i(1, 1), Vector2i(6, 5)), JUNGLE_DARK)
	_rect(image, Rect2i(at + Vector2i(2, 0), Vector2i(4, 2)), JUNGLE_MID)
	_rect(image, Rect2i(at + Vector2i(0, 3), Vector2i(3, 3)), JUNGLE_MID)
	_rect(image, Rect2i(at + Vector2i(5, 3), Vector2i(3, 3)), JUNGLE_MID)
	_rect(image, Rect2i(at + Vector2i(2, 2), Vector2i(2, 2)), JUNGLE_LIGHT)
	if variant == 1:
		_rect(image, Rect2i(at + Vector2i(5, 1), Vector2i(1, 2)), LEAF_GLOW)
	elif variant == 2:
		_rect(image, Rect2i(at + Vector2i(1, 4), Vector2i(2, 1)), LEAF_GLOW)


func _draw_lawn_path_edge(image: Image, at: Vector2i, path_on_right: bool) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), JUNGLE_MID)
	if path_on_right:
		_rect(image, Rect2i(at + Vector2i(4, 0), Vector2i(4, 8)), PATH_LIGHT)
		_rect(image, Rect2i(at + Vector2i(3, 0), Vector2i(1, 8)), PATH_DARK)
	else:
		_rect(image, Rect2i(at, Vector2i(4, 8)), PATH_LIGHT)
		_rect(image, Rect2i(at + Vector2i(4, 0), Vector2i(1, 8)), PATH_DARK)


func _draw_water_bank(image: Image, at: Vector2i, water_on_right: bool) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), JUNGLE_DARK)
	if water_on_right:
		_rect(image, Rect2i(at + Vector2i(3, 0), Vector2i(1, 8)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(4, 0), Vector2i(4, 8)), WATER)
		_rect(image, Rect2i(at + Vector2i(5, 2), Vector2i(2, 1)), WATER_LIGHT)
	else:
		_rect(image, Rect2i(at, Vector2i(4, 8)), WATER)
		_rect(image, Rect2i(at + Vector2i(4, 0), Vector2i(1, 8)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(1, 5), Vector2i(2, 1)), WATER_LIGHT)


func _draw_stone_ground(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), EARTH)
	_rect(image, Rect2i(at + Vector2i(1, 1), Vector2i(3, 2)), STONE)
	_rect(image, Rect2i(at + Vector2i(4, 5), Vector2i(3, 2)), STONE)
	if variant == 0:
		_rect(image, Rect2i(at + Vector2i(2, 1), Vector2i(1, 1)), STONE_LIGHT)
	else:
		_rect(image, Rect2i(at + Vector2i(5, 5), Vector2i(1, 1)), STONE_LIGHT)


func _draw_hut(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), EARTH)
	if variant == 0:
		_rect(image, Rect2i(at + Vector2i(0, 1), Vector2i(8, 2)), ROOF)
		_rect(image, Rect2i(at + Vector2i(1, 0), Vector2i(6, 1)), ROOF_LIGHT)
		_rect(image, Rect2i(at + Vector2i(1, 3), Vector2i(6, 5)), PATH_DARK)
	else:
		_rect(image, Rect2i(at + Vector2i(0, 0), Vector2i(8, 2)), ROOF)
		_rect(image, Rect2i(at + Vector2i(1, 2), Vector2i(6, 6)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(3, 4), Vector2i(2, 4)), JUNGLE_DEEP)


func _draw_fossil(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), STONE)
	_rect(image, Rect2i(at + Vector2i(1, 1), Vector2i(6, 6)), STONE_LIGHT)
	if variant == 0:
		_rect(image, Rect2i(at + Vector2i(2, 2), Vector2i(4, 1)), BONE)
		_rect(image, Rect2i(at + Vector2i(2, 3), Vector2i(1, 3)), BONE)
		_rect(image, Rect2i(at + Vector2i(4, 3), Vector2i(2, 1)), BONE)
	else:
		_rect(image, Rect2i(at + Vector2i(2, 2), Vector2i(1, 4)), BONE)
		_rect(image, Rect2i(at + Vector2i(3, 2), Vector2i(3, 1)), BONE)
		_rect(image, Rect2i(at + Vector2i(4, 4), Vector2i(2, 2)), BONE)


func _draw_mud(image: Image, at: Vector2i, variant: int) -> void:
	_rect(image, Rect2i(at, Vector2i(8, 8)), EARTH)
	if variant == 0:
		_rect(image, Rect2i(at + Vector2i(1, 2), Vector2i(4, 2)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(5, 5), Vector2i(2, 1)), JUNGLE_DEEP)
	else:
		_rect(image, Rect2i(at + Vector2i(3, 1), Vector2i(4, 2)), PATH_DARK)
		_rect(image, Rect2i(at + Vector2i(1, 6), Vector2i(2, 1)), JUNGLE_DEEP)


func _build_props() -> Image:
	var image := _image(128, 64)
	image.fill(CLEAR)
	_draw_fern(image)
	_draw_cycad(image)
	_draw_palm(image)
	_draw_rock(image)
	_draw_bone(image)
	_draw_footprint(image)
	_draw_eggshell(image)
	_draw_hut_pieces(image)
	_draw_fossil_shrine(image)
	return image


func _draw_fern(image: Image) -> void:
	_rect(image, Rect2i(7, 7, 2, 9), JUNGLE_DARK)
	_rect(image, Rect2i(2, 6, 5, 2), JUNGLE_MID)
	_rect(image, Rect2i(9, 5, 5, 2), JUNGLE_MID)
	_rect(image, Rect2i(3, 3, 4, 2), JUNGLE_LIGHT)
	_rect(image, Rect2i(9, 2, 3, 2), LEAF_GLOW)
	_rect(image, Rect2i(1, 9, 6, 2), JUNGLE_LIGHT)
	_rect(image, Rect2i(9, 9, 6, 2), JUNGLE_LIGHT)


func _draw_cycad(image: Image) -> void:
	_rect(image, Rect2i(23, 10, 2, 14), EARTH)
	_rect(image, Rect2i(18, 7, 6, 3), JUNGLE_MID)
	_rect(image, Rect2i(25, 6, 6, 3), JUNGLE_MID)
	_rect(image, Rect2i(16, 3, 8, 3), JUNGLE_LIGHT)
	_rect(image, Rect2i(24, 2, 8, 3), LEAF_GLOW)
	_rect(image, Rect2i(20, 0, 3, 8), JUNGLE_MID)
	_rect(image, Rect2i(26, 0, 3, 7), JUNGLE_LIGHT)


func _draw_palm(image: Image) -> void:
	_rect(image, Rect2i(43, 9, 4, 23), EARTH)
	_rect(image, Rect2i(44, 10, 2, 20), PATH_DARK)
	_rect(image, Rect2i(35, 5, 10, 4), JUNGLE_MID)
	_rect(image, Rect2i(47, 4, 9, 4), JUNGLE_MID)
	_rect(image, Rect2i(38, 1, 8, 4), JUNGLE_LIGHT)
	_rect(image, Rect2i(46, 0, 8, 4), LEAF_GLOW)
	_rect(image, Rect2i(33, 9, 10, 3), JUNGLE_LIGHT)
	_rect(image, Rect2i(48, 9, 9, 3), JUNGLE_LIGHT)


func _draw_rock(image: Image) -> void:
	_rect(image, Rect2i(58, 10, 12, 6), JUNGLE_DEEP)
	_rect(image, Rect2i(60, 6, 9, 8), STONE)
	_rect(image, Rect2i(62, 5, 5, 2), STONE_LIGHT)
	_rect(image, Rect2i(59, 9, 2, 3), STONE_LIGHT)


func _draw_bone(image: Image) -> void:
	_rect(image, Rect2i(74, 8, 2, 2), BONE)
	_rect(image, Rect2i(76, 9, 8, 3), BONE)
	_rect(image, Rect2i(83, 7, 2, 2), BONE)
	_rect(image, Rect2i(72, 10, 3, 3), BONE)
	_rect(image, Rect2i(83, 11, 3, 3), BONE)


func _draw_footprint(image: Image) -> void:
	_rect(image, Rect2i(90, 9, 5, 6), EARTH)
	_rect(image, Rect2i(89, 6, 2, 3), EARTH)
	_rect(image, Rect2i(92, 5, 2, 3), EARTH)
	_rect(image, Rect2i(95, 6, 2, 3), EARTH)


func _draw_eggshell(image: Image) -> void:
	_rect(image, Rect2i(101, 8, 11, 7), BONE)
	_rect(image, Rect2i(103, 6, 3, 4), BONE)
	_rect(image, Rect2i(108, 5, 3, 5), BONE)
	_rect(image, Rect2i(104, 8, 6, 4), CLEAR)
	_rect(image, Rect2i(103, 14, 2, 1), STONE_LIGHT)


func _draw_hut_pieces(image: Image) -> void:
	# Roof cap, wall, doorway, and woven side are separate 16x16-aligned pieces.
	_rect(image, Rect2i(0, 35, 32, 5), ROOF)
	_rect(image, Rect2i(4, 32, 24, 4), ROOF_LIGHT)
	_rect(image, Rect2i(2, 40, 28, 8), PATH_DARK)
	_rect(image, Rect2i(4, 48, 12, 16), PATH_DARK)
	_rect(image, Rect2i(16, 48, 12, 16), PATH_DARK)
	_rect(image, Rect2i(18, 50, 8, 14), JUNGLE_DEEP)
	_rect(image, Rect2i(32, 40, 16, 24), PATH_DARK)
	_rect(image, Rect2i(34, 42, 2, 20), ROOF_LIGHT)
	_rect(image, Rect2i(40, 42, 2, 20), ROOF_LIGHT)
	_rect(image, Rect2i(46, 42, 2, 20), ROOF_LIGHT)


func _draw_fossil_shrine(image: Image) -> void:
	_rect(image, Rect2i(56, 56, 32, 8), STONE)
	_rect(image, Rect2i(60, 48, 24, 8), STONE_LIGHT)
	_rect(image, Rect2i(64, 34, 16, 16), STONE)
	_rect(image, Rect2i(66, 36, 12, 12), STONE_LIGHT)
	_rect(image, Rect2i(68, 38, 7, 2), BONE)
	_rect(image, Rect2i(68, 40, 2, 6), BONE)
	_rect(image, Rect2i(72, 41, 4, 2), BONE)
	_rect(image, Rect2i(76, 43, 2, 3), BONE)
	_rect(image, Rect2i(88, 48, 8, 16), JUNGLE_DARK)
	_rect(image, Rect2i(90, 44, 4, 6), JUNGLE_LIGHT)


func _build_player() -> Image:
	var image := _image(64, 40)
	image.fill(CLEAR)
	_draw_player_down(image, Vector2i(0, 0), false)
	_draw_player_up(image, Vector2i(16, 0), false)
	_draw_player_left(image, Vector2i(32, 0), false)
	_draw_player_right(image, Vector2i(48, 0), false)
	_draw_player_down(image, Vector2i(0, 20), true)
	_draw_player_up(image, Vector2i(16, 20), true)
	_draw_player_left(image, Vector2i(32, 20), true)
	_draw_player_right(image, Vector2i(48, 20), true)
	return image


func _draw_player_down(image: Image, at: Vector2i, step: bool) -> void:
	_draw_player_body(image, at)
	_rect(image, Rect2i(at + Vector2i(5, 3), Vector2i(6, 2)), HAIR)
	_rect(image, Rect2i(at + Vector2i(6, 6), Vector2i(1, 1)), JUNGLE_DEEP)
	_rect(image, Rect2i(at + Vector2i(9, 6), Vector2i(1, 1)), JUNGLE_DEEP)
	if step:
		_rect(image, Rect2i(at + Vector2i(4, 17), Vector2i(3, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(10, 16), Vector2i(2, 3)), BOOT)
	else:
		_rect(image, Rect2i(at + Vector2i(5, 17), Vector2i(2, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 17), Vector2i(2, 3)), BOOT)


func _draw_player_up(image: Image, at: Vector2i, step: bool) -> void:
	_draw_player_body(image, at)
	_rect(image, Rect2i(at + Vector2i(4, 3), Vector2i(8, 5)), HAIR)
	_rect(image, Rect2i(at + Vector2i(5, 8), Vector2i(6, 1)), SKIN)
	if step:
		_rect(image, Rect2i(at + Vector2i(4, 16), Vector2i(2, 4)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 17), Vector2i(3, 3)), BOOT)
	else:
		_rect(image, Rect2i(at + Vector2i(5, 17), Vector2i(2, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 17), Vector2i(2, 3)), BOOT)


func _draw_player_left(image: Image, at: Vector2i, step: bool) -> void:
	_draw_player_body(image, at)
	_rect(image, Rect2i(at + Vector2i(4, 3), Vector2i(7, 3)), HAIR)
	_rect(image, Rect2i(at + Vector2i(4, 5), Vector2i(2, 3)), HAIR)
	_rect(image, Rect2i(at + Vector2i(5, 6), Vector2i(1, 1)), JUNGLE_DEEP)
	_rect(image, Rect2i(at + Vector2i(3, 11), Vector2i(2, 4)), SKIN)
	if step:
		_rect(image, Rect2i(at + Vector2i(4, 17), Vector2i(3, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 16), Vector2i(2, 3)), BOOT)
	else:
		_rect(image, Rect2i(at + Vector2i(5, 17), Vector2i(2, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 17), Vector2i(2, 3)), BOOT)


func _draw_player_right(image: Image, at: Vector2i, step: bool) -> void:
	_draw_player_body(image, at)
	_rect(image, Rect2i(at + Vector2i(5, 3), Vector2i(7, 3)), HAIR)
	_rect(image, Rect2i(at + Vector2i(10, 5), Vector2i(2, 3)), HAIR)
	_rect(image, Rect2i(at + Vector2i(10, 6), Vector2i(1, 1)), JUNGLE_DEEP)
	_rect(image, Rect2i(at + Vector2i(11, 11), Vector2i(2, 4)), SKIN)
	if step:
		_rect(image, Rect2i(at + Vector2i(4, 16), Vector2i(2, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 17), Vector2i(3, 3)), BOOT)
	else:
		_rect(image, Rect2i(at + Vector2i(5, 17), Vector2i(2, 3)), BOOT)
		_rect(image, Rect2i(at + Vector2i(9, 17), Vector2i(2, 3)), BOOT)


func _draw_player_body(image: Image, at: Vector2i) -> void:
	_rect(image, Rect2i(at + Vector2i(5, 2), Vector2i(6, 1)), HAIR)
	_rect(image, Rect2i(at + Vector2i(4, 3), Vector2i(8, 5)), SKIN)
	_rect(image, Rect2i(at + Vector2i(5, 8), Vector2i(6, 2)), SKIN)
	_rect(image, Rect2i(at + Vector2i(4, 10), Vector2i(8, 6)), SHIRT)
	_rect(image, Rect2i(at + Vector2i(3, 11), Vector2i(1, 4)), SKIN)
	_rect(image, Rect2i(at + Vector2i(12, 11), Vector2i(1, 4)), SKIN)
	_rect(image, Rect2i(at + Vector2i(5, 15), Vector2i(6, 3)), SHORTS)


func _build_palette() -> Image:
	var image := _image(16, 1)
	var colors: Array[Color] = [
		JUNGLE_DEEP, JUNGLE_DARK, JUNGLE_MID, JUNGLE_LIGHT,
		LEAF_GLOW, PATH_LIGHT, PATH_DARK, EARTH,
		WATER, WATER_LIGHT, STONE, STONE_LIGHT,
		BONE, ROOF, ROOF_LIGHT, SHIRT,
	]
	for x in range(colors.size()):
		image.set_pixel(x, 0, colors[x])
	return image


func _validate_outputs() -> bool:
	var expected := {
		TILE_PATH: Vector2i(64, 32),
		PROP_PATH: Vector2i(128, 64),
		PLAYER_PATH: Vector2i(64, 40),
		PALETTE_PATH: Vector2i(16, 1),
	}
	var valid := true
	for path: String in expected:
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			push_error("Could not load generated atlas: %s" % path)
			valid = false
			continue
		var size := Vector2i(image.get_width(), image.get_height())
		if size != expected[path]:
			push_error("%s must be %s, got %s" % [path, expected[path], size])
			valid = false
		if not _has_opaque_pixel(image):
			push_error("%s contains no visible pixels" % path)
			valid = false
		if path in [PROP_PATH, PLAYER_PATH] and not _has_transparent_pixel(image):
			push_error("%s must preserve transparent atlas space" % path)
			valid = false
	return valid


func _has_opaque_pixel(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a == 1.0:
				return true
	return false


func _has_transparent_pixel(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0:
				return true
	return false
