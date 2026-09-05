extends TestCase
## Battle flavor wraps and keeps the nostalgic / 2026 split.


func test_intro_wants_to_debate() -> void:
	assert_true(BattleCopy.intro("Debugbug").contains("debate"))
	assert_true(BattleCopy.fits(BattleCopy.intro("Debugbug")))


func test_miss_and_faint_and_run() -> void:
	assert_eq(BattleCopy.miss(), "The attack hallucinated.")
	assert_true(BattleCopy.faint_wild("Debugbug").contains("logged off"))
	assert_true(BattleCopy.faint_player("Starterpup").contains("Skill issue"))
	assert_eq(BattleCopy.run_ok(), "Got away safely!")
	assert_true(BattleCopy.run_fail().contains("unionizing"))


func test_catch_throw_escalates_with_rage() -> void:
	assert_true(BattleCopy.catch_throw(0).contains("threw"))
	assert_true(BattleCopy.catch_throw(2).contains("yeeted"))


func test_switch_lines_keep_fire_red_shape() -> void:
	assert_true(BattleCopy.switch_out("Starterpup").begins_with("Come back,"))
	assert_true(BattleCopy.switch_out("Starterpup").contains("discourse"))
	assert_true(BattleCopy.switch_in("Starterpup").begins_with("Go,"))
	assert_true(BattleCopy.switch_in("Starterpup").contains("comments"))


func test_all_named_copy_fits_long_names() -> void:
	var names := ["X", "Debugbug", "Starterpup", "Hallucinox", "Contextfrog"]
	for n in names:
		var lines: Array[String] = [
			BattleCopy.intro(n),
			BattleCopy.used_move(n, "TACKLE"),
			BattleCopy.wild_used_move(n, "EMBER"),
			BattleCopy.faint_wild(n),
			BattleCopy.faint_player(n),
			BattleCopy.recovered(n, 20),
			BattleCopy.already_out(n),
			BattleCopy.switch_out(n),
			BattleCopy.switch_in(n),
			BattleCopy.catch_throw(0),
			BattleCopy.catch_throw(3),
			BattleCopy.run_ok(),
			BattleCopy.run_fail(),
			BattleCopy.miss(),
			BattleCopy.no_item(),
			BattleCopy.no_orbs(),
		]
		for line in lines:
			assert_true(BattleCopy.fits(line), line)
