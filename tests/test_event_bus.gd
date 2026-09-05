extends TestCase
## EventBus must declare exactly the PRD §12 integration signals.

const PRD_SIGNALS := [
	"player_moved", "encounter_triggered",
	"battle_started", "battle_won", "battle_lost", "battle_escaped",
	"catch_started", "creature_caught", "catch_failed",
	"menu_opened", "menu_closed",
	"inventory_changed", "party_changed", "active_creature_changed",
]

func _bus() -> Node:
	return tree.root.get_node("EventBus")

func test_declares_every_prd_signal() -> void:
	for s in PRD_SIGNALS:
		assert_true(_bus().has_signal(s), "missing signal %s" % s)

func test_signal_arity_matches_contract() -> void:
	var arity := {}
	for s in _bus().get_signal_list():
		arity[s["name"]] = s["args"].size()
	assert_eq(arity.get("player_moved"), 2, "player_moved(tile, in_encounter_zone)")
	assert_eq(arity.get("encounter_triggered"), 1, "encounter_triggered(wild)")
	assert_eq(arity.get("battle_started"), 2, "battle_started(player_creature, wild)")
	assert_eq(arity.get("battle_lost"), 0)
	assert_eq(arity.get("catch_failed"), 1)
	assert_eq(arity.get("inventory_changed"), 1)
