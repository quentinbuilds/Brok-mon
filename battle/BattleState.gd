extends GameStateBase
class_name BattleState
## Person 4 battle. FireRed menu + RAGEBAIT. Talks to the rest of the game only
## via EventBus / GameState.transition_to / GameData (through BattleServices).

enum Sub { IDLE, INTRO, PLAYER_TURN, RESOLVING, ENEMY_TURN, FINISHED }
enum Result { WON, LOST, ESCAPED, CAUGHT }

signal battle_finished(result: int)

var services := BattleServices.new()
var ragebait := Ragebait.new()
var rng := RandomNumberGenerator.new()

var player: Creature
var enemy: Creature
var sub: int = Sub.IDLE
var busy: bool = false
var finished: bool = false
var run_failures: int = 0
## Headless tests set this so awaits collapse to a frame.
var instant: bool = false:
	set(value):
		instant = value
		if seq != null:
			seq.instant = value


var ui: BattleUI
var seq: TurnSequencer


func debug_payload() -> Dictionary:
	return {"wild": (load(GameConfig.DEBUG_WILD_PATH) as Creature).make_instance()}


func _ready() -> void:
	if ui == null:
		ui = BattleUI.new()
		add_child(ui)
	seq = TurnSequencer.new()
	seq.ui = ui
	seq.instant = instant
	add_child(seq)
	set_process(false)


func _on_enter() -> void:
	enemy = payload.get("wild") as Creature
	player = GameData.get_active_creature()
	if player == null:
		push_error("BattleState: no active creature")
		EventBus.battle_escaped.emit()
		return
	# GameState integration tests sometimes enter BATTLE without a wild; fall back
	# so the scene still mounts instead of emitting a spurious battle_escaped.
	if enemy == null:
		var fallback := load(GameConfig.DEBUG_WILD_PATH) as Creature
		if fallback:
			enemy = fallback.make_instance()
		else:
			push_error("BattleState: missing wild payload")
			EventBus.battle_escaped.emit()
			return

	run_failures = 0
	finished = false
	busy = false
	ragebait.reset()
	ui.rage_level = 0
	if player.level <= 0:
		player.level = 5
	Learnset.ensure_moves(player)
	ui.bind(player, enemy)
	seq.instant = instant

	if services.party is BattleServices.NullParty:
		var np: BattleServices.NullParty = services.party
		if np.party.is_empty():
			np.party = [player]

	var resuming := bool(payload.get("resume", false))
	if not resuming:
		enemy.level = Leveling.roll_wild_level(player.level, rng)
		enemy.known_move_ids = PackedStringArray()
		Learnset.ensure_moves(enemy)
		EventBus.battle_started.emit(player, enemy)
		_run_intro()
	else:
		Learnset.ensure_moves(enemy)
		# Failed catch: wild gets a free swing, then the menu returns.
		_enemy_turn()


func update(_delta: float) -> void:
	if busy or finished:
		return
	match ui.mode:
		BattleUI.Mode.ACTION:
			_handle_action_menu()
		BattleUI.Mode.FIGHT:
			_handle_fight_menu()
		BattleUI.Mode.BAG:
			_handle_list(ui.bag_menu, _confirm_bag)
		BattleUI.Mode.PARTY:
			_handle_list(ui.party_menu, _confirm_party)


func _run_intro() -> void:
	sub = Sub.INTRO
	busy = true
	await seq.intro(enemy.name)
	busy = false
	_open_action_menu()


func _open_action_menu() -> void:
	sub = Sub.PLAYER_TURN
	ui.mode = BattleUI.Mode.ACTION
	ui.action_menu.reset()


func _handle_action_menu() -> void:
	if sub != Sub.PLAYER_TURN:
		return
	var dir := InputManager.direction_just_pressed()
	var moved := false
	if dir == Vector2i.LEFT:
		moved = ui.action_menu.move(-1, 0)
	elif dir == Vector2i.RIGHT:
		moved = ui.action_menu.move(1, 0)
	elif dir == Vector2i.UP:
		moved = ui.action_menu.move(0, -1)
	elif dir == Vector2i.DOWN:
		moved = ui.action_menu.move(0, 1)
	if moved:
		ui.audio.menu_move()
	if InputManager.button_a_just_pressed():
		ui.audio.confirm()
		_choose(ui.action_menu.current())


func _handle_list(menu: ListMenu, on_confirm: Callable) -> void:
	var dir := InputManager.direction_just_pressed()
	if dir == Vector2i.UP:
		if menu.move(-1):
			ui.audio.menu_move()
	elif dir == Vector2i.DOWN:
		if menu.move(1):
			ui.audio.menu_move()
	if InputManager.button_b_just_pressed():
		ui.audio.cancel()
		_open_action_menu()
		return
	if InputManager.button_a_just_pressed():
		if menu.is_empty():
			ui.audio.denied()
			return
		on_confirm.call(menu.current())


