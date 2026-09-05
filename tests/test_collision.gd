extends TestCase
## Terrain masking on the beach, and NPCs as solid tiles.
##
## The overworld has no physics bodies by design (docs/ARCHITECTURE.md), so both are
## walkability questions rather than collider questions.

const MapCycle := preload("res://world/MapCycle.gd")
const GrassMap := preload("res://world/GrassMap.gd")


func _overworld() -> OverworldState:
	var world := load("res://world/OverworldState.tscn").instantiate() as OverworldState
	tree.root.add_child(world)
	GameData.player_tile = GrassMap.START_TILE
	world.enter({})
	return world


## Every tile the mask calls land, reachable from where the player arrives.
func _reachable_beach() -> Dictionary:
	var seen := {MapCycle.BEACH_RETURN: true}
	var queue: Array[Vector2i] = [MapCycle.BEACH_RETURN]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = tile + step
			if seen.has(next) or not MapCycle.is_walkable(MapCycle.Mode.BEACH, next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_beach_sea_is_not_walkable() -> void:
	for wet in [Vector2i(0, 5), Vector2i(2, 5), Vector2i(19, 4), Vector2i(9, 8), Vector2i(4, 2)]:
		assert_false(MapCycle.is_walkable(MapCycle.Mode.BEACH, wet), "sea at %s" % wet)


func test_beach_sand_is_walkable() -> void:
	for dry in [MapCycle.BEACH_RETURN, MapCycle.BEACH_DOOR, Vector2i(12, 3), Vector2i(15, 9)]:
		assert_true(MapCycle.is_walkable(MapCycle.Mode.BEACH, dry), "sand at %s" % dry)


func test_beach_mask_is_rectangular_and_sealed() -> void:
	assert_eq(MapCycle.BEACH_MAP.size(), MapCycle.BEACH_HEIGHT)
	for row in MapCycle.BEACH_MAP:
		assert_eq(String(row).length(), MapCycle.BEACH_WIDTH, "row width")
	# The swatch bar row and everything off the edge read as sea.
	for x in MapCycle.BEACH_WIDTH:
		assert_false(MapCycle.is_walkable(MapCycle.Mode.BEACH, Vector2i(x, 0)), "swatch row")
	assert_false(MapCycle.is_walkable(MapCycle.Mode.BEACH, Vector2i(-1, 5)), "off left")
	assert_false(MapCycle.is_walkable(MapCycle.Mode.BEACH, Vector2i(MapCycle.BEACH_WIDTH, 5)))
	assert_false(MapCycle.is_walkable(MapCycle.Mode.BEACH, Vector2i(5, MapCycle.BEACH_HEIGHT)))


## No sand the player can see but never stand on, and nowhere to be stranded.
func test_every_walkable_beach_tile_is_reachable() -> void:
	var seen := _reachable_beach()
	for y in MapCycle.BEACH_HEIGHT:
		for x in MapCycle.BEACH_WIDTH:
			var tile := Vector2i(x, y)
			if MapCycle.is_walkable(MapCycle.Mode.BEACH, tile):
				assert_true(seen.has(tile), "stranded land at %s" % tile)
	assert_true(seen.has(MapCycle.BEACH_DOOR), "door reachable")


func test_beach_encounter_zone_is_dry_land() -> void:
	var found := false
	for y in MapCycle.BEACH_HEIGHT:
		for x in MapCycle.BEACH_WIDTH:
			var tile := Vector2i(x, y)
			if not MapCycle.is_encounter_zone(MapCycle.Mode.BEACH, tile):
				continue
			found = true
			assert_true(MapCycle.is_walkable(MapCycle.Mode.BEACH, tile), "wet encounter %s" % tile)
	assert_true(found, "beach still has an encounter zone")
	assert_false(MapCycle.is_encounter_zone(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN))


func test_swatch_bar_stays_off_camera() -> void:
	assert_eq(MapCycle.camera_top(MapCycle.Mode.BEACH), MapCycle.BEACH_TOP_MARGIN)
	assert_eq(MapCycle.camera_top(MapCycle.Mode.DEFAULT), 0)


func test_npc_tiles_block_the_player() -> void:
	var world := _overworld()
	var npcs := world.get_tree().get_nodes_in_group("npc")
	assert_true(npcs.size() > 0, "overworld ships NPCs")
	for npc in npcs:
		var tile: Vector2i = OverworldState.tile_of(npc as Node2D)
		assert_true(MapCycle.is_walkable(MapCycle.Mode.DEFAULT, tile), "NPC on open ground %s" % tile)
		assert_false(world._is_active_tile_walkable(tile), "NPC tile is solid %s" % tile)
	world.free()


func test_player_cannot_step_onto_an_npc() -> void:
	var world := _overworld()
	var npc := world.get_tree().get_nodes_in_group("npc")[0] as Node2D
	var tile := OverworldState.tile_of(npc)
	var player := world.get_node("Player")
	player.place(tile + Vector2i.LEFT)
	assert_false(player.try_step(Vector2i.RIGHT), "walked through an NPC")
	assert_eq(player.tile, tile + Vector2i.LEFT, "stayed put")
	assert_eq(player.facing, Vector2i.RIGHT, "still turns to face them")
	world.free()


## Blocking three tiles must not wall off part of the map.
func test_npcs_do_not_disconnect_the_map() -> void:
	var world := _overworld()
	var seen := {GrassMap.START_TILE: true}
	var queue: Array[Vector2i] = [GrassMap.START_TILE]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = tile + step
			if seen.has(next) or not world._is_active_tile_walkable(next):
				continue
			seen[next] = true
			queue.append(next)
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var tile := Vector2i(x, y)
			if world._is_active_tile_walkable(tile):
				assert_true(seen.has(tile), "walled off %s" % tile)
	world.free()


## NPCs live on the default map only; they must not haunt the beach or the interior.
func test_hidden_npcs_stop_blocking() -> void:
	var world := _overworld()
	var tile: Vector2i = OverworldState.tile_of(world.get_tree().get_nodes_in_group("npc")[0])
	assert_false(world._is_active_tile_walkable(tile), "blocks on the default map")
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	assert_eq(world._npc_tiles.size(), 0, "no NPC tiles held on the beach")
	world.free()


## The house prop is drawn by OverworldState.tscn but blocked by map data, and the two have to
## agree. They did not: the footprint sat three rows below the sprite, so the player walked
## through the house and was stopped by nothing in the grass underneath.
func test_house_body_is_solid_where_the_sprite_is_drawn() -> void:
	var world := _overworld()
	var house: Sprite2D = world.get_node("House")
	var origin := OverworldState.tile_of(house)
	assert_eq(origin, GrassMap.HOUSE_FOOTPRINT.position, "sprite sits on its own footprint")
	var span := Vector2i(house.texture.get_width(), house.texture.get_height()) / GrassMap.TILE
	assert_true(span.x == GrassMap.HOUSE_FOOTPRINT.size.x, "footprint is as wide as the art")
	for y in GrassMap.HOUSE_FOOTPRINT.size.y:
		for x in GrassMap.HOUSE_FOOTPRINT.size.x:
			var tile: Vector2i = GrassMap.HOUSE_FOOTPRINT.position + Vector2i(x, y)
			if tile == MapCycle.DEFAULT_DOOR:
				continue
			assert_false(world._is_active_tile_walkable(tile), "walked through the house at %s" % tile)
	world.free()


func test_the_front_door_opens_and_lets_you_back_out() -> void:
	var world := _overworld()
	assert_true(MapCycle.is_walkable(MapCycle.Mode.DEFAULT, MapCycle.DEFAULT_DOOR), "door")
	assert_true(MapCycle.is_walkable(MapCycle.Mode.DEFAULT, MapCycle.DEFAULT_RETURN), "step back out")
	assert_eq(MapCycle.DEFAULT_RETURN, MapCycle.DEFAULT_DOOR + Vector2i.DOWN, "return is at the door")
	# Walking up onto the door tile enters the house.
	world._player.place(MapCycle.DEFAULT_RETURN)
	assert_true(world._player.try_step(Vector2i.UP), "can reach the door from outside")
	world.free()


## The beach mask is traced off the background art and knows nothing about props laid on top.
func test_the_beach_house_is_solid_too() -> void:
	for y in MapCycle.BEACH_HOUSE_FOOTPRINT.size.y:
		for x in MapCycle.BEACH_HOUSE_FOOTPRINT.size.x:
			var tile: Vector2i = MapCycle.BEACH_HOUSE_FOOTPRINT.position + Vector2i(x, y)
			assert_false(MapCycle.is_walkable(MapCycle.Mode.BEACH, tile), "through the beach house at %s" % tile)
	assert_true(MapCycle.is_walkable(MapCycle.Mode.BEACH, MapCycle.BEACH_DOOR), "its door still opens")
