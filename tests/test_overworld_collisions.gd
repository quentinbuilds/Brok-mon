extends TestCase
## Water tiles and NPC rects block walking. player_moved still fires only on tile change.

const Catalog := preload("res://world/tiles/ForestTileCatalog.gd")
const OverworldCharacter := preload("res://world/characters/OverworldCharacter.gd")

const SPRITE := 16
const GRASS_POS := Vector2(96, 16)
const POND_POS := Vector2(128, 80)


func test_water_tile_ids_are_blocked() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	var fmap = ow.get_node("ForestMap")
	var cell := Vector2i(6, 1)
	var pos := Vector2(cell * Catalog.TILE_SIZE)
	assert_true(ow.can_walk(pos), "grass cell starts walkable")
	for tile_name in Catalog.WATER_TILES:
		assert_true(Catalog.is_water(tile_name), tile_name)
		fmap.paint_named(cell, tile_name)
		assert_true(fmap.is_water_cell(cell), tile_name)
		assert_false(ow.can_walk(pos), "water id %s blocks" % tile_name)
		assert_true(ow.is_blocked(Rect2(pos, Vector2(SPRITE, SPRITE))), tile_name)
	fmap.paint_named(cell, "grass")
	assert_true(ow.can_walk(pos), "grass after water paint")
	ow.free()


func test_dummy_npc_rect_blocks() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	assert_true(ow.can_walk(GRASS_POS), "empty grass")
	var dummy := Node2D.new()
	dummy.position = GRASS_POS
	dummy.add_to_group(OverworldCharacter.NPC_GROUP)
	ow.add_child(dummy)
	assert_false(ow.can_walk(GRASS_POS), "dummy npc blocks")
	assert_true(ow.is_blocked(Rect2(GRASS_POS, Vector2(SPRITE, SPRITE))))
	assert_true(ow.can_walk(GRASS_POS + Vector2(-SPRITE, 0)), "adjacent is free")
	dummy.free()
	assert_true(ow.can_walk(GRASS_POS), "grass after dummy removed")
	ow.free()


func test_empty_grass_does_not_block() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	assert_true(ow.can_walk(GRASS_POS))
	assert_false(ow.is_blocked(Rect2(GRASS_POS, Vector2(SPRITE, SPRITE))))
	var fmap = ow.get_node("ForestMap")
	var empty_cell := Vector2i(6, 3)
	var empty_pos := Vector2(empty_cell * Catalog.TILE_SIZE)
	fmap.erase_cell(empty_cell)
	assert_false(fmap.is_water_cell(empty_cell))
	assert_true(ow.can_walk(empty_pos), "erased cell does not block")
	ow.free()


func test_player_moved_emits_only_on_tile_change() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	var data: Node = tree.root.get_node("GameData")
	var bus: Node = tree.root.get_node("EventBus")
	var count := [0]
	var last_tile := [Vector2i.ZERO]
	var cb := func(tile: Vector2i, _zone: bool):
		count[0] += 1
		last_tile[0] = tile
	bus.player_moved.connect(cb)
	assert_true(ow.can_walk(GRASS_POS), "setup grass")
	ow.get_node("Player").position = GRASS_POS
	data.player_tile = Vector2i((GRASS_POS / 8.0).floor())
	assert_true(ow.try_move(GRASS_POS + Vector2(3, 0)), "same movement tile")
	assert_eq(count[0], 0, "no emit when tile unchanged")
	assert_true(ow.try_move(GRASS_POS + Vector2(8, 0)), "cross 8px tile")
	assert_eq(count[0], 1, "emit once on tile change")
	assert_eq(last_tile[0], Vector2i(13, 2))
	var before: Vector2 = ow.get_node("Player").position
	assert_false(ow.try_move(POND_POS), "water rejects move")
	assert_eq(ow.get_node("Player").position, before)
	assert_eq(count[0], 1, "blocked move does not emit")
	bus.player_moved.disconnect(cb)
	ow.free()


func test_player_is_not_an_npc() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	var player: Node = ow.get_node("Player")
	assert_false(player.is_in_group(OverworldCharacter.NPC_GROUP))
	assert_eq(player.get("is_npc"), false)
	var elder: Node = ow.get_node("Characters/Elder")
	assert_true(elder.is_in_group(OverworldCharacter.NPC_GROUP))
	assert_false(ow.can_walk(elder.position), "placed elder is solid")
	ow.free()


func test_demo_pond_blocks_footprint() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	assert_false(ow.can_walk(POND_POS), "pond cell")
	assert_false(ow.can_walk(Vector2(120, 80)), "16x16 footprint overlapping pond")
	assert_true(ow.can_walk(Vector2(112, 80)), "adjacent grass west of pond")
	ow.free()


func _spawn_overworld():
	var packed := load("res://world/OverworldState.tscn") as PackedScene
	assert_true(packed != null, "OverworldState.tscn must load")
	if packed == null:
		return null
	var ow: Node = packed.instantiate()
	tree.root.add_child(ow)
	await tree.process_frame
	return ow