func _choose(action: int) -> void:
	match action:
		ActionMenu.Action.FIGHT:
			_open_fight()
		ActionMenu.Action.BAG:
			_open_bag()
		ActionMenu.Action.PARTY:
			_open_party()
		ActionMenu.Action.RUN:
			attempt_run()
		ActionMenu.Action.RAGE:
			perform_ragebait()


func _open_fight() -> void:
	ui.fight_menu.set_moves(BattleLogic.moves_of(player))
	ui.mode = BattleUI.Mode.FIGHT


func _handle_fight_menu() -> void:
	if sub != Sub.PLAYER_TURN:
		return
	var dir := InputManager.direction_just_pressed()
	var moved := false
	if dir == Vector2i.LEFT:
		moved = ui.fight_menu.move(-1, 0)
	elif dir == Vector2i.RIGHT:
		moved = ui.fight_menu.move(1, 0)
	elif dir == Vector2i.UP:
		moved = ui.fight_menu.move(0, -1)
	elif dir == Vector2i.DOWN:
		moved = ui.fight_menu.move(0, 1)
	if moved:
		ui.audio.menu_move()
	if InputManager.button_b_just_pressed():
		ui.audio.cancel()
		_open_action_menu()
		return
	if InputManager.button_a_just_pressed():
		var move := ui.fight_menu.current()
		if move == null:
			ui.audio.denied()
			return
		ui.audio.confirm()
		perform_attack(move)


func _open_bag() -> void:
	ui.bag_menu.set_items(services.inventory.get_battle_items())
	ui.mode = BattleUI.Mode.BAG


func _open_party() -> void:
	var rows: Array[Dictionary] = []
	var party := services.party.get_party()
	for i in party.size():
		var c := party[i]
		rows.append({"index": i, "name": c.name, "hp": c.hp, "max_hp": c.max_hp})
	ui.party_menu.set_items(rows)
	ui.mode = BattleUI.Mode.PARTY


func _confirm_bag(item: Dictionary) -> void:
	ui.audio.confirm()
	use_item(item.get("id", &""))


func _confirm_party(row: Dictionary) -> void:
	ui.audio.confirm()
	switch_creature(int(row.get("index", 0)))


# --- Public actions (also used by tests) ------------------------------------

func perform_attack(move: BattleMove = null) -> void:
	if busy:
		return
	busy = true
	sub = Sub.RESOLVING
	if move == null:
		move = BattleLogic.moves_of(player)[0]
	await seq.say_auto(BattleCopy.used_move(player.name, move.name))
	await seq.lunge(ui.player_view)
	var result := BattleLogic.resolve_attack(
		player, enemy, move, rng, 1.0, ragebait.enemy_defense_multiplier()
	)
	if not result.hit:
		await seq.say_auto(BattleCopy.miss())
	else:
		await seq.impact(ui.enemy_view, result.damage, ui.enemy_center())
		await seq.drain_enemy_hp()
	if enemy.is_fainted():
		await seq.faint(ui.enemy_view)
		await seq.say_wait(BattleCopy.faint_wild(enemy.name))
		await _award_exp()
		_finish(Result.WON)
		return
	await _enemy_turn()


func use_item(item_id: StringName) -> void:
	if busy:
		return
	if item_id == GameData.ITEM_CAPTURE_ORB or item_id == &"capture_orb":
		request_catch()
		return
	if item_id == GameData.ITEM_POTION or item_id == &"potion":
		busy = true
		sub = Sub.RESOLVING
		if not services.inventory.use_item(item_id):
			ui.audio.denied()
			await seq.say_wait(BattleCopy.no_item())
			busy = false
			_open_action_menu()
			return
		var healed := BattleLogic.apply_heal(player, BattleConfig.POTION_HEAL)
		await seq.say_auto(BattleCopy.recovered(player.name, healed))
		await seq.drain_player_hp()
		await _enemy_turn()
		return
	ui.audio.denied()


func request_catch() -> void:
	if busy:
		return
	busy = true
	sub = Sub.RESOLVING
	if not services.inventory.use_item(GameData.ITEM_CAPTURE_ORB) \
			and not services.inventory.use_item(&"capture_orb"):
		ui.audio.denied()
		await seq.say_wait(BattleCopy.no_orbs())
		busy = false
		_open_action_menu()
		return
	var multiplier := ragebait.catch_multiplier()
	await seq.say_auto(BattleCopy.catch_throw(ragebait.level))
	# Person 5 owns catching. Hand off wild + rage multiplier via payload.
	finished = true
	busy = false
	sub = Sub.FINISHED
	GameState.transition_to(GameState.State.CATCHING, {
		"wild": enemy,
		"catch_multiplier": multiplier,
	})
	battle_finished.emit(Result.CAUGHT)


