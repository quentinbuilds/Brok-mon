extends TestCase
## ItemCatalog is a 9-item menu-owned sheet; MenuState can show every slot.

func _data() -> Node:
	return tree.root.get_node("GameData")

func before_each() -> void:
	_data().reset()

func test_catalog_has_nine_items() -> void:
	var catalog := ItemCatalog.entries()
	assert_eq(catalog.size(), ItemCatalog.COUNT)
	assert_eq(ItemCatalog.COUNT, 9)
	assert_eq(ItemCatalog.ids().size(), 9)

func test_catalog_ids_are_unique() -> void:
	var seen := {}
	for e in ItemCatalog.entries():
		var id: StringName = e[&"id"]
		assert_false(seen.has(id), "duplicate id %s" % id)
		seen[id] = true

func test_maps_existing_core_item_ids() -> void:
	var catalog := ItemCatalog.entries()
	assert_eq(catalog[0][&"id"], GameData.ITEM_CAPTURE_ORB)
	assert_eq(catalog[0][&"name"], "Capture Orb")
	assert_eq(catalog[0][&"kind"], ItemCatalog.KIND_ORB)
	assert_eq(catalog[8][&"id"], GameData.ITEM_POTION)
	assert_eq(catalog[8][&"name"], "Tonic")
	assert_eq(catalog[8][&"kind"], ItemCatalog.KIND_TONIC)

func test_orb_and_tonic_kinds() -> void:
	var orbs := 0
	var tonics := 0
	for e in ItemCatalog.entries():
		if e[&"kind"] == ItemCatalog.KIND_ORB:
			orbs += 1
		elif e[&"kind"] == ItemCatalog.KIND_TONIC:
			tonics += 1
	assert_eq(orbs, 7)
	assert_eq(tonics, 2)

func test_sheet_exists_and_regions_fit() -> void:
	var sheet := ItemCatalog.sheet()
	assert_ne(sheet, null, "item sheet missing at %s" % ItemCatalog.SHEET_PATH)
	assert_eq(sheet.get_width(), ItemCatalog.CELL * 3)
	assert_eq(sheet.get_height(), ItemCatalog.CELL * 3)
	for e in ItemCatalog.entries():
		var r := ItemCatalog.region_of(e)
		assert_eq(r.size, Vector2(ItemCatalog.CELL, ItemCatalog.CELL))
		assert_true(r.position.x >= 0.0)
		assert_true(r.position.y >= 0.0)
		assert_true(r.end.x <= sheet.get_width())
		assert_true(r.end.y <= sheet.get_height())
		var tex := ItemCatalog.texture_for(e)
		assert_ne(tex, null)
		assert_ne(tex.atlas, null)
		assert_eq(tex.region, r)

func test_demo_seed_fills_extras_without_changing_starts() -> void:
	assert_eq(_data().get_item_count(GameData.ITEM_CAPTURE_ORB), GameConfig.START_CAPTURE_ORBS)
	assert_eq(_data().get_item_count(GameData.ITEM_POTION), GameConfig.START_POTIONS)
	ItemCatalog.ensure_demo_items()
	assert_eq(_data().get_item_count(GameData.ITEM_CAPTURE_ORB), GameConfig.START_CAPTURE_ORBS)
	assert_eq(_data().get_item_count(GameData.ITEM_POTION), GameConfig.START_POTIONS)
	for e in ItemCatalog.entries():
		var id: StringName = e[&"id"]
		if id == GameData.ITEM_CAPTURE_ORB or id == GameData.ITEM_POTION:
			continue
		assert_eq(_data().get_item_count(id), ItemCatalog.DEMO_COUNT)
	ItemCatalog.ensure_demo_items()
	assert_eq(_data().get_item_count(&"stripe_orb"), ItemCatalog.DEMO_COUNT, "seed is idempotent")

func test_menu_shows_nine_catalog_items() -> void:
	var scene := load("res://menu/MenuState.tscn") as PackedScene
	assert_ne(scene, null, "MenuState.tscn missing")
	var menu = scene.instantiate()
	tree.root.add_child(menu)
	menu.enter({})
	await tree.process_frame
	assert_eq(menu.get_slot_count(), 9)
	assert_eq(menu.get_visible_ids().size(), 9)
	assert_eq(menu.get_visible_ids()[0], GameData.ITEM_CAPTURE_ORB)
	assert_eq(menu.get_visible_ids()[8], GameData.ITEM_POTION)
	assert_true(_data().get_item_count(&"bloom_orb") > 0)
	assert_eq(menu.get_node("Canvas/ItemGrid").get_child_count(), 9)
	menu.exit()
	menu.free()
