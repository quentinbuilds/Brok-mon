extends TestCase
## Pause menu: party, bag, save gag, exit to title, revive.


func before_each() -> void:
	GameData.reset()


func test_bag_names() -> void:
	assert_eq(MenuItems.display_name(GameData.ITEM_CAPTURE_ORB), "Capture Orb")
	assert_eq(MenuItems.display_name(GameData.ITEM_POTION), "Potion")
	assert_eq(MenuItems.display_name(GameData.ITEM_REVIVE), "Revive")
	assert_eq(MenuItems.BAG_ORDER.size(), 3)


func test_potion_heals_active() -> void:
	var c := GameData.get_active_creature()
	c.hp = 4
	var before := GameData.get_item_count(GameData.ITEM_POTION)
	var msg := MenuItems.use_potion()
	assert_true(msg.contains("recovered"))
	assert_eq(c.hp, 4 + GameConfig.POTION_HEAL)
	assert_eq(GameData.get_item_count(GameData.ITEM_POTION), before - 1)


func test_potion_refuses_fainted() -> void:
	var c := GameData.get_active_creature()
	c.hp = 0
	var before := GameData.get_item_count(GameData.ITEM_POTION)
	assert_true(MenuItems.use_potion().contains("REVIVE"))
	assert_eq(GameData.get_item_count(GameData.ITEM_POTION), before)
	assert_eq(c.hp, 0)


func test_revive_restores_full_hp() -> void:
	var c := GameData.get_active_creature()
	c.hp = 0
	var before := GameData.get_item_count(GameData.ITEM_REVIVE)
	var msg := MenuItems.use_revive()
	assert_true(msg.contains("back"))
	assert_eq(c.hp, c.max_hp)
	assert_eq(GameData.get_item_count(GameData.ITEM_REVIVE), before - 1)


func test_revive_does_nothing_when_everyone_is_up() -> void:
	var before := GameData.get_item_count(GameData.ITEM_REVIVE)
	assert_true(MenuItems.use_revive().contains("Nobody"))
	assert_eq(GameData.get_item_count(GameData.ITEM_REVIVE), before)


func test_save_is_a_gag() -> void:
	assert_true(MenuItems.SAVE_GAG.contains("battery"))


func _menu() -> MenuState:
	var packed := load("res://menu/MenuState.tscn") as PackedScene
	var node := packed.instantiate() as MenuState
	tree.root.add_child(node)
	return node


func test_root_lists_four_items() -> void:
	var menu := _menu()
	await tree.process_frame
	menu.enter({})
	assert_eq(menu.page, MenuState.Page.ROOT)
	var text: String = menu.get_node("Label").text
	assert_true(text.contains("PARTY"))
	assert_true(text.contains("BAG"))
	assert_true(text.contains("SAVE"))
	assert_true(text.contains("EXIT"))
	menu.queue_free()
	await tree.process_frame


func test_save_shows_the_gag() -> void:
	var menu := _menu()
	await tree.process_frame
	menu.enter({})
	menu.cursor = 2
	menu._confirm_root()
	assert_eq(menu.page, MenuState.Page.MESSAGE)
	assert_true(menu.get_node("Label").text.contains("battery"))
	menu.queue_free()
	await tree.process_frame
