extends GameStateBase
class_name MenuState
## Pause menu: PARTY / BAG / SAVE / EXIT. SOUND stays as a debug row.
## Keep: emit menu_opened / menu_closed; B or C on the root closes to OVERWORLD.

enum Page { ROOT, PARTY, BAG, MESSAGE, EXIT_CONFIRM }

const ROOT_ITEMS := ["PARTY", "BAG", "SAVE", "EXIT"]

@onready var _label: Label = $Label

var page: int = Page.ROOT
var cursor: int = 0
var _message := ""


func _on_enter() -> void:
	EventBus.menu_opened.emit()
	page = Page.ROOT
	cursor = 0
	_message = ""
	_refresh()


func exit() -> void:
	EventBus.menu_closed.emit()


func update(_delta: float) -> void:
	match page:
		Page.ROOT:
			_handle_root()
		Page.PARTY:
			_handle_list(_party_count(), _confirm_party)
		Page.BAG:
			_handle_list(MenuItems.BAG_ORDER.size(), _confirm_bag)
		Page.MESSAGE, Page.EXIT_CONFIRM:
			_handle_message()


func _root_items() -> PackedStringArray:
	var items := PackedStringArray(ROOT_ITEMS)
	if GameConfig.debug_keys_enabled():
		items.append("SOUND")
	return items


func _party_count() -> int:
	return GameData.party.size()


func _handle_root() -> void:
	if InputManager.button_b_just_pressed() or InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.OVERWORLD)
		return
	_move_cursor(_root_items().size())
	if InputManager.button_a_just_pressed():
		_confirm_root()


func _handle_list(count: int, on_a: Callable) -> void:
	if InputManager.button_b_just_pressed() or InputManager.button_menu_just_pressed():
		_open_root()
		return
	_move_cursor(count)
	if InputManager.button_a_just_pressed():
		on_a.call()


func _handle_message() -> void:
	if InputManager.button_b_just_pressed() or InputManager.button_menu_just_pressed():
		if page == Page.EXIT_CONFIRM:
			_open_root()
		else:
			_open_root()
		return
	if InputManager.button_a_just_pressed():
		if page == Page.EXIT_CONFIRM:
			GameState.transition_to(GameState.State.TITLE)
		else:
			_open_root()


func _move_cursor(count: int) -> void:
	if count <= 0:
		cursor = 0
		return
	var dir := InputManager.direction_just_pressed()
	if dir.y < 0:
		cursor = wrapi(cursor - 1, 0, count)
		_refresh()
	elif dir.y > 0:
		cursor = wrapi(cursor + 1, 0, count)
		_refresh()


func _confirm_root() -> void:
	var items := _root_items()
	if cursor < 0 or cursor >= items.size():
		return
	match items[cursor]:
		"PARTY":
			page = Page.PARTY
			cursor = 0
		"BAG":
			page = Page.BAG
			cursor = 0
		"SAVE":
			_show_message(MenuItems.SAVE_GAG)
		"EXIT":
			page = Page.EXIT_CONFIRM
			_message = "Quit to title?\nA: YES   B: NO"
		"SOUND":
			GameState.transition_to(GameState.State.SOUND_TEST)
			return
	_refresh()


func _confirm_party() -> void:
	if cursor < 0 or cursor >= GameData.party.size():
		return
	var c: Creature = GameData.party[cursor]
	if c == null:
		return
	if c.is_fainted():
		_show_message(MenuItems.use_revive(cursor))
		return
	if cursor == GameData.active_index:
		_show_message("%s is already out!" % c.name)
		return
	GameData.set_active(cursor)
	_show_message("Go, %s!" % c.name)


func _confirm_bag() -> void:
	if cursor < 0 or cursor >= MenuItems.BAG_ORDER.size():
		return
	var id: StringName = MenuItems.BAG_ORDER[cursor]
	match id:
		GameData.ITEM_CAPTURE_ORB:
			_show_message("Throw it in battle.")
		GameData.ITEM_POTION:
			_show_message(MenuItems.use_potion())
		GameData.ITEM_REVIVE:
			_show_message(MenuItems.use_revive())


func _open_root() -> void:
	page = Page.ROOT
	cursor = 0
	_message = ""
	_refresh()


func _show_message(text: String) -> void:
	page = Page.MESSAGE
	_message = text
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	match page:
		Page.ROOT:
			_label.text = _root_text()
		Page.PARTY:
			_label.text = _party_text()
		Page.BAG:
			_label.text = _bag_text()
		Page.MESSAGE, Page.EXIT_CONFIRM:
			_label.text = _message + "\n\nA: OK" if page == Page.MESSAGE else _message


func _root_text() -> String:
	var lines: PackedStringArray = ["MENU"]
	var items := _root_items()
	for i in items.size():
		lines.append("%s%s" % ["> " if i == cursor else "  ", items[i]])
	lines.append("")
	lines.append("A: pick   B: close")
	return "\n".join(lines)


func _party_text() -> String:
	var lines: PackedStringArray = ["PARTY"]
	if GameData.party.is_empty():
		lines.append("  --")
	for i in GameData.party.size():
		var c: Creature = GameData.party[i]
		var mark := "> " if i == cursor else "  "
		var active := "*" if i == GameData.active_index else " "
		var status := "FNT" if c.is_fainted() else "%d/%d" % [c.hp, c.max_hp]
		lines.append("%s%s%s %s" % [mark, active, c.name, status])
	lines.append("")
	lines.append("A: set/revive  B: back")
	return "\n".join(lines)


func _bag_text() -> String:
	var lines: PackedStringArray = ["BAG"]
	for i in MenuItems.BAG_ORDER.size():
		var id: StringName = MenuItems.BAG_ORDER[i]
		var mark := "> " if i == cursor else "  "
		lines.append("%s%s  x%d" % [mark, MenuItems.display_name(id), GameData.get_item_count(id)])
	lines.append("")
	lines.append("A: use   B: back")
	return "\n".join(lines)