func switch_creature(index: int) -> void:
	if busy:
		return
	var party := services.party.get_party()
	if index < 0 or index >= party.size():
		return
	if party[index] == player:
		ui.audio.denied()
		busy = true
		await seq.say_wait(BattleCopy.already_out(player.name))
		busy = false
		_open_action_menu()
		return
	busy = true
	sub = Sub.RESOLVING
	var incoming := party[index]
	await seq.say_auto(BattleCopy.switch_out(player.name))
	services.party.set_active_index(index)
	player = incoming
	ui.bind(player, enemy)
	ui.player_view.slide_in(Vector2(-70, 0))
	await seq.say_auto(BattleCopy.switch_in(player.name))
	await _enemy_turn()


func perform_ragebait() -> void:
	if busy:
		return
	busy = true
	sub = Sub.RESOLVING
	var outcome := ragebait.taunt(enemy, rng)
	ui.rage_level = ragebait.level
	ui.audio.taunt()
	await seq.say_auto(BattleCopy.you_said(outcome.line))
	await seq.anger(maxi(1, absi(outcome.level)), outcome.direction == Ragebait.Direction.WARY)
	await seq.say_wait(ragebait.outcome_message(enemy.name, outcome))
	await _enemy_turn()


func attempt_run() -> void:
	if busy:
		return
	busy = true
	sub = Sub.RESOLVING
	EventBus.run_attempted.emit()
	if BattleLogic.try_run(run_failures, rng):
		await seq.say_wait(BattleCopy.run_ok())
		_finish(Result.ESCAPED)
		return
	run_failures += 1
	await seq.say_auto(BattleCopy.run_fail())
	await _enemy_turn()


func _enemy_turn() -> void:
	if finished:
		return
	sub = Sub.ENEMY_TURN
	var move := BattleLogic.choose_enemy_move(enemy, rng)
	await seq.say_auto(BattleCopy.wild_used_move(enemy.name, move.name))
	await seq.lunge(ui.enemy_view)
	var result := BattleLogic.resolve_attack(
		enemy, player, move, rng, ragebait.enemy_attack_multiplier(), 1.0
	)
	if not result.hit:
		await seq.say_auto(BattleCopy.miss())
	else:
		await seq.impact(ui.player_view, result.damage, ui.player_center())
		await seq.drain_player_hp()
	if player.is_fainted():
		await seq.faint(ui.player_view)
		await seq.say_wait(BattleCopy.faint_player(player.name))
		await _black_out()
		return
	busy = false
	_open_action_menu()


func _award_exp() -> void:
	var report := Leveling.grant_exp(player, enemy)
	var gained: int = int(report.get("gained", 0))
	if gained <= 0:
		return
	await seq.say_wait(BattleCopy.gained_exp(player.name, gained))
	for step in report.get("levels", []):
		await seq.say_wait(BattleCopy.leveled_up(player.name, int(step.get("level", player.level))))
		var learned_id := String(step.get("learned", ""))
		if learned_id.is_empty():
			continue
		var replaced_id := String(step.get("replaced", ""))
		if not replaced_id.is_empty():
			await seq.say_wait(BattleCopy.uninstalled_move(MoveDex.display_name(StringName(replaced_id))))
		await seq.say_wait(BattleCopy.learned_move(player.name, MoveDex.display_name(StringName(learned_id))))
	ui.player_display_hp = float(player.hp)


## Losing fades the screen to black before handing control back, so the swap out of BATTLE is
## covered rather than a hard cut. Follows the shape Transition.gd documents: await the close,
## do the swap, then start the open without awaiting it -- this node is freed by the swap, and
## awaiting past that point resumes inside a freed object.
##
## The party is healed here because battle owns creature HP; the overworld separately hears
## battle_lost and walks the player home. Without the heal the next encounter would open with
## a creature already on nought HP.
func _black_out() -> void:
	await seq.say_wait(BattleCopy.blacked_out(player.name))
	heal_party()
	# instant is how tests skip battle animation; the iris honours it too so a headless run
	# does not sit through the fade.
	var fade := 0.0 if instant else BattleConfig.BLACKOUT_FADE
	await Transition.close(ui.player_center(), fade)
	_finish(Result.LOST)
	Transition.open(fade)


## Full heal for everyone. GameData hands out the live creatures, so this also revives the
## fainted one currently on the field.
static func heal_party() -> void:
	for creature in GameData.get_party():
		creature.hp = creature.max_hp


func _finish(result: int) -> void:
	if finished:
		return
	finished = true
	busy = false
	sub = Sub.FINISHED
	if result == Result.WON:
		ui.audio.victory()
	ui.audio.stop_low_hp()
	match result:
		Result.WON:
			EventBus.battle_won.emit(enemy)
		Result.LOST:
			EventBus.battle_lost.emit()
		Result.ESCAPED:
			EventBus.battle_escaped.emit()
		Result.CAUGHT:
			pass
	battle_finished.emit(result)
