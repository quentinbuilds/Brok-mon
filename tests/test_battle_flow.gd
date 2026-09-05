extends TestCase
## BattleState flows via public actions (instant mode).


func _mk(p_name: String, hp: int, atk: int, defense: int) -> Creature:
	var c := Creature.new()
	c.name = p_name
	c.max_hp = hp
	c.hp = hp
	c.attack = atk
	c.defense = defense
	c.catch_rate = 0.5
	c.type = &"NORMAL"
	return c


func before_each() -> void:
	GameData.reset()


func _wait_player_turn(battle: BattleState, frames: int = 45) -> void:
	for _i in frames:
		await tree.process_frame
		if battle.sub == BattleState.Sub.PLAYER_TURN:
			return


func test_fight_to_victory() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var battle := BattleState.new()
	battle.instant = true
	battle.services.inventory = BattleServices.NullInventory.new()
	battle.services.party = BattleServices.NullParty.new()
	host.add_child(battle)
	await tree.process_frame

	var mine := _mk("HERO", 30, 20, 5)
	var wild := _mk("BUG", 1, 1, 1)
	GameData.party = [mine]
	GameData.active_index = 0
	(battle.services.party as BattleServices.NullParty).party = [mine]

	var won := [false]
	EventBus.battle_won.connect(func(_w): won[0] = true, CONNECT_ONE_SHOT)

	battle.enter({"wild": wild})
	await _wait_player_turn(battle)
	assert_eq(battle.sub, BattleState.Sub.PLAYER_TURN, "intro reaches player turn")
	battle.perform_attack()
	for _i in 90:
		await tree.process_frame
		if won[0] or battle.finished:
			break
	assert_true(won[0], "battle_won emitted")
	assert_true(battle.finished)
	host.queue_free()
	await tree.process_frame


func test_run_emits_escaped() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var battle := BattleState.new()
	battle.instant = true
	battle.rng.seed = 42
	battle.services.inventory = BattleServices.NullInventory.new()
	battle.services.party = BattleServices.NullParty.new()
	host.add_child(battle)
	await tree.process_frame
	var mine := _mk("HERO", 30, 5, 5)
	var wild := _mk("BUG", 30, 5, 5)
	GameData.party = [mine]
	GameData.active_index = 0
	(battle.services.party as BattleServices.NullParty).party = [mine]
	var escaped := [false]
	EventBus.battle_escaped.connect(func(): escaped[0] = true, CONNECT_ONE_SHOT)
	battle.enter({"wild": wild})
	await _wait_player_turn(battle)
	for _attempt in 12:
		if escaped[0] or battle.finished:
			break
		battle.attempt_run()
		for _i in 40:
			await tree.process_frame
			if escaped[0] or battle.sub == BattleState.Sub.PLAYER_TURN or battle.finished:
				break
	assert_true(escaped[0], "battle_escaped emitted")
	host.queue_free()
	await tree.process_frame


func test_ragebait_changes_level() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var battle := BattleState.new()
	battle.instant = true
	battle.ragebait.forced_direction = Ragebait.Direction.ENRAGED
	battle.services.inventory = BattleServices.NullInventory.new()
	battle.services.party = BattleServices.NullParty.new()
	host.add_child(battle)
	await tree.process_frame
	var mine := _mk("HERO", 40, 8, 8)
	var wild := _mk("BUG", 40, 1, 8)
	GameData.party = [mine]
	GameData.active_index = 0
	(battle.services.party as BattleServices.NullParty).party = [mine]
	battle.enter({"wild": wild})
	await _wait_player_turn(battle)
	battle.perform_ragebait()
	for _i in 60:
		await tree.process_frame
		if battle.sub == BattleState.Sub.PLAYER_TURN:
			break
	assert_eq(battle.ragebait.level, 1)
	assert_eq(battle.ui.rage_level, 1)
	host.queue_free()
	await tree.process_frame


func test_catch_transitions_to_catching() -> void:
	var world := Node.new()
	var overlay := Node.new()
	tree.root.add_child(world)
	tree.root.add_child(overlay)
	GameState.bind(world, overlay)
	assert_true(GameState.transition_to(GameState.State.TITLE, {}))
	assert_true(GameState.transition_to(GameState.State.OVERWORLD, {}))
	var wild := _mk("BUG", 20, 5, 5)
	assert_true(GameState.transition_to(GameState.State.BATTLE, {"wild": wild}))
	await tree.process_frame
	var battle := GameState.get("_overlay") as BattleState
	assert_true(battle != null, "overlay is BattleState")
	Engine.time_scale = 12.0
	battle.instant = true
	if battle.seq:
		battle.seq.instant = true
	await _wait_player_turn(battle, 180)
	assert_eq(battle.sub, BattleState.Sub.PLAYER_TURN, "reached player turn before catch")
	battle.ragebait.level = 2
	var expected := battle.ragebait.catch_multiplier()
	# Ensure inventory path can spend an orb.
	if battle.services.inventory is BattleServices.NullInventory:
		pass
	else:
		assert_true(GameData.get_item_count(GameData.ITEM_CAPTURE_ORB) > 0)
	battle.request_catch()
	for _i in 90:
		await tree.process_frame
		if GameState.current == GameState.State.CATCHING:
			break
	Engine.time_scale = 1.0
	assert_eq(GameState.current, GameState.State.CATCHING)
	var catching := GameState.get("_overlay") as GameStateBase
	assert_true(catching != null)
	assert_eq(catching.payload.get("catch_multiplier", -1.0), expected)
	assert_eq(catching.payload.get("wild"), wild)
	GameState.unbind()
	world.queue_free()
	overlay.queue_free()
	await tree.process_frame
