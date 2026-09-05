extends GameStateBase
## Studio-styled pause menu. Presentation only; gameplay data stays owned by GameData.

enum Page { MAIN, PARTY, INVENTORY }

const MAIN_LABELS := ["PARTY", "INVENTORY", "SAVE", "CLOSE"]
const SAVE_LINE := "Save the game from who? You? Huh dumbass"
const PANEL_COLOR := Color("78a8ad")
const ARROW_POSITIONS := [Vector2(3, 25), Vector2(95, 25), Vector2(3, 66), Vector2(95, 66)]

@onready var _main_page: Control = $MainPage
@onready var _detail_page: Panel = $DetailPage
@onready var _detail_title: Label = $DetailPage/Title
@onready var _detail_body: Label = $DetailPage/Body
@onready var _hint: Label = $Hint

var page: Page = Page.MAIN
var selection := 0
var party_selection := 0
var inventory_selection := 0
var dialog_open := false
var _input_lock := 0.0
var _cursor_phase := 0.0
var _cursor_target := Vector2.ZERO
var _cursor: Control
var _option_panels: Array[Panel] = []
var _dialog: Control
var _dialog_label: Label

func _ready() -> void:
	_build_cursor()
	_build_option_panels()
	_build_dialog()

func _on_enter() -> void:
	_input_lock = 0.12 # Escape is B + Menu; do not consume opening press.
	page = Page.MAIN
	selection = 0
	party_selection = clampi(GameData.active_index, 0, maxi(GameData.party.size() - 1, 0))
	inventory_selection = 0
	dialog_open = false
	EventBus.menu_opened.emit()
	AudioManager.play_sfx("menu")
	_refresh()

func exit() -> void:
	EventBus.menu_closed.emit()

func update(delta: float) -> void:
	_animate_cursor(delta)
	if _input_lock > 0.0:
		_input_lock -= delta
		return
	if dialog_open:
		if InputManager.button_a_just_pressed() or InputManager.button_b_just_pressed():
			AudioManager.play_sfx("cancel")
			dialog_open = false
			_refresh()
		elif InputManager.button_menu_just_pressed():
			_close()
		return
	var direction := InputManager.direction_just_pressed()
	if direction != Vector2i.ZERO:
		_move_cursor(direction)
	if InputManager.button_a_just_pressed():
		_activate()
	elif InputManager.button_menu_just_pressed():
		_close()
	elif InputManager.button_b_just_pressed():
		_back()

func _move_cursor(direction: Vector2i) -> void:
	if page == Page.MAIN:
		var grid := Vector2i(selection % 2, selection / 2)
		if direction.x != 0:
			grid.x = posmod(grid.x + direction.x, 2)
		elif direction.y != 0:
			grid.y = posmod(grid.y + direction.y, 2)
		selection = grid.y * 2 + grid.x
	elif page == Page.PARTY and not GameData.party.is_empty() and direction.y != 0:
		party_selection = posmod(party_selection + direction.y, GameData.party.size())
	elif page == Page.INVENTORY and direction.y != 0:
		inventory_selection = posmod(inventory_selection + direction.y, 2)
	else:
		return
	AudioManager.play_sfx("menu")
	_cursor_phase = 0.0
	_refresh()

func _activate() -> void:
	AudioManager.play_sfx("confirm")
	if page == Page.MAIN:
		match selection:
			0:
				page = Page.PARTY
				party_selection = clampi(GameData.active_index, 0, maxi(GameData.party.size() - 1, 0))
			1:
				page = Page.INVENTORY
			2:
				_show_dialog(SAVE_LINE)
			3:
				_close(false)
	elif page == Page.PARTY and party_selection < GameData.party.size():
		GameData.set_active(party_selection)
	elif page == Page.INVENTORY:
		_show_inventory_dialog()
	_refresh()

func _back() -> void:
	AudioManager.play_sfx("cancel")
	if page == Page.MAIN:
		_close(false)
	else:
		page = Page.MAIN
		_refresh()

func _close(play_sound := true) -> void:
	if play_sound:
		AudioManager.play_sfx("cancel")
	GameState.transition_to(GameState.State.OVERWORLD)

func _refresh() -> void:
	_main_page.visible = page == Page.MAIN and not dialog_open
	_detail_page.visible = page != Page.MAIN and not dialog_open
	_dialog.visible = dialog_open
	_cursor.visible = not dialog_open
	for panel in _option_panels:
		panel.visible = false
	if dialog_open:
		_hint.text = "A/B BACK   C CLOSE"
		return
	if page == Page.MAIN:
		for i in MAIN_LABELS.size():
			var panel := _main_page.get_node("Button%d" % i) as Panel
			panel.self_modulate = PANEL_COLOR
			(panel.get_node("Label") as Label).text = MAIN_LABELS[i]
		_cursor_target = ARROW_POSITIONS[selection]
		_hint.text = "A SELECT   B/C CLOSE"
	elif page == Page.PARTY:
		_refresh_party()
		_hint.text = "A EQUIP   B BACK   C CLOSE"
	else:
		_refresh_inventory()
		_hint.text = "A INFO   B BACK   C CLOSE"

