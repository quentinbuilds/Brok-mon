extends TestCase
## Menu presentation and navigation stay isolated from core gameplay logic.

var menu: Node

func before_each() -> void:
	GameData.reset()
	menu = load("res://menu/MenuState.tscn").instantiate()
	tree.root.add_child(menu)
	menu.enter({})

func after_each() -> void:
	menu.free()

func test_main_menu_uses_the_studio_asset() -> void:
	assert_eq(menu.get_node("Backdrop").texture.resource_path, "res://assets/studio/battle_menu.png")
	assert_true(menu.get_node("MainPage/Button0/Label").text.contains("PARTY"))
	assert_true(menu.get_node("MainPage/Button1/Label").text.contains("INVENTORY"))

func test_main_cursor_wraps_in_two_by_two_grid() -> void:
	menu._move_cursor(Vector2i.LEFT)
	assert_eq(menu.selection, 1)
	menu._move_cursor(Vector2i.UP)
	assert_eq(menu.selection, 3)

func test_party_page_shows_active_creature_and_hp() -> void:
	menu.selection = 0
	menu._activate()
	assert_eq(menu.page, menu.Page.PARTY)
	var body: String = menu.get_node("DetailPage/Body").text
	assert_true(body.contains("*"), "active creature marker")
	assert_true(body.contains("HP"))

func test_party_selection_equips_through_game_data() -> void:
	var second: Creature = load("res://creatures/data/emberfox.tres").make_instance()
	GameData.add_to_party(second)
	menu.selection = 0
	menu._activate()
	menu._move_cursor(Vector2i.DOWN)
	menu._activate()
	assert_eq(GameData.active_index, 1)

func test_inventory_page_shows_existing_counts() -> void:
	menu.selection = 1
	menu._activate()
	assert_eq(menu.page, menu.Page.INVENTORY)
	var body: String = menu.get_node("DetailPage/Body").text
	assert_true(body.contains("CAPTURE ORBS"))
	assert_true(body.contains("x%02d" % GameData.get_item_count(GameData.ITEM_CAPTURE_ORB)))
	assert_true(body.contains("POTIONS"))

func test_back_returns_from_detail_to_main() -> void:
	menu.selection = 1
	menu._activate()
	menu._back()
	assert_eq(menu.page, menu.Page.MAIN)
	assert_true(menu.get_node("MainPage").visible)
