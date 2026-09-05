extends TestCase
## Encounters: the creature pool, the per-step roll, the cooldown, and the handoff to core.

const CreaturePool := preload("res://encounters/CreaturePool.gd")
const EncounterScript := preload("res://encounters/EncounterSystem.gd")

var world: Node
var overlay: Node

func _gs() -> Node:
	return tree.root.get_node("GameState")

## Encounters only roll in OVERWORLD, so put core there for the duration of each test.
func before_each() -> void:
	world = Node.new()
	overlay = Node.new()
	tree.root.add_child(world)
	tree.root.add_child(overlay)
	_gs().bind(world, overlay)
	_gs().transition_to(GameState.State.TITLE)
	_gs().transition_to(GameState.State.OVERWORLD)

func after_each() -> void:
	_gs().unbind()
	world.free()
	overlay.free()

## A system driven directly, so the overworld's own instance cannot interfere.
func _system(seed_value: int = 1) -> Node:
	var s := EncounterScript.new()
	s.rng.seed = seed_value
	return s

## A triggered encounter sends core to BATTLE, and the system deliberately refuses to roll
## outside OVERWORLD. Any test that wants a second encounter has to come back first.
func _back_to_overworld() -> void:
	if _gs().current == GameState.State.BATTLE:
		_gs().transition_to(GameState.State.OVERWORLD)

# --- creature pool ---

func test_pool_loads_every_definition() -> void:
	var pool := CreaturePool.new()
	assert_eq(pool.size(), CreaturePool.POOL.size())
	assert_true(pool.size() >= 3, "PRD asks for 3-5 creatures, got %d" % pool.size())
	assert_true(pool.size() <= 5)

func test_definitions_are_complete_and_distinct() -> void:
	var pool := CreaturePool.new()
	var ids := {}
	var names := {}
	for c in pool.get_definitions():
		assert_ne(c.name, "", "every creature needs a name")
		assert_ne(c.sprite, null, "%s has no sprite" % c.name)
		assert_ne(c.type, &"", "%s has no type" % c.name)
		assert_true(c.max_hp > 0, "%s max_hp" % c.name)
		assert_eq(c.hp, c.max_hp, "%s starts healed" % c.name)
		assert_true(c.attack > 0, "%s attack" % c.name)
		assert_true(c.defense > 0, "%s defense" % c.name)
		assert_true(c.catch_rate > 0.0 and c.catch_rate <= 1.0, "%s catch_rate" % c.name)
		assert_false(ids.has(c.id), "duplicate id %d" % c.id)
		assert_false(names.has(c.name), "duplicate name %s" % c.name)
		ids[c.id] = true
		names[c.name] = true

func test_generated_creature_is_a_healed_copy_not_the_definition() -> void:
	var pool := CreaturePool.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var wild := pool.generate_wild_creature(rng)
	assert_ne(wild, null)
	assert_eq(wild.hp, wild.max_hp)
	for definition in pool.get_definitions():
		assert_ne(wild, definition, "must not hand out the shared definition")
	wild.hp = 1
	for definition in pool.get_definitions():
		assert_eq(definition.hp, definition.max_hp, "definition was mutated")

func test_generation_covers_the_whole_pool() -> void:
	var pool := CreaturePool.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var seen := {}
	for i in 2000:
		seen[pool.generate_wild_creature(rng).name] = true
	assert_eq(seen.size(), pool.size(), "every creature should be reachable, saw %s" % str(seen.keys()))

func test_generation_is_deterministic_for_a_seed() -> void:
	var pool := CreaturePool.new()
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	for i in 10:
		assert_eq(pool.generate_wild_creature(a).name, pool.generate_wild_creature(b).name)

func test_rarity_ordering_follows_the_weights() -> void:
	var pool := CreaturePool.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var counts := {}
	for i in 4000:
		var n: String = pool.generate_wild_creature(rng).name
		counts[n] = counts.get(n, 0) + 1
	assert_true(counts.get("Mossbug", 0) > counts.get("Rizzzmoth", 0),
		"the common creature should outnumber the rare one: %s" % str(counts))

# --- the roll ---

func test_step_outside_grass_never_triggers() -> void:
	var s := _system()
	s.force_next = true
	for i in 50:
		assert_false(s.try_encounter(false), "no roll outside an encounter zone")
	s.free()

