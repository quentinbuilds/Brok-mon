extends TestCase
## Corner minimap: what it paints, where it sits, and when it gets out of the way.

const MapCycle := preload("res://world/MapCycle.gd")
const GrassMap := preload("res://world/GrassMap.gd")


func _overworld() -> OverworldState:
	var world := load("res://world/OverworldState.tscn").instantiate() as OverworldState
	tree.root.add_child(world)
	GameData.player_tile = GrassMap.START_TILE
	world.enter({})
	return world


## Image pixel for a tile, accounting for the one-pixel frame and the window origin.
func _pixel_for(map: Minimap, tile: Vector2i) -> Vector2i:
	return tile - map.window_origin() + Vector2i.ONE


func test_overworld_ships_a_minimap() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	assert_ne(map, null)
	assert_eq(map.layer, Minimap.LAYER)
	assert_true(map.layer < 20, "an open dialogue covers the map")
	world.free()


func test_minimap_sits_in_the_bottom_right_corner() -> void:
	var world := _overworld()
	var view: TextureRect = world.get_node("Minimap/View")
	var far := view.position + view.size
	assert_true(view.position.x > Minimap.SCREEN.x * 0.5, "right half")
	assert_true(view.position.y > Minimap.SCREEN.y * 0.5, "bottom half")
	assert_true(far.x <= Minimap.SCREEN.x, "inside the screen")
	assert_true(far.y <= Minimap.SCREEN.y, "inside the screen")
	assert_eq(far, Vector2(Minimap.SCREEN - Vector2i.ONE * Minimap.MARGIN), "hugs the corner")
	world.free()


func test_player_dot_sits_at_the_centre_of_the_window() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	map._blink_on = true
	map.track(Vector2i(20, 15))
	var at := _pixel_for(map, Vector2i(20, 15))
	assert_eq(map._image.get_pixel(at.x, at.y), Minimap.PLAYER_DOT)
	world.free()


func test_terrain_is_coloured_from_the_map_glyphs() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	map._blink_on = false
	map.track(Vector2i(20, 15))
	var checked := 0
	for y in GrassMap.HEIGHT:
		for x in GrassMap.WIDTH:
			var tile := Vector2i(x, y)
			var at := _pixel_for(map, tile)
			if at.x < 1 or at.y < 1 or at.x > Minimap.VIEW.x or at.y > Minimap.VIEW.y:
				continue
			if map._npc_tiles.has(tile):
				continue
			var want: Color = Minimap.TERRAIN[GrassMap.glyph(tile)]
			assert_eq(map._image.get_pixel(at.x, at.y), want, "tile %s" % tile)
			checked += 1
	assert_true(checked > 100, "checked a real slice of the map")
	world.free()


func test_npcs_show_as_their_own_dots() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	map._blink_on = false
	map.track(GrassMap.START_TILE)
	assert_true(map._npc_tiles.size() > 0, "minimap was told about the NPCs")
	for tile in map._npc_tiles:
		var at := _pixel_for(map, tile)
		if at.x < 1 or at.y < 1 or at.x > Minimap.VIEW.x or at.y > Minimap.VIEW.y:
			continue
		assert_eq(map._image.get_pixel(at.x, at.y), Minimap.NPC_DOT, "NPC dot at %s" % tile)
	world.free()


## The beach is smaller than the window, so it is centred and framed by empty margin.
func test_off_map_reads_as_empty() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	map._blink_on = false
	map.refresh()
	assert_eq(map._image.get_pixel(1, 1), Minimap.OFF_MAP)
	world.free()


## The whole point of TASK 3's event listener: no minimap during a fight.
func test_minimap_disappears_for_battle_and_comes_back() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	assert_true(GameState.state_changed.is_connected(map._on_state_changed), "listening")
	map._on_state_changed(GameState.State.OVERWORLD, GameState.State.BATTLE)
	assert_false(map.visible, "hidden for the battle")
	map._on_state_changed(GameState.State.BATTLE, GameState.State.OVERWORLD)
	assert_true(map.visible, "back afterwards")
	world.free()


## It is a CanvasLayer, so hiding the overworld Node2D does not hide it -- only the listener does.
func test_minimap_also_yields_to_the_menu_and_catching() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	for state in [GameState.State.MENU, GameState.State.CATCHING, GameState.State.TITLE]:
		map._on_state_changed(GameState.State.OVERWORLD, state)
		assert_false(map.visible, "hidden for %s" % GameState.State.keys()[state])
	world.free()


func test_minimap_follows_the_player_onto_the_beach() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	assert_eq(map.map_mode, MapCycle.Mode.BEACH)
	assert_eq(map.player_tile, MapCycle.BEACH_RETURN)
	# The beach has its own cast now; the default-map locals must not show up here.
	assert_true(map._npc_tiles.size() > 0, "the beach cast is plotted")
	for tile in map._npc_tiles:
		assert_true(MapCycle.is_walkable(MapCycle.Mode.BEACH, tile), "dot on sand at %s" % tile)
	map._blink_on = false
	map.refresh()
	var sea := _pixel_for(map, Vector2i(0, 5))
	assert_eq(map._image.get_pixel(sea.x, sea.y), Minimap.TERRAIN["~"], "sea reads as water")
	var sand := _pixel_for(map, MapCycle.BEACH_RETURN)
	assert_eq(map._image.get_pixel(sand.x, sand.y), Minimap.TERRAIN["="], "land reads as sand")
	world.free()


func test_walking_moves_the_window() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	var before := map.player_tile
	world._player.place(GrassMap.START_TILE)
	world._player.try_step(Vector2i.RIGHT)
	while not world._player.advance(0.05):
		pass
	world._on_step_finished()
	assert_ne(map.player_tile, before, "minimap tracked the step")
	assert_eq(map.player_tile, world._player.tile)
	world.free()


## A map smaller than the window is centred rather than pinned to the player, so standing in a
## corner does not fill the widget with void. The beach is the small one.
func test_window_frames_a_small_map_instead_of_chasing_the_player() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	map.track(Vector2i(11, 1))
	var framed := map.window_origin()
	map.track(Vector2i(MapCycle.BEACH_WIDTH - 2, MapCycle.BEACH_HEIGHT - 2))
	assert_eq(map.window_origin(), framed, "whole map stays framed from either corner")
	assert_eq(framed, -(Minimap.VIEW - MapCycle.map_tiles(MapCycle.Mode.BEACH)) / 2, "centred")
	world.free()


## A map bigger than the window scrolls, but stops at the edges.
func test_window_clamps_to_the_edges_of_a_large_map() -> void:
	var world := _overworld()
	var map: Minimap = world.get_node("Minimap")
	var big := MapCycle.map_tiles(MapCycle.Mode.DEFAULT)
	assert_true(big.x > Minimap.VIEW.x, "the default map outgrew the widget")
	map.track(Vector2i.ZERO)
	assert_eq(map.window_origin().x, 0, "does not scroll past the left edge")
	map.track(Vector2i(big.x - 1, 0))
	assert_eq(map.window_origin().x, big.x - Minimap.VIEW.x, "stops at the right edge")
	map.track(Vector2i(big.x / 2, big.y / 2))
	assert_eq(map.window_origin().x, big.x / 2 - Minimap.VIEW.x / 2, "scrolls with the player")
	world.free()
