extends TestCase
## GameState: legal transition table, two-layer scene model, event-driven transitions.

var world: Node
var overlay: Node

func _gs() -> Node:
	return tree.root.get_node("GameState")

func _bus() -> Node:
	return tree.root.get_node("EventBus")

func _wild() -> Creature:
	var c := Creature.new()
	c.name = "Testbug"
	c.max_hp = 10
	c.hp = 10
	return c

func before_each() -> void:
	world = Node.new()
	overlay = Node.new()
	tree.root.add_child(world)
	tree.root.add_child(overlay)
	_gs().bind(world, overlay)

func after_each() -> void:
	_gs().unbind()
	world.free()
	overlay.free()

func _go(states: Array) -> void:
	for s in states:
		assert_true(_gs().transition_to(s), "transition to %s from %s" % [s, _gs().current])

func test_bind_starts_in_boot() -> void:
	assert_eq(_gs().current, GameState.State.BOOT)

func test_boot_to_title_is_legal() -> void:
	assert_true(_gs().transition_to(GameState.State.TITLE))
	assert_eq(_gs().current, GameState.State.TITLE)

func test_illegal_transition_is_rejected_and_state_unchanged() -> void:
	assert_false(_gs().transition_to(GameState.State.BATTLE))
	assert_eq(_gs().current, GameState.State.BOOT)

func test_full_prd_loop_is_legal() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.BATTLE, S.CATCHING, S.OVERWORLD, S.MENU, S.OVERWORLD, S.BATTLE, S.OVERWORLD])
	assert_eq(_gs().current, S.OVERWORLD)

func test_title_lives_in_overlay_and_is_removed_on_overworld() -> void:
	var S := GameState.State
	_go([S.TITLE])
	assert_eq(overlay.get_child_count(), 1, "title in overlay")
	assert_eq(world.get_child_count(), 0)
	_go([S.OVERWORLD])
	assert_eq(overlay.get_child_count(), 0, "overlay cleared")
	assert_eq(world.get_child_count(), 1, "overworld in world layer")

func test_overworld_persists_and_freezes_under_battle() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD])
	var ow := world.get_child(0)
	_go([S.BATTLE])
	assert_eq(overlay.get_child_count(), 1, "battle in overlay")
	assert_false(ow.visible, "overworld hidden during battle")
	assert_eq(ow.process_mode, Node.PROCESS_MODE_DISABLED)
	_go([S.OVERWORLD])
	assert_eq(world.get_child_count(), 1)
	assert_eq(world.get_child(0), ow, "same overworld instance survives")
	assert_true(ow.visible)
	assert_eq(ow.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(overlay.get_child_count(), 0)

func test_menu_freezes_overworld_and_closes_back() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.MENU])
	assert_eq(world.get_child(0).process_mode, Node.PROCESS_MODE_DISABLED)
	_go([S.OVERWORLD])
	assert_eq(world.get_child(0).process_mode, Node.PROCESS_MODE_INHERIT)

func test_payload_is_delivered_to_state() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD])
	var wild := _wild()
	assert_true(_gs().transition_to(S.BATTLE, {"wild": wild}))
	var battle := overlay.get_child(0)
	assert_eq(battle.payload.get("wild"), wild)

func test_encounter_event_drives_overworld_to_battle() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD])
	_bus().encounter_triggered.emit(_wild())
	assert_eq(_gs().current, S.BATTLE)

func test_encounter_event_ignored_outside_overworld() -> void:
	var S := GameState.State
	_go([S.TITLE])
	_bus().encounter_triggered.emit(_wild())
	assert_eq(_gs().current, S.TITLE)

func test_battle_results_return_to_overworld() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.BATTLE])
	_bus().battle_won.emit(_wild())
	assert_eq(_gs().current, S.OVERWORLD)
	_go([S.BATTLE])
	_bus().battle_lost.emit()
	assert_eq(_gs().current, S.OVERWORLD)
	_go([S.BATTLE])
	_bus().battle_escaped.emit()
	assert_eq(_gs().current, S.OVERWORLD)

func test_catch_failed_returns_to_battle_with_same_wild() -> void:
	var S := GameState.State
	var wild := _wild()
	_go([S.TITLE, S.OVERWORLD])
	_gs().transition_to(S.BATTLE, {"wild": wild})
	_gs().transition_to(S.CATCHING, {"wild": wild})
	_bus().catch_failed.emit(wild)
	assert_eq(_gs().current, S.BATTLE)
	assert_eq(overlay.get_child(0).payload.get("wild"), wild)
	assert_true(overlay.get_child(0).payload.get("resume", false))

func test_creature_caught_returns_to_overworld() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.BATTLE, S.CATCHING])
	_bus().creature_caught.emit(_wild())
	assert_eq(_gs().current, S.OVERWORLD)

func test_state_changed_signal_fires() -> void:
	var seen := []
	_gs().state_changed.connect(func(from, to): seen.append([from, to]))
	_gs().transition_to(GameState.State.TITLE)
	assert_eq(seen.size(), 1)
	assert_eq(seen[0], [GameState.State.BOOT, GameState.State.TITLE])

# --- SOUND_TEST: dev audio screen, reached from the menu (MENU -> A) ---

func test_menu_opens_sound_test_and_returns() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.MENU, S.SOUND_TEST])
	assert_eq(overlay.get_child_count(), 1, "sound test replaces the menu in the overlay")
	_go([S.MENU])
	assert_eq(_gs().current, S.MENU)

func test_sound_test_is_only_reachable_from_the_menu() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD])
	assert_false(_gs().transition_to(S.SOUND_TEST), "overworld must not jump to the sound test")
	assert_eq(_gs().current, S.OVERWORLD)

func test_sound_test_cannot_skip_straight_to_overworld() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.MENU, S.SOUND_TEST])
	assert_false(_gs().transition_to(S.OVERWORLD), "C returns to the menu, not the map")
	assert_eq(_gs().current, S.SOUND_TEST)

func test_overworld_stays_frozen_under_the_sound_test() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.MENU, S.SOUND_TEST])
	assert_eq(world.get_child_count(), 1, "overworld kept alive")
	assert_eq(world.get_child(0).process_mode, Node.PROCESS_MODE_DISABLED)


func test_menu_can_return_to_title_and_drops_the_overworld() -> void:
	var S := GameState.State
	_go([S.TITLE, S.OVERWORLD, S.MENU])
	var old_ow := world.get_child(0)
	assert_true(_gs().transition_to(S.TITLE), "EXIT is MENU -> TITLE")
	assert_eq(_gs().current, S.TITLE)
	assert_eq(world.get_child_count(), 0, "overworld freed so a new game can start")
	_go([S.OVERWORLD])
	assert_eq(world.get_child_count(), 1)
	assert_ne(world.get_child(0), old_ow, "title starts a fresh overworld")
