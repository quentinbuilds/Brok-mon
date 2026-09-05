extends TestCase
## Overworld characters: 20-row sheet, named placeable scenes, player is id 0.

const OverworldCharacter := preload("res://world/characters/OverworldCharacter.gd")


func test_sheet_is_160x320() -> void:
	assert_true(FileAccess.file_exists(OverworldCharacter.SHEET_PATH), OverworldCharacter.SHEET_PATH)
	var sheet := load(OverworldCharacter.SHEET_PATH) as Texture2D
	assert_true(sheet != null, "characters_v3.png must import")
	if sheet == null:
		return
	assert_eq(sheet.get_width(), 160)
	assert_eq(sheet.get_height(), 320)
	assert_eq(sheet.get_width(), OverworldCharacter.COLS * OverworldCharacter.CELL)
	assert_eq(sheet.get_height(), OverworldCharacter.ROWS * OverworldCharacter.CELL)


func test_twenty_character_ids() -> void:
	assert_eq(OverworldCharacter.COUNT, 20)
	assert_eq(OverworldCharacter.NAMES.size(), 20)
	assert_eq(OverworldCharacter.ROWS, 20)
	var seen := {}
	for i in OverworldCharacter.COUNT:
		var name: String = OverworldCharacter.NAMES[i]
		assert_false(seen.has(name), "duplicate name %s" % name)
		seen[name] = true
		assert_eq(OverworldCharacter.scene_path(i), "res://world/characters/%s.tscn" % name)


func test_frame0_region() -> void:
	assert_eq(OverworldCharacter.frame_region(0, 0), Rect2(0, 0, 16, 16))
	var ch = await _spawn_character(0)
	if ch == null:
		return
	var atlas: AtlasTexture = ch.atlas_frame(&"idle_front", 0)
	assert_true(atlas != null, "idle_front frame 0")
	if atlas != null:
		assert_eq(atlas.region, Rect2(0, 0, 16, 16))
	ch.queue_free()


func test_first_walk_frame_skips_empty_column() -> void:
	assert_eq(OverworldCharacter.EMPTY_COL, 3)
	assert_eq(OverworldCharacter.FIRST_WALK_COL, 4)
	assert_eq(OverworldCharacter.frame_region(0, OverworldCharacter.FIRST_WALK_COL).position.x, 64.0)
	var ch = await _spawn_character(0)
	if ch == null:
		return
	var atlas: AtlasTexture = ch.atlas_frame(&"walk_front", 0)
	assert_true(atlas != null, "walk_front frame 0")
	if atlas != null:
		assert_eq(atlas.region.position.x, 64.0)
		assert_eq(atlas.region, Rect2(64, 0, 16, 16))
	for anim in OverworldCharacter.ANIM_COLS:
		for col in OverworldCharacter.ANIM_COLS[anim]:
			assert_ne(int(col), OverworldCharacter.EMPTY_COL, "%s uses empty col" % anim)
	ch.queue_free()


func test_character_19_last_frame() -> void:
	assert_eq(OverworldCharacter.frame_region(19, OverworldCharacter.LAST_COL), Rect2(144, 304, 16, 16))
	var ch = await _spawn_character(19)
	if ch == null:
		return
	assert_eq(ch.character_id, 19)
	var atlas: AtlasTexture = ch.atlas_frame(&"walk_side", 1)
	assert_true(atlas != null, "walk_side last frame")
	if atlas != null:
		assert_eq(atlas.region, Rect2(144, 304, 16, 16))
	ch.queue_free()


func test_player_uses_character_id_0() -> void:
	var packed := load("res://world/OverworldState.tscn") as PackedScene
	assert_true(packed != null, "OverworldState.tscn must load")
	if packed == null:
		return
	var ow: Node = packed.instantiate()
	tree.root.add_child(ow)
	await tree.process_frame
	var player := ow.get_node_or_null("Player")
	assert_true(player != null, "Player node kept")
	if player != null:
		assert_eq(player.get("character_id"), 0)
		assert_true(player is AnimatedSprite2D)
	ow.queue_free()


func test_named_scenes_load() -> void:
	for i in OverworldCharacter.COUNT:
		var path := OverworldCharacter.scene_path(i)
		assert_true(FileAccess.file_exists(path), path)
		var packed := load(path) as PackedScene
		assert_true(packed != null, "load %s" % path)
		if packed == null:
			continue
		var ch = packed.instantiate()
		tree.root.add_child(ch)
		await tree.process_frame
		assert_eq(ch.character_id, i, path)
		var atlas: AtlasTexture = ch.atlas_frame(&"idle_front", 0)
		assert_true(atlas != null, "%s idle_front" % path)
		if atlas != null:
			assert_eq(atlas.region, OverworldCharacter.frame_region(i, 0))
		ch.queue_free()


func _spawn_character(id: int):
	var packed := load("res://world/characters/OverworldCharacter.tscn") as PackedScene
	assert_true(packed != null, "OverworldCharacter.tscn must load")
	if packed == null:
		return null
	var ch = packed.instantiate()
	ch.character_id = id
	tree.root.add_child(ch)
	await tree.process_frame
	return ch
