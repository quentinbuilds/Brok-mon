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
	assert_eq(c.level, 5)
	assert_eq(c.exp, 0)
	assert_eq(c.known_move_ids.size(), 0)

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


## Two creatures shipped with 16x16 programmer-art placeholders while the rest used full Studio
## art, so a couple of them showed up in battle as green blocks. The battle stretches whatever
## texture it is given into a square rect, so anything this small reads as a cube.
func test_no_creature_still_has_placeholder_art() -> void:
	var dir := DirAccess.open("res://creatures/data")
	assert_ne(dir, null, "creature data is missing")
	dir.list_dir_begin()
	var file := dir.get_next()
	var checked := 0
	while file != "":
		if file.ends_with(".tres"):
			var creature: Creature = load("res://creatures/data/%s" % file)
			assert_ne(creature.sprite, null, "%s has no sprite" % file)
			var size := creature.sprite.get_size()
			assert_true(size.x >= 64 and size.y >= 64,
				"%s uses %dx%d placeholder art" % [file, int(size.x), int(size.y)])
			checked += 1
		file = dir.get_next()
	assert_true(checked >= 5, "checked the whole roster, got %d" % checked)
