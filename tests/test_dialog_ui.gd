extends TestCase
## Proximity prompt, portrait dialogue box, and the repeat-visit line rotation.

const MapCycle := preload("res://world/MapCycle.gd")
const GrassMap := preload("res://world/GrassMap.gd")


func _overworld() -> OverworldState:
	var world := load("res://world/OverworldState.tscn").instantiate() as OverworldState
	tree.root.add_child(world)
	GameData.player_tile = GrassMap.START_TILE
	world.enter({})
	return world


func _npc_named(world: OverworldState, id: String) -> Node2D:
	for npc in world.get_tree().get_nodes_in_group("npc"):
		if NpcTalk.id_of(npc) == id:
			return npc as Node2D
	return null


func test_every_variation_opens_with_the_canonical_line() -> void:
	for id in NpcTalk.VARIATIONS:
		var all := NpcTalk.lines_for(String(id))
		assert_true(all.size() >= 2, "%s has variations" % id)
		assert_eq(all[0], NpcTalk.line_for(String(id)), "%s opens on its known line" % id)


func test_line_at_rotates_and_wraps() -> void:
	var all := NpcTalk.lines_for("elder")
	assert_eq(NpcTalk.line_at("elder", 0), all[0])
	assert_eq(NpcTalk.line_at("elder", 1), all[1])
	assert_eq(NpcTalk.line_at("elder", all.size()), all[0], "wraps back to the opener")
	# An id with no variations still answers, it just never changes.
	assert_eq(NpcTalk.line_at("unknown-npc", 3), NpcTalk.FALLBACK)


func test_every_mapped_portrait_exists() -> void:
	for id in NpcTalk.PORTRAITS:
		var path := NpcTalk.portrait_path(String(id))
		assert_true(ResourceLoader.exists(path), "missing portrait %s" % path)
	assert_eq(NpcTalk.portrait_path("sign"), "", "a sign has no face")


func test_talking_twice_moves_to_the_next_line() -> void:
	var world := _overworld()
	var box: Label = world.get_node("TalkHud/TalkBox")
	assert_true(world.try_talk())
	var first := box.text
	world._close_talk()
	assert_true(world.try_talk())
	assert_ne(box.text, first, "repeat visit says something new")
	world.free()


func test_dialogue_box_shows_the_studio_frame_and_a_portrait() -> void:
	var world := _overworld()
	var panel: TextureRect = world.get_node("TalkHud/Panel")
	var portrait: TextureRect = world.get_node("TalkHud/Portrait")
	var frame := panel.texture as AtlasTexture
	assert_ne(frame, null, "box is cropped, not the raw sheet")
	assert_eq(frame.atlas.resource_path, "res://assets/studio/dialogue_box.png")
	assert_true(frame.region.position.y > 0.0, "swatch bar cropped off the top")

	var elder := _npc_named(world, "elder")
	world._player.place(OverworldState.tile_of(elder))
	assert_true(world.try_talk())
	assert_true(panel.visible)
	assert_true(portrait.visible, "elder has a portrait")
	assert_eq(portrait.texture.resource_path, NpcTalk.portrait_path("elder"))
	# Portrait sits in the bottom-left of the frame.
	assert_true(portrait.position.x < panel.position.x + panel.size.x * 0.25, "left")
	assert_true(portrait.position.y + portrait.size.y <= panel.position.y + panel.size.y, "inside")
	world.free()


func test_closing_clears_the_portrait() -> void:
	var world := _overworld()
	var portrait: TextureRect = world.get_node("TalkHud/Portrait")
	world._player.place(OverworldState.tile_of(_npc_named(world, "elder")))
	assert_true(world.try_talk())
	assert_true(portrait.visible)
	world._close_talk()
	assert_false(portrait.visible)
	assert_false(world.get_node("TalkHud/Panel").visible)
	world.free()


func test_a_faceless_npc_still_opens_the_box() -> void:
	var world := _overworld()
	world._player.place(OverworldState.tile_of(_npc_named(world, "sign")))
	assert_true(world.try_talk())
	assert_true(world.get_node("TalkHud/Panel").visible, "box opens")
	assert_false(world.get_node("TalkHud/Portrait").visible, "no face for a sign")
	world.free()


func test_prompt_appears_near_an_npc_and_hides_when_away() -> void:
	var world := _overworld()
	var prompt: Node2D = world.get_node("InteractPrompt")
	var elder := _npc_named(world, "elder")
	world._player.place(OverworldState.tile_of(elder) + Vector2i.LEFT)
	world._refresh_prompt()
	assert_true(prompt.visible, "badge shows next to the elder")
	assert_eq(world.prompt_target(), elder)
	assert_true(prompt.position.y < elder.position.y, "badge floats above their head")

	world._player.place(Vector2i(20, 20))
	world._refresh_prompt()
	assert_false(prompt.visible, "badge gone once out of range")
	world.free()


func test_prompt_hides_while_talking() -> void:
	var world := _overworld()
	world._player.place(OverworldState.tile_of(_npc_named(world, "elder")))
	world._refresh_prompt()
	assert_true(world.get_node("InteractPrompt").visible)
	assert_true(world.try_talk())
	assert_false(world.get_node("InteractPrompt").visible, "badge yields to the dialogue")
	assert_eq(world.prompt_target(), null)
	world.free()


## NPCs are hidden away from the default map, so nothing should float over the beach.
func test_prompt_stays_hidden_on_other_maps() -> void:
	var world := _overworld()
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	world._refresh_prompt()
	assert_false(world.get_node("InteractPrompt").visible)
	assert_eq(world.prompt_target(), null)
	world.free()


## In UI text the buttons are named A / B / C, never keyboard keys (docs/ARCHITECTURE.md).
func test_prompt_names_the_button_not_the_key() -> void:
	var world := _overworld()
	var text: String = (world.get_node("InteractPrompt/Label") as Label).text
	assert_true(text.contains("A"), "names the A button")
	for key in ["SPACE", "ENTER", "Z", "KEY"]:
		assert_false(text.to_upper().contains(key), "leaks a key name: %s" % key)
	world.free()
