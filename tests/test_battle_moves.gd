extends TestCase
## Fight menu is a 2x2 moveset, not an auto-attack.


func _mk(p_name: String, hp: int, atk: int, defense: int) -> Creature:
	var c := Creature.new()
	c.name = p_name
	c.max_hp = hp
	c.hp = hp
	c.attack = atk
	c.defense = defense
	c.catch_rate = 0.5
	c.type = &"NORMAL"
	c.level = 5
	return c


func before_each() -> void:
	GameData.reset()


func _wait_player_turn(battle: BattleState, frames: int = 45) -> void:
	for _i in frames:
		await tree.process_frame
		if battle.sub == BattleState.Sub.PLAYER_TURN:
			return


func test_fight_menu_skips_empty_cell() -> void:
	var m := FightMenu.new()
	var moves: Array[BattleMove] = [
		MoveDex.get_move(&"tackle"),
		MoveDex.get_move(&"side_eye"),
		MoveDex.get_move(&"quick_post"),
	]
	m.set_moves(moves)
	assert_eq(m.current().id, &"tackle")
	assert_true(m.move(1, 0))
	assert_eq(m.current().id, &"side_eye")
	assert_eq(m.row, 0)
	assert_eq(m.col, 1)
	assert_true(m.cell_at(1, 1) == null, "bottom-right is empty with 3 moves")
	assert_true(m.move(0, 1), "down from top-right skips the empty slot")
	assert_eq(m.current().id, &"quick_post")
	assert_eq(m.row, 1)
	assert_eq(m.col, 0)


func test_moves_of_uses_known_ids() -> void:
	var c := Creature.new()
	c.type = &"FIRE"
	c.known_move_ids = PackedStringArray(["ember", "hot_take"])
	var moves := BattleLogic.moves_of(c)
	assert_eq(moves.size(), 2)
	assert_eq(moves[0].name, "EMBER")
	assert_eq(moves[1].name, "HOT TAKE")


func test_fight_opens_move_menu_instead_of_attacking() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var battle := BattleState.new()
	battle.instant = true
	battle.services.inventory = BattleServices.NullInventory.new()
	battle.services.party = BattleServices.NullParty.new()
	host.add_child(battle)
	await tree.process_frame
	var mine := _mk("HERO", 30, 8, 5)
	var wild := _mk("BUG", 30, 1, 5)
	GameData.party = [mine]
	GameData.active_index = 0
	(battle.services.party as BattleServices.NullParty).party = [mine]
	battle.enter({"wild": wild})
	await _wait_player_turn(battle)
	var hp_before := wild.hp
	battle._choose(ActionMenu.Action.FIGHT)
	await tree.process_frame
	assert_eq(battle.ui.mode, BattleUI.Mode.FIGHT)
	assert_eq(battle.sub, BattleState.Sub.PLAYER_TURN)
	assert_false(battle.busy)
	assert_eq(wild.hp, hp_before, "FIGHT must not auto-use a move")
	assert_true(battle.ui.fight_menu.moves.size() >= 1)
	host.queue_free()
	await tree.process_frame


func test_selected_move_then_victory_grants_exp() -> void:
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
	var level_before := mine.level
	battle.perform_attack(MoveDex.get_move(&"tackle"))
	for _i in 90:
		await tree.process_frame
		if won[0] or battle.finished:
			break
	assert_true(won[0], "battle_won emitted")
	assert_true(mine.level > level_before or mine.exp > 0, "winner got EXP")
	host.queue_free()
	await tree.process_frame
