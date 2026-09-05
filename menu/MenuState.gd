extends GameStateBase
## Studio-styled pause menu. This state presents existing GameData through established APIs.

enum Page { MAIN, PARTY, INVENTORY }

const MAIN_LABELS := ["PARTY", "INVENTORY", "SOUND TEST", "CLOSE"]
const PANEL_IDLE := Color("78a8ad")
const PANEL_SELECTED := Color("78b568")

@onready var _main_page: Control = $MainPage
@onready var _detail_page: Control = $DetailPage
@onready var _detail_title: Label = $DetailPage/Title
@onready var _detail_body: Label = $DetailPage/Body
@onready var _hint: Label = $Hint

var page: Page = Page.MAIN
var selection: int = 0
var party_selection: int = 0

func _on_enter() -> void:
	page = Page.MAIN
	selection = 0
	party_selection = clampi(GameData.active_index, 0, maxi(GameData.party.size() - 1, 0))
	EventBus.menu_opened.emit()
	AudioManager.play_sfx("menu")
	_refresh()

func exit() -> void:
	EventBus.menu_closed.emit()

func update(_delta: float) -> void:
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
		var position := Vector2i(selection % 2, selection / 2)
		if direction.x != 0:
			position.x = posmod(position.x + direction.x, 2)
		elif direction.y != 0:
			position.y = posmod(position.y + direction.y, 2)
		selection = position.y * 2 + position.x
	elif page == Page.PARTY and not GameData.party.is_empty() and direction.y != 0:
		party_selection = posmod(party_selection + direction.y, GameData.party.size())
	else:
		return
	AudioManager.play_sfx("menu")
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
				GameState.transition_to(GameState.State.SOUND_TEST)
			3:
				_close(false)
	elif page == Page.PARTY and party_selection < GameData.party.size():
		GameData.set_active(party_selection)
	_refresh()

func _back() -> void:
	AudioManager.play_sfx("cancel")
	if page == Page.MAIN:
		_close(false)
	else:
		page = Page.MAIN
		_refresh()

func _close(play_sound: bool = true) -> void:
	if play_sound:
		AudioManager.play_sfx("cancel")
	GameState.transition_to(GameState.State.OVERWORLD)

func _refresh() -> void:
	_main_page.visible = page == Page.MAIN
	_detail_page.visible = page != Page.MAIN
	if page == Page.MAIN:
		for i in MAIN_LABELS.size():
			var panel := _main_page.get_node("Button%d" % i) as Panel
			var label := panel.get_node("Label") as Label
			# Tint only the panel so the cream label remains high-contrast.
			panel.self_modulate = PANEL_SELECTED if i == selection else PANEL_IDLE
			label.text = ("> " if i == selection else "  ") + MAIN_LABELS[i]
		_hint.text = "A SELECT   B/C CLOSE"
	elif page == Page.PARTY:
		_refresh_party()
		_hint.text = "A EQUIP   B BACK   C CLOSE"
	else:
		_refresh_inventory()
		_hint.text = "B BACK   C CLOSE"

func _refresh_party() -> void:
	_detail_title.text = "PARTY"
	if GameData.party.is_empty():
		_detail_body.text = "NO CREATURES"
		return
	var lines: Array[String] = []
	for i in GameData.party.size():
		var creature: Creature = GameData.party[i]
		var cursor := ">" if i == party_selection else " "
		var active := "*" if i == GameData.active_index else " "
		lines.append("%s%s %-10s %-5s" % [cursor, active, creature.name.to_upper(), str(creature.type)])
		lines.append("   HP %d/%d" % [creature.hp, creature.max_hp])
	_detail_body.text = "\n".join(lines)

func _refresh_inventory() -> void:
	_detail_title.text = "INVENTORY"
	_detail_body.text = "CAPTURE ORBS   x%02d\n\nPOTIONS        x%02d" % [
		GameData.get_item_count(GameData.ITEM_CAPTURE_ORB),
		GameData.get_item_count(GameData.ITEM_POTION),
	]
