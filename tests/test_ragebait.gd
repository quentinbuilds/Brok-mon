extends TestCase
## RAGEBAIT clamping, directions, multipliers, messages.


func test_forced_enrage_and_wary() -> void:
	var c := Creature.new()
	c.name = "BUG"
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var r := Ragebait.new()
	r.forced_direction = Ragebait.Direction.ENRAGED
	var up := r.taunt(c, rng)
	assert_eq(up.direction, Ragebait.Direction.ENRAGED)
	assert_eq(r.level, 1)
	var r2 := Ragebait.new()
	r2.forced_direction = Ragebait.Direction.WARY
	var down := r2.taunt(c, rng)
	assert_eq(down.direction, Ragebait.Direction.WARY)
	assert_eq(r2.level, -1)


func test_clamps_at_caps() -> void:
	var c := Creature.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var r := Ragebait.new()
	r.forced_direction = Ragebait.Direction.ENRAGED
	for _i in 10:
		r.taunt(c, rng)
	assert_eq(r.level, BattleConfig.RAGE_LEVEL_MAX)
	assert_true(r.taunt(c, rng).at_cap)
	var r2 := Ragebait.new()
	r2.forced_direction = Ragebait.Direction.WARY
	for _i in 10:
		r2.taunt(c, rng)
	assert_eq(r2.level, BattleConfig.RAGE_LEVEL_MIN)
	r2.reset()
	assert_eq(r2.level, 0)


func test_multipliers() -> void:
	var r := Ragebait.new()
	assert_eq(r.catch_multiplier(), 1.0)
	r.level = 2
	assert_true(r.catch_multiplier() > 1.0)
	assert_true(r.enemy_attack_multiplier() > 1.0)
	assert_true(r.enemy_defense_multiplier() < 1.0)
	r.level = -2
	assert_true(r.catch_multiplier() < 1.0)
	assert_true(r.enemy_attack_multiplier() < 1.0)
	assert_true(r.enemy_defense_multiplier() > 1.0)


func test_messages_differ() -> void:
	var c := Creature.new()
	c.name = "MOSSBUG"
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var r := Ragebait.new()
	r.forced_direction = Ragebait.Direction.ENRAGED
	var up := r.outcome_message(c.name, r.taunt(c, rng))
	var r2 := Ragebait.new()
	r2.forced_direction = Ragebait.Direction.WARY
	var down := r2.outcome_message(c.name, r2.taunt(c, rng))
	assert_true(up.contains("FURIOUS"))
	assert_true(down.contains("WARY"))
	assert_true(up != down)
	assert_true(MessageBox.wrap_lines(up).size() <= BattleConfig.TEXT_MAX_LINES)


func test_source_swappable() -> void:
	var c := Creature.new()
	var r := Ragebait.new()
	assert_true(r.source.get_line(c, 0).length() > 0)
	var custom := _CustomSource.new()
	r.source = custom
	assert_eq(r.source.get_line(c, 0), "CUSTOM")


func test_default_source_is_line_table() -> void:
	var r := Ragebait.new()
	assert_true(r.source is RagebaitSource.LineTable)


func test_line_table_varies_by_type_and_band() -> void:
	var table := RagebaitSource.LineTable.new()
	var fire := Creature.new()
	fire.name = "Emberfox"
	fire.type = &"FIRE"
	fire.id = 1
	var grass := Creature.new()
	grass.name = "Debugbug"
	grass.type = &"GRASS"
	grass.id = 2
	assert_eq(RagebaitSource.LineTable.band_for(0), "mild")
	assert_eq(RagebaitSource.LineTable.band_for(2), "hot")
	assert_eq(RagebaitSource.LineTable.band_for(3), "max")
	assert_eq(RagebaitSource.LineTable.band_for(-1), "wary")
	var mild_fire := table.get_line(fire, 0)
	var max_grass := table.get_line(grass, 3)
	assert_true(mild_fire.length() > 0)
	assert_true(max_grass.length() > 0)
	assert_true(mild_fire != max_grass)
	var fire_pool: Array = table.pool_for(fire, 0)
	var grass_pool: Array = table.pool_for(grass, 3)
	assert_true(fire_pool.has(mild_fire))
	assert_true(grass_pool.has(max_grass))


func test_every_table_line_fits_the_battle_box() -> void:
	var table := RagebaitSource.LineTable.new()
	var types := ["FIRE", "GRASS", "WATER", "ROCK", "NORMAL", "GHOST"]
	for type_name in types:
		var c := Creature.new()
		c.name = "Mossbug"
		c.type = StringName(type_name)
		c.id = type_name.length()
		for level in range(BattleConfig.RAGE_LEVEL_MIN, BattleConfig.RAGE_LEVEL_MAX + 1):
			var line := table.get_line(c, level)
			assert_true(BattleCopy.fits(BattleCopy.you_said(line)), BattleCopy.you_said(line))


class _CustomSource:
	extends RagebaitSource
	func get_line(_creature: Creature, _rage_level: int) -> String:
		return "CUSTOM"
