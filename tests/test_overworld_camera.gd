extends TestCase
## Larger forest map plus a Camera2D that stays centered on the player.

const Catalog := preload("res://world/tiles/ForestTileCatalog.gd")

const OLD_CHUNK := Vector2i(13, 8)
const SPRITE := 16
const VIEW := Vector2(200, 120)
const FAR_GRASS := Vector2(300, 80)


func test_demo_map_is_four_times_larger() -> void:
	var packed := load(Catalog.MAP_PATH) as PackedScene
	assert_true(packed != null, "ForestMap.tscn must load")
	if packed == null:
		return
	var map: Node = packed.instantiate()
	tree.root.add_child(map)
	await tree.process_frame
	var layer := map as TileMapLayer
	assert_true(layer != null, "ForestMap root is TileMapLayer")
	if layer == null:
		map.queue_free()
		return
	var used: Rect2i = layer.get_used_rect()
	assert_true(used.size.x >= OLD_CHUNK.x * 4, "width ~4x old demo")
	assert_true(used.size.y >= OLD_CHUNK.y * 4, "height ~4x old demo")
	var px: Rect2 = layer.pixel_rect()
	assert_true(px.size.x >= float(OLD_CHUNK.x * 4 * Catalog.TILE_SIZE), "pixel width")
	assert_true(px.size.y >= float(OLD_CHUNK.y * 4 * Catalog.TILE_SIZE), "pixel height")
	assert_true(px.size.x > VIEW.x, "wider than viewport")
	assert_true(px.size.y > VIEW.y, "taller than viewport")
	map.queue_free()


func test_camera_exists_and_is_current() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	var cam := _camera(ow)
	assert_true(cam != null, "Camera2D under Player")
	if cam != null:
		assert_true(cam.enabled, "camera enabled")
		assert_true(cam.is_current(), "camera is current")
		assert_false(cam.position_smoothing_enabled, "no smoothing")
	ow.queue_free()


func test_camera_centers_on_player() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	var player: Node2D = ow.get_node("Player")
	var cam := _camera(ow)
	assert_true(cam != null, "Camera2D under Player")
	if cam == null:
		ow.queue_free()
		return
	player.position = FAR_GRASS
	await tree.process_frame
	var visual_center: Vector2 = player.global_position + Vector2(SPRITE / 2, SPRITE / 2)
	var cam_center: Vector2 = cam.global_position + cam.offset
	assert_eq(cam_center, visual_center, "camera + offset is sprite center")
	assert_eq(cam.offset, Vector2(SPRITE / 2, SPRITE / 2))
	ow.queue_free()


func test_player_can_stand_outside_old_viewport() -> void:
	var ow = await _spawn_overworld()
	if ow == null:
		return
	var bounds: Rect2 = ow.walk_bounds()
	assert_true(bounds.size.x > VIEW.x, "walk width > 200")
	assert_true(bounds.size.y > VIEW.y, "walk height > 120")
	assert_true(bounds.has_point(FAR_GRASS), "300,80 is inside map")
	assert_true(ow.can_walk(FAR_GRASS), "300,80 is grass")
	assert_true(ow.try_move(FAR_GRASS), "move beyond 200x120")
	assert_eq(ow.get_node("Player").position, FAR_GRASS)
	ow.queue_free()


func _camera(ow: Node) -> Camera2D:
	var node := ow.get_node_or_null("Player/Camera2D")
	return node as Camera2D


func _spawn_overworld():
	var packed := load("res://world/OverworldState.tscn") as PackedScene
	assert_true(packed != null, "OverworldState.tscn must load")
	if packed == null:
		return null
	var ow: Node = packed.instantiate()
	tree.root.add_child(ow)
	await tree.process_frame
	return ow
