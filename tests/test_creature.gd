extends TestCase
## Creature is a Resource with the PRD §4 fields; make_instance() yields a healed copy.

func _definition() -> Creature:
	var c := Creature.new()
	c.id = 1
	c.name = "Emberfox"
	c.type = &"FIRE"
	c.max_hp = 30
	c.hp = 5
	c.attack = 8
	c.defense = 5
	c.catch_rate = 0.35
	return c

func test_has_prd_fields() -> void:
	var c := _definition()
	assert_eq(c.name, "Emberfox")
	assert_eq(c.type, &"FIRE")
	assert_eq(c.attack, 8)
	assert_eq(c.catch_rate, 0.35)

func test_make_instance_is_a_healed_copy() -> void:
	var def := _definition()
	var inst := def.make_instance()
	assert_ne(inst, def, "instance must be a distinct object")
	assert_eq(inst.hp, 30, "instance starts at full hp")
	assert_eq(def.hp, 5, "definition untouched")
	assert_eq(inst.name, "Emberfox")

func test_is_fainted() -> void:
	var c := _definition()
	assert_false(c.is_fainted())
	c.hp = 0
	assert_true(c.is_fainted())
