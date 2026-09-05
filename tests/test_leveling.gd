extends TestCase
## EXP curve, level-up stats, and learn-on-level.


func _creature(p_type: StringName = &"NORMAL", level: int = 5) -> Creature:
	var c := Creature.new()
	c.name = "HERO"
	c.type = p_type
	c.max_hp = 20
	c.hp = 20
	c.attack = 6
	c.defense = 4
	c.level = level
	c.exp = 0
	return c


func test_first_win_levels_a_starter() -> void:
	var hero := _creature()
	Learnset.ensure_moves(hero)
	var wild := _creature(&"GRASS", 5)
	wild.max_hp = 20
	var before := hero.level
	var report := Leveling.grant_exp(hero, wild)
	assert_true(int(report["gained"]) > 0)
	assert_true(hero.level > before, "one grassland win should level a Lv5 starter")
	assert_eq(hero.max_hp, 22)
	assert_eq(hero.attack, 7)


func test_learn_quick_post_already_seeded() -> void:
	var hero := _creature(&"NORMAL", 5)
	Learnset.ensure_moves(hero)
	assert_eq(hero.known_move_ids.size(), 3)
	assert_eq(String(hero.known_move_ids[0]), "tackle")
	assert_eq(String(hero.known_move_ids[2]), "quick_post")


func test_level_8_learns_hard_refresh() -> void:
	var hero := _creature(&"NORMAL", 7)
	Learnset.ensure_moves(hero)
	var step := Leveling.apply_level_up(hero)
	assert_eq(hero.level, 8)
	assert_eq(String(step["learned"]), "hard_refresh")
	assert_eq(String(step["replaced"]), "")
	var last := String(hero.known_move_ids[hero.known_move_ids.size() - 1])
	assert_eq(last, "hard_refresh")


func test_fifth_move_uninstalls_oldest() -> void:
	var hero := _creature(&"NORMAL", 11)
	Learnset.ensure_moves(hero)
	assert_eq(hero.known_move_ids.size(), BattleConfig.MAX_MOVES)
	var step := Leveling.apply_level_up(hero)
	assert_eq(hero.level, 12)
	assert_eq(String(step["learned"]), "ratio")
	assert_eq(String(step["replaced"]), "tackle")
	assert_eq(hero.known_move_ids.size(), BattleConfig.MAX_MOVES)
	assert_false(Array(hero.known_move_ids).has("tackle"))


func test_exp_needed_grows() -> void:
	assert_true(Leveling.exp_needed(6) > Leveling.exp_needed(5))


func test_fainted_winner_gains_nothing() -> void:
	var hero := _creature()
	hero.hp = 0
	var wild := _creature(&"ROCK", 5)
	var report := Leveling.grant_exp(hero, wild)
	assert_eq(int(report["gained"]), 0)
	assert_eq(hero.level, 5)