func test_forced_roll_triggers_on_grass() -> void:
	var s := _system()
	s.force_next = true
	var caught: Array = []
	var handler := func(wild): caught.append(wild)
	EventBus.encounter_triggered.connect(handler)
	assert_true(s.try_encounter(true))
	EventBus.encounter_triggered.disconnect(handler)
	assert_eq(caught.size(), 1, "one encounter_triggered per encounter")
	assert_true(caught[0] is Creature)
	assert_eq(caught[0].hp, caught[0].max_hp, "wild creature arrives healed")
	s.free()

func test_force_next_is_consumed() -> void:
	var s := _system()
	s.force_next = true
	assert_true(s.try_encounter(true))
	assert_false(s.force_next, "force_next is a one-shot")
	s.free()

func test_encounter_drives_core_into_battle() -> void:
	var s := _system()
	s.force_next = true
	s.try_encounter(true)
	assert_eq(_gs().current, GameState.State.BATTLE, "core reacted to encounter_triggered")
	var wild = overlay.get_child(0).payload.get("wild")
	assert_true(wild is Creature, "the wild creature reached BATTLE in the payload")
	s.free()

func test_no_roll_outside_overworld() -> void:
	var s := _system()
	_gs().transition_to(GameState.State.MENU)
	s.force_next = true
	assert_false(s.try_encounter(true), "encounters must not fire while a menu is up")
	s.free()

# --- cooldown ---

func test_cooldown_blocks_immediately_repeated_encounters() -> void:
	var s := _system()
	s.force_next = true
	assert_true(s.try_encounter(true))
	assert_eq(s.steps_until_ready(), GameConfig.ENCOUNTER_COOLDOWN_STEPS)
	_back_to_overworld()
	for i in GameConfig.ENCOUNTER_COOLDOWN_STEPS:
		s.force_next = true
		assert_false(s.try_encounter(true), "still cooling down on step %d" % i)
	s.force_next = true
	assert_true(s.try_encounter(true), "eligible again once the cooldown is walked off")
	s.free()

func test_cooldown_counts_steps_outside_grass_too() -> void:
	var s := _system()
	s.force_next = true
	s.try_encounter(true)
	_back_to_overworld()
	for i in GameConfig.ENCOUNTER_COOLDOWN_STEPS:
		s.try_encounter(false)
	assert_eq(s.steps_until_ready(), 0)
	s.force_next = true
	assert_true(s.try_encounter(true))
	s.free()

func test_reset_cooldown_clears_it() -> void:
	var s := _system()
	s.force_next = true
	s.try_encounter(true)
	s.reset_cooldown()
	assert_eq(s.steps_until_ready(), 0)
	s.free()

# --- probability ---

func test_rate_tracks_the_configured_chance() -> void:
	# Cooldown is cleared each step so this measures the roll alone. Core is walked back to
	# OVERWORLD after every hit, otherwise the OVERWORLD-only guard stops all later rolls.
	var s := _system(2024)
	var trials := 4000
	var hits := 0
	for i in trials:
		s.reset_cooldown()
		if s.try_encounter(true):
			hits += 1
			_back_to_overworld()
	var rate := float(hits) / float(trials)
	var expected: float = GameConfig.ENCOUNTER_CHANCE
	# n=4000 gives a standard error near 0.004, so 0.02 is a wide but still meaningful band.
	assert_true(absf(rate - expected) < 0.02,
		"expected about %.2f per grass step, measured %.4f over %d steps" % [expected, rate, trials])
	s.free()

func test_configured_chance_is_in_the_prd_band() -> void:
	assert_true(GameConfig.ENCOUNTER_CHANCE >= 0.05 and GameConfig.ENCOUNTER_CHANCE <= 0.10,
		"PRD §7 asks for 5-10%% per step, got %s" % GameConfig.ENCOUNTER_CHANCE)
	assert_true(GameConfig.ENCOUNTER_COOLDOWN_STEPS > 0, "a cooldown is required")

# --- wiring ---

func test_overworld_ships_with_an_encounter_system() -> void:
	var ow = load("res://world/OverworldState.tscn").instantiate()
	var found := false
	for child in ow.get_children():
		if child.get_script() == EncounterScript:
			found = true
	assert_true(found, "OverworldState must host an EncounterSystem so encounters freeze with it")
	ow.free()

func test_player_moved_reaches_the_roll() -> void:
	var s := _system()
	tree.root.add_child(s)
	await tree.process_frame
	s.force_next = true
	var caught: Array = []
	var handler := func(wild): caught.append(wild)
	EventBus.encounter_triggered.connect(handler)
	EventBus.player_moved.emit(Vector2i(6, 4), true)
	EventBus.encounter_triggered.disconnect(handler)
	assert_eq(caught.size(), 1, "the system listens to player_moved")
	s.free()
