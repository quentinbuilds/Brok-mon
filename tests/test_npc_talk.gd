extends TestCase
## Overworld NPC one-liners. Lookup stays usable after Person 2 replaces the map.


func test_known_ids_match_the_plan() -> void:
	assert_true(NpcTalk.line_for("wizard").contains("Fetch"))
	assert_true(NpcTalk.line_for("skeleton").contains("cooldown"))
	assert_true(NpcTalk.line_for("elder").contains("'98"))
	assert_true(NpcTalk.line_for("sign").contains("TOKEN"))
	assert_true(NpcTalk.line_for("youth").contains("battery"))
	assert_eq(NpcTalk.line_for("unknown-npc"), NpcTalk.FALLBACK)


func test_id_prefers_talk_id_meta() -> void:
	var n := Node2D.new()
	n.name = "SomeSprite"
	n.set_meta("talk_id", "wizard")
	assert_eq(NpcTalk.id_of(n), "wizard")
	assert_true(NpcTalk.line_for_node(n).contains("Fetch"))
	n.free()


func test_nearest_respects_talk_range() -> void:
	var a := Node2D.new()
	a.position = Vector2(40, 0)
	var b := Node2D.new()
	b.position = Vector2(8, 0)
	var hit := NpcTalk.nearest(Vector2.ZERO, [a, b])
	assert_eq(hit, b)
	var miss := NpcTalk.nearest(Vector2.ZERO, [a])
	assert_eq(miss, null)
	var stub := ColorRect.new()
	stub.position = Vector2(4, 0)
	assert_eq(NpcTalk.nearest(Vector2.ZERO, [stub]), stub)
	a.free()
	b.free()
	stub.free()


func test_overworld_talks_to_nearby_npc() -> void:
	var packed := load("res://world/OverworldState.tscn") as PackedScene
	var world := packed.instantiate() as OverworldState
	tree.root.add_child(world)
	await tree.process_frame
	GameData.player_tile = Vector2i.ZERO
	world.enter({})
	world.get_node("Player").position = Vector2(72, 8)
	assert_true(world.try_talk())
	assert_true(world.talking)
	assert_true(world.get_node("TalkBox").visible)
	assert_true(world.get_node("TalkBox").text.contains("TOKEN"))
	world.queue_free()
	await tree.process_frame