func _refresh_party() -> void:
	_detail_title.text = "PARTY"
	_detail_body.visible = GameData.party.is_empty()
	_detail_body.text = "NO CREATURES"
	for i in GameData.party.size():
		var creature: Creature = GameData.party[i]
		var active := "  ACTIVE" if i == GameData.active_index else ""
		_set_option(i, "%s  %s%s\nHP %d/%d" % [creature.name.to_upper(), str(creature.type), active, creature.hp, creature.max_hp])
	_cursor_target = Vector2(9, 24 + party_selection * 25)

func _refresh_inventory() -> void:
	_detail_title.text = "INVENTORY"
	_detail_body.visible = false
	_set_option(0, "CAPTURE ORB             x%02d" % GameData.get_item_count(GameData.ITEM_CAPTURE_ORB))
	_set_option(1, "POTION                  x%02d" % GameData.get_item_count(GameData.ITEM_POTION))
	_cursor_target = Vector2(9, 32 + inventory_selection * 34)

func _show_inventory_dialog() -> void:
	if inventory_selection == 0:
		_show_dialog("Capture Orb: used during encounters. You have x%02d." % GameData.get_item_count(GameData.ITEM_CAPTURE_ORB))
	else:
		_show_dialog("Potion: restores health during battle. You have x%02d." % GameData.get_item_count(GameData.ITEM_POTION))

func _show_dialog(text: String) -> void:
	dialog_open = true
	_dialog_label.text = text

func _set_option(index: int, text: String) -> void:
	var panel := _option_panels[index]
	panel.visible = true
	(panel.get_node("Label") as Label).text = text
	if page == Page.PARTY:
		panel.position = Vector2(18, 22 + index * 25)
		panel.size = Vector2(164, 23)
	else:
		panel.position = Vector2(18, 30 + index * 34)
		panel.size = Vector2(164, 28)

func _animate_cursor(delta: float) -> void:
	_cursor_phase += delta * 8.0
	var bob := 2.0 if posmod(int(_cursor_phase * 4.0), 2) == 0 else 0.0
	_cursor.position = _cursor.position.lerp(_cursor_target + Vector2(bob, 0), minf(delta * 18.0, 1.0)).round()
	var pulse := 0.82 + sin(_cursor_phase * 2.0) * 0.18
	_cursor.modulate.a = pulse

func _build_cursor() -> void:
	_cursor = Control.new()
	_cursor.name = "SelectionArrow"
	_cursor.size = Vector2(9, 12)
	_cursor.z_index = 20
	var shadow := Polygon2D.new()
	shadow.position = Vector2(1, 1)
	shadow.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 10), Vector2(8, 5)])
	shadow.color = Color("102044")
	_cursor.add_child(shadow)
	var face := Polygon2D.new()
	face.polygon = PackedVector2Array([Vector2(0, 1), Vector2(0, 9), Vector2(7, 5)])
	face.color = Color("ffe8a0")
	_cursor.add_child(face)
	add_child(_cursor)

func _build_option_panels() -> void:
	var style := (_main_page.get_node("Button0") as Panel).get_theme_stylebox("panel")
	for i in 3:
		var panel := Panel.new()
		panel.name = "Option%d" % i
		panel.add_theme_stylebox_override("panel", style)
		panel.self_modulate = PANEL_COLOR
		var label := Label.new()
		label.name = "Label"
		label.position = Vector2(7, 2)
		label.size = Vector2(150, 20)
		label.add_theme_color_override("font_color", Color("ffe8a0"))
		label.add_theme_font_size_override("font_size", 7)
		panel.add_child(label)
		_detail_page.add_child(panel)
		_option_panels.append(panel)

func _build_dialog() -> void:
	_dialog = Control.new()
	_dialog.name = "Dialog"
	_dialog.z_index = 30
	var texture := TextureRect.new()
	texture.position = Vector2(3, 22)
	texture.size = Vector2(194, 92)
	texture.texture = load("res://assets/studio/dialogue_box.png")
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	_dialog.add_child(texture)
	_dialog_label = Label.new()
	_dialog_label.name = "Text"
	_dialog_label.position = Vector2(16, 40)
	_dialog_label.size = Vector2(168, 52)
	_dialog_label.add_theme_color_override("font_color", Color("102044"))
	_dialog_label.add_theme_font_size_override("font_size", 9)
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog.add_child(_dialog_label)
	add_child(_dialog)
