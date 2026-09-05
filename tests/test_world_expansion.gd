extends TestCase
## The bigger world: size, biome variety, and how the cast is spread across it.

const GrassMap := preload("res://world/GrassMap.gd")
const MapCycle := preload("res://world/MapCycle.gd")


func _overworld() -> OverworldState:
	var world := load("res://world/OverworldState.tscn").instantiate() as OverworldState
	tree.root.add_child(world)
	GameData.player_tile = GrassMap.START_TILE
	world.enter({})
	return world


func test_the_world_outgrew_its_first_draft() -> void:
	assert_true(GrassMap.WIDTH >= 64, "wider, got %d" % GrassMap.WIDTH)
	assert_true(GrassMap.HEIGHT >= 48, "taller, got %d" % GrassMap.HEIGHT)
	assert_true(GrassMap.WIDTH * GrassMap.HEIGHT >= 2 * 40 * 30, "at least twice the area")


## Every tile the atlas can draw is actually used somewhere, so no biome art goes to waste.
func test_every_biome_glyph_appears_in_the_world() -> void:
	var seen := {}
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			seen[GrassMap.glyph(Vector2i(x, y))] = true
	for glyph in GrassMap.ATLAS_COLUMN:
		assert_true(seen.has(glyph), "glyph '%s' is never placed" % glyph)


func test_the_original_town_survived_the_expansion() -> void:
	# The coordinates other tests and the house pin down all still mean what they meant.
	assert_true(GrassMap.is_walkable(GrassMap.START_TILE), "start")
	assert_false(GrassMap.is_walkable(Vector2i(26, 4)), "tree")
	assert_false(GrassMap.is_walkable(Vector2i(4, 16)), "water")
	assert_false(GrassMap.is_walkable(Vector2i(29, 9)), "house footprint")
	# The doorway is carved through the house footprint by MapCycle, not by the glyph map.
	assert_true(MapCycle.is_walkable(MapCycle.Mode.DEFAULT, MapCycle.DEFAULT_DOOR), "door opens")
	assert_true(MapCycle.is_walkable(MapCycle.Mode.DEFAULT, MapCycle.DEFAULT_RETURN), "and back out")


func test_the_cast_grew_with_the_world() -> void:
	var world := _overworld()
	var npcs := world.get_tree().get_nodes_in_group("npc")
	assert_true(npcs.size() >= 12, "expected a populated world, got %d" % npcs.size())
	world.free()


## Spread, not a huddle: the cast should cover a real share of the map in both directions.
func test_npcs_are_spread_across_the_map() -> void:
	var world := _overworld()
	var low := Vector2i(GrassMap.WIDTH, GrassMap.HEIGHT)
	var high := Vector2i.ZERO
	for npc in world.get_tree().get_nodes_in_group("npc"):
		var tile: Vector2i = OverworldState.tile_of(npc as Node2D)
		low = Vector2i(mini(low.x, tile.x), mini(low.y, tile.y))
		high = Vector2i(maxi(high.x, tile.x), maxi(high.y, tile.y))
	var span := high - low
	assert_true(span.x >= GrassMap.WIDTH / 2, "spread across, got %d" % span.x)
	assert_true(span.y >= GrassMap.HEIGHT / 2, "spread down, got %d" % span.y)
	world.free()


func test_every_npc_stands_somewhere_legal() -> void:
	var world := _overworld()
	for npc in world.get_tree().get_nodes_in_group("npc"):
		var tile: Vector2i = OverworldState.tile_of(npc as Node2D)
		var biome: int = OverworldState.npc_biome(npc)
		assert_true(MapCycle.is_walkable(biome, tile),
			"%s is inside scenery at %s on %s" % [npc.name, tile, biome])
	world.free()


## A new face with nothing to say is worse than no new face.
func test_every_npc_has_a_line_and_most_have_a_portrait() -> void:
	var world := _overworld()
	var with_faces := 0
	for npc in world.get_tree().get_nodes_in_group("npc"):
		var id := NpcTalk.id_of(npc)
		assert_ne(NpcTalk.line_for(id), NpcTalk.FALLBACK, "%s says nothing" % id)
		assert_true(NpcTalk.lines_for(id).size() >= 2, "%s never varies" % id)
		var portrait := NpcTalk.portrait_path(id)
		if portrait != "":
			assert_true(ResourceLoader.exists(portrait), "missing portrait for %s" % id)
			with_faces += 1
	assert_true(with_faces >= 10, "most of the cast has a face, got %d" % with_faces)
	world.free()


func test_the_camera_covers_the_bigger_map() -> void:
	var world := _overworld()
	var camera: Camera2D = world.get_node("Camera")
	assert_eq(camera.limit_right, GrassMap.WIDTH * GrassMap.TILE)
	assert_eq(camera.limit_bottom, GrassMap.HEIGHT * GrassMap.TILE)
	world.free()
