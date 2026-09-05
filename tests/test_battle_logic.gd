extends TestCase
## Pure battle maths.


func _creature(hp: int, atk: int, defense: int) -> Creature:
	var c := Creature.new()
	c.name = "TEST"
	c.max_hp = hp
	c.hp = hp
	c.attack = atk
	c.defense = defense
	return c


func test_compute_damage_base() -> void:
	assert_eq(BattleLogic.compute_damage(10, 10, 4, 1.0), 8)


func test_compute_damage_floors() -> void:
	assert_eq(BattleLogic.compute_damage(1, 1, 100, 1.0), BattleConfig.MIN_DAMAGE)


func test_rage_multipliers_change_damage() -> void:
	var base := BattleLogic.compute_damage(10, 10, 4, 1.0, 1.0, 1.0)
	assert_true(BattleLogic.compute_damage(10, 10, 4, 1.0, 1.5, 1.0) > base)
	assert_true(BattleLogic.compute_damage(10, 10, 4, 1.0, 1.0, 0.5) > base)


func test_run_chance_improves() -> void:
	assert_eq(BattleLogic.run_chance(0), BattleConfig.RUN_BASE_CHANCE)
	assert_true(BattleLogic.run_chance(1) > BattleLogic.run_chance(0))
	assert_eq(BattleLogic.run_chance(99), BattleConfig.RUN_CHANCE_MAX)


func test_resolve_attack_applies_damage() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var atk := _creature(30, 10, 5)
	var defense := _creature(30, 10, 4)
	var move := BattleMove.make(&"t", "TACKLE", &"NORMAL", 10, 1.0)
	var before := defense.hp
	var result := BattleLogic.resolve_attack(atk, defense, move, rng)
	assert_true(result.hit)
	assert_eq(defense.hp, before - result.damage)
	defense.hp = 2
	var lethal := BattleLogic.resolve_attack(atk, defense, move, rng)
	assert_eq(defense.hp, 0)
	assert_eq(lethal.damage, 2)
	assert_true(lethal.fainted)


func test_default_move_by_type() -> void:
	var fire := Creature.new()
	fire.type = &"FIRE"
	assert_eq(BattleLogic.default_move(fire).name, "EMBER")
