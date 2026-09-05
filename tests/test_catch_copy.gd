extends TestCase
## Catching handshake copy and stub A/B contract.


func test_handshake_beats() -> void:
	assert_true(CatchCopy.connecting("Debugbug").contains("Connecting"))
	assert_eq(CatchCopy.handshake(), "Handshaking...")
	assert_true(CatchCopy.waiting().contains("200 OK"))
	assert_true(CatchCopy.beat_text(0, "Debugbug").contains("Debugbug"))
	assert_true(CatchCopy.beat_text(3, "Debugbug").contains("A: catch"))


func test_result_copy() -> void:
	assert_true(CatchCopy.success().contains("dataset"))
	assert_true(CatchCopy.party_full("Debugbug").contains("test set"))
	assert_true(CatchCopy.failure(2.0).contains("furious"))
	assert_true(CatchCopy.failure(0.5).contains("contract"))
	assert_true(CatchCopy.failure(1.0).contains("peer"))


func test_a_still_catches() -> void:
	GameData.reset()
	var packed := load("res://catching/CatchingState.tscn") as PackedScene
	var state := packed.instantiate() as CatchingState
	tree.root.add_child(state)
	await tree.process_frame
	var wild := Creature.new()
	wild.name = "Debugbug"
	wild.max_hp = 10
	wild.hp = 10
	var caught := [false]
	EventBus.creature_caught.connect(func(_c): caught[0] = true, CONNECT_ONE_SHOT)
	state.enter({"wild": wild, "catch_multiplier": 1.0})
	assert_true(state.get_node("Label").text.contains("Connecting"))
	GameConfig.debug_force_catch = 1
	state.update(0.0)
	assert_true(caught[0])
	assert_true(state.get_node("Label").text.contains("dataset"))
	state.queue_free()
	await tree.process_frame
	GameConfig.debug_force_catch = 0
