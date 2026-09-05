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
	var card: Panel = menu.get_node("DetailPage/Option0")
	assert_true(card.visible)
	assert_true(card.get_node("Label").text.contains("ACTIVE"))
	assert_true(card.get_node("Label").text.contains("HP"))

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
	var first: String = menu.get_node("DetailPage/Option0/Label").text
	var second: String = menu.get_node("DetailPage/Option1/Label").text
	assert_true(first.contains("CAPTURE ORB"))
	assert_true(first.contains("x%02d" % GameData.get_item_count(GameData.ITEM_CAPTURE_ORB)))
	assert_true(second.contains("POTION"))
	assert_eq(menu.get_node("DetailPage/Option0/Icon").texture.resource_path, "res://assets/ui/capture_orb.png")
	assert_eq(menu.get_node("DetailPage/Option1/Icon").texture.resource_path, "res://assets/ui/potion.png")

func test_selection_uses_visible_arrow_without_green_highlight() -> void:
	var arrow: Control = menu.get_node("SelectionArrow")
	assert_true(arrow.visible)
	assert_eq(arrow.get_child_count(), 2, "outlined pixel arrow")
	assert_eq(menu.get_node("MainPage/Button0").self_modulate, menu.PANEL_COLOR)
	menu._move_cursor(Vector2i.RIGHT)
	assert_eq(menu.get_node("MainPage/Button1").self_modulate, menu.PANEL_COLOR)
	var before := arrow.position
	menu._animate_cursor(0.1)
	assert_ne(arrow.position, before, "arrow slides/bobs instead of static highlight")

func test_save_opens_requested_studio_dialogue_without_changing_data() -> void:
	var before_party := GameData.party.duplicate()
	var before_inventory := GameData.inventory.duplicate()
	menu.selection = 2
	menu._activate()
	assert_true(menu.dialog_open)
	assert_eq(menu.get_node("Dialog/Text").text, menu.SAVE_LINE)
	assert_eq(menu.get_node("Dialog").get_child(0).texture.resource_path, "res://assets/studio/dialogue_box.png")
	assert_eq(GameData.party, before_party)
	assert_eq(GameData.inventory, before_inventory)

func test_inventory_options_are_selectable_and_open_descriptions() -> void:
	menu.selection = 1
	menu._activate()
	menu._move_cursor(Vector2i.DOWN)
	assert_eq(menu.inventory_selection, 1)
	menu._activate()
	assert_true(menu.dialog_open)
	assert_true(menu.get_node("Dialog/Text").text.contains("Potion:"))

func test_back_returns_from_detail_to_main() -> void:
	menu.selection = 1
	menu._activate()
	menu._back()
	assert_eq(menu.page, menu.Page.MAIN)
	assert_true(menu.get_node("MainPage").visible)
