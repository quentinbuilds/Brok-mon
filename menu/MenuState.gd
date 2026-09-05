extends GameStateBase
## Studio-styled pause menu. Presentation only; gameplay data stays owned by GameData.

enum Page { MAIN, PARTY, INVENTORY }

## The party page is the creature list, so it is branded rather than named after the
## mechanic. Page.PARTY stays the internal name; only the label changed.
const PARTY_LABEL := "BROKEDEX"

## Brokedex card geometry. Three cards have to fit inside DetailPage, which is 95 px tall.
const PORTRAIT_SIZE := 21
const PARTY_ROW_Y := 22
const PARTY_ROW_STEP := 25
const PARTY_ROW_HEIGHT := 22

## Creature summary screen.
const STAT_ART_SIZE := 46
const STAT_BAR_OK := Color("6cc06c")
const STAT_BAR_LOW := Color("c4413f")

const MAIN_LABELS := [PARTY_LABEL, "INVENTORY", "SAVE", "CLOSE"]
const SAVE_LINE := "Save the game from who? You? Huh dumbass"
const PANEL_COLOR := Color("78a8ad")
const ARROW_POSITIONS := [Vector2(4, 25), Vector2(96, 25), Vector2(4, 66), Vector2(96, 66)]

## Studio palette, drawn rather than blitted. The backdrop used to be the whole
## battle_menu.png mockup, which has a gold selection arrow, four button labels and a green
## highlight painted into it; the panels covered the buttons, but the baked arrow sat outside
## the grid and read as a second cursor permanently stuck beside PARTY.
const FRAME_COLOR := Color(0.965, 0.894, 0.678, 1)
const FRAME_BORDER := Color(0.06, 0.11, 0.2, 1)

const DIALOGUE_SHEET := "res://assets/studio/dialogue_box.png"

## The Studio sheets carry a palette swatch bar across their first rows. Crop past it so the
## bar is not part of the frame everywhere the art is used.
const DIALOGUE_REGION := Rect2(0, 14, 1242, 577)


## The clean cream frame, without the swatch bar. Shared by the modal here and by the scene's
## Backdrop, which used to be the whole battle_menu mockup -- arrow, labels and all.
static func dialogue_frame() -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = load(DIALOGUE_SHEET)
	frame.region = DIALOGUE_REGION
	return frame

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
## Party index whose stat screen is open, or -1 for the Brokedex list.
var stats_index := -1
var _input_lock := 0.0
var _cursor_phase := 0.0
var _cursor_target := Vector2.ZERO
var _cursor: Control
var _option_panels: Array[Panel] = []
var _dialog: Control
var _dialog_label: Label
var _stats: Control
var _stats_art: TextureRect
var _stats_name: Label
var _stats_rows: Label
var _stats_bar_bg: ColorRect
var _stats_bar: ColorRect

func _ready() -> void:
	_build_cursor()
	_build_option_panels()
	_build_dialog()
	_build_stats()

func _on_enter() -> void:
	_input_lock = 0.12 # Escape is B + Menu; do not consume opening press.
	page = Page.MAIN
	selection = 0
	party_selection = clampi(GameData.active_index, 0, maxi(GameData.party.size() - 1, 0))
	inventory_selection = 0
	dialog_open = false
	stats_index = -1
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
	elif stats_index >= 0:
		return
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
		if stats_index < 0:
			stats_index = party_selection      # first A: show the creature
		else:
			GameData.set_active(stats_index)   # second A: make it the active one
	elif page == Page.INVENTORY:
		_show_inventory_dialog()
	_refresh()

func _back() -> void:
	AudioManager.play_sfx("cancel")
	if stats_index >= 0:
		stats_index = -1
		_refresh()
	elif page == Page.MAIN:
		_close(false)
	else:
		page = Page.MAIN
		_refresh()

func _close(play_sound := true) -> void:
	if play_sound:
		AudioManager.play_sfx("cancel")
	GameState.transition_to(GameState.State.OVERWORLD)

func _refresh() -> void:
	var on_stats := stats_index >= 0 and not dialog_open
	_main_page.visible = page == Page.MAIN and not dialog_open and not on_stats
	_detail_page.visible = page != Page.MAIN and not dialog_open and not on_stats
	_dialog.visible = dialog_open
	_stats.visible = on_stats
	_cursor.visible = not dialog_open and not on_stats
	if on_stats:
		_refresh_stats()
		_hint.text = "A SET ACTIVE   B BACK"
		return
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
	_detail_title.text = PARTY_LABEL
	_detail_body.visible = GameData.party.is_empty()
	_detail_body.text = "NO CREATURES"
	for i in GameData.party.size():
		var creature: Creature = GameData.party[i]
		var active := "  ACTIVE" if i == GameData.active_index else ""
		_set_option(i, "%s   %d/%d%s" % [creature.name.to_upper(), creature.hp, creature.max_hp, active])
	# The page was text only, which is not much of a creature screen.
	for i in GameData.party.size():
		var icon := _option_panels[i].get_node("Icon") as TextureRect
		icon.texture = GameData.party[i].sprite
		icon.visible = icon.texture != null
	_cursor_target = Vector2(9, PARTY_ROW_Y + party_selection * PARTY_ROW_STEP)

