extends TestCase
## FireRed 2x3 cursor rules + list menus.


func test_action_menu_wrap_and_skip_empty() -> void:
	var m := ActionMenu.new()
	assert_eq(m.current(), ActionMenu.Action.FIGHT)
	m.move(1, 0)
	assert_eq(m.current(), ActionMenu.Action.BAG)
	m.move(1, 0)
	assert_eq(m.current(), ActionMenu.Action.PARTY)
	m.move(1, 0)
	assert_eq(m.current(), ActionMenu.Action.FIGHT)
	m.reset()
	m.move(0, 1)
	assert_eq(m.current(), ActionMenu.Action.RUN)
	m.move(1, 0)
	assert_eq(m.current(), ActionMenu.Action.RAGE)
	m.move(1, 0)
	assert_eq(m.current(), ActionMenu.Action.RUN)
	m.reset()
	for _step in 40:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			m.move(d.x, d.y)
			assert_true(m.current() != -1)


func test_party_label_not_trademark() -> void:
	assert_eq(ActionMenu.LABELS[ActionMenu.Action.PARTY], "PARTY")


func test_fight_menu_two_by_two() -> void:
	var m := FightMenu.new()
	m.set_moves([
		MoveDex.get_move(&"tackle"),
		MoveDex.get_move(&"ember"),
		MoveDex.get_move(&"vine_whip"),
		MoveDex.get_move(&"water_gun"),
	])
	assert_eq(m.current().id, &"tackle")
	m.move(1, 0)
	assert_eq(m.current().id, &"ember")
	m.move(0, 1)
	assert_eq(m.current().id, &"water_gun")
	m.move(-1, 0)
	assert_eq(m.current().id, &"vine_whip")


func test_list_menu_window() -> void:
	var m := ListMenu.new()
	assert_true(m.is_empty())
	m.set_items([
		{"id": &"a", "name": "ORB", "count": 5},
		{"id": &"b", "name": "POTION", "count": 3},
		{"id": &"c", "name": "ROPE", "count": 1},
	])
	assert_eq(m.current()["id"], &"a")
	m.move(1)
	assert_eq(m.current()["id"], &"b")
	assert_eq(m.visible_rows().size(), 2)