func _refresh_inventory() -> void:
	_detail_title.text = "INVENTORY"
	_detail_body.visible = false
	_set_option(0, "CAPTURE ORB             x%02d" % GameData.get_item_count(GameData.ITEM_CAPTURE_ORB))
	_set_option(1, "POTION                  x%02d" % GameData.get_item_count(GameData.ITEM_POTION))
	(_option_panels[0].get_node("Icon") as TextureRect).texture = load("res://assets/ui/capture_orb.png")
	(_option_panels[1].get_node("Icon") as TextureRect).texture = load("res://assets/ui/potion.png")
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
	var label := panel.get_node("Label") as Label
	var icon := panel.get_node("Icon") as TextureRect
	label.text = text
	icon.visible = page == Page.INVENTORY
	if page == Page.PARTY:
		# Tall enough for the name line and the HP line; the HP line used to spill out
		# of the bottom of the card.
		panel.position = Vector2(18, PARTY_ROW_Y - 2 + index * PARTY_ROW_STEP)
		panel.size = Vector2(164, PARTY_ROW_HEIGHT)
		icon.position = Vector2(3, 0)
		icon.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
		label.position = Vector2(PORTRAIT_SIZE + 7, 4)
		label.size = Vector2(164 - PORTRAIT_SIZE - 11, PARTY_ROW_HEIGHT - 8)
	else:
		panel.position = Vector2(18, 30 + index * 34)
		panel.size = Vector2(164, 28)
		icon.position = Vector2(3, 6)
		icon.size = Vector2(16, 16)
		label.position = Vector2(23 if icon.visible else 7, 2)
		label.size = Vector2(150, 20)

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
	# Navy on the cream frame, not cream: the arrow used to be the same colour as the panel it
	# sits on and all you could see was its one-pixel outline.
	var halo := Polygon2D.new()
	halo.position = Vector2(1, 1)
	halo.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 10), Vector2(8, 5)])
	halo.color = Color("ffe8a0")
	_cursor.add_child(halo)
	var face := Polygon2D.new()
	face.polygon = PackedVector2Array([Vector2(0, 1), Vector2(0, 9), Vector2(7, 5)])
	face.color = Color("102044")
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
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.position = Vector2(3, 6)
		icon.size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.visible = false
		panel.add_child(icon)
		_detail_page.add_child(panel)
		_option_panels.append(panel)

func _build_dialog() -> void:
	_dialog = Control.new()
	_dialog.name = "Dialog"
	_dialog.z_index = 30
	var texture := TextureRect.new()
	texture.position = Vector2(3, 22)
	texture.size = Vector2(194, 92)
	texture.texture = dialogue_frame()
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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


## Creature summary: the art, who it is, and the numbers behind it. Opened by pressing A on a
## Brokedex row; a second A makes that creature the active one.
func _refresh_stats() -> void:
	if stats_index < 0 or stats_index >= GameData.party.size():
		stats_index = -1
		return
	var c: Creature = GameData.party[stats_index]
	_stats_art.texture = c.sprite
	_stats_art.visible = c.sprite != null
	var active := "  ACTIVE" if stats_index == GameData.active_index else ""
	_stats_name.text = "%s%s" % [c.name.to_upper(), active]
	# Level and type live here rather than under the name, where the second line landed on
	# top of the artwork.
	_stats_rows.text = "Lv %d      %s
HP        %d/%d
ATTACK    %d
DEFENSE   %d
EXP       %d" % [
		c.level, str(c.type), c.hp, c.max_hp, c.attack, c.defense, c.exp]
	var frac := float(c.hp) / float(c.max_hp) if c.max_hp > 0 else 0.0
	_stats_bar.size = Vector2(round(_stats_bar_bg.size.x * clampf(frac, 0.0, 1.0)), _stats_bar_bg.size.y)
	_stats_bar.color = STAT_BAR_OK if frac > 0.25 else STAT_BAR_LOW


func _build_stats() -> void:
	_stats = Control.new()
	_stats.name = "Stats"
	_stats.z_index = 25
	var frame := Panel.new()
	frame.name = "Frame"
	frame.add_theme_stylebox_override("panel", (_main_page.get_node("Button0") as Panel).get_theme_stylebox("panel"))
	frame.self_modulate = PANEL_COLOR
	frame.position = Vector2(8, 8)
	frame.size = Vector2(184, 95)
	_stats.add_child(frame)

	_stats_art = TextureRect.new()
	_stats_art.name = "Art"
	_stats_art.position = Vector2(14, 26)
	_stats_art.size = Vector2(STAT_ART_SIZE, STAT_ART_SIZE)
	_stats_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stats_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stats_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_stats.add_child(_stats_art)

	_stats_name = Label.new()
	_stats_name.name = "Who"
	_stats_name.position = Vector2(14, 11)
	_stats_name.size = Vector2(170, 11)
	_stats_name.add_theme_color_override("font_color", Color("ffe8a0"))
	_stats_name.add_theme_font_size_override("font_size", 7)
	_stats.add_child(_stats_name)

	# HP bar under the art, so low health reads at a glance rather than only as a number.
	_stats_bar_bg = ColorRect.new()
	_stats_bar_bg.name = "BarBg"
	_stats_bar_bg.position = Vector2(14, 26 + STAT_ART_SIZE + 3)
	_stats_bar_bg.size = Vector2(STAT_ART_SIZE, 4)
	_stats_bar_bg.color = Color("102044")
	_stats.add_child(_stats_bar_bg)
	_stats_bar = ColorRect.new()
	_stats_bar.name = "Bar"
	_stats_bar.position = _stats_bar_bg.position
	_stats_bar.size = _stats_bar_bg.size
	_stats_bar.color = STAT_BAR_OK
	_stats.add_child(_stats_bar)

	_stats_rows = Label.new()
	_stats_rows.name = "Rows"
	_stats_rows.position = Vector2(14 + STAT_ART_SIZE + 10, 24)
	_stats_rows.size = Vector2(184 - STAT_ART_SIZE - 30, 76)
	_stats_rows.add_theme_color_override("font_color", Color("ffe8a0"))
	_stats_rows.add_theme_font_size_override("font_size", 7)
	_stats.add_child(_stats_rows)
	add_child(_stats)
