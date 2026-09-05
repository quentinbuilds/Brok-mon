extends GameStateBase
## Party summary plus a 3x3 inventory grid. Person 6 may restyle.
## Keep: emit menu_opened / menu_closed; B or menu key closes back to OVERWORLD.

const ICON := 20
const SLOT := 22

@onready var _party_label: Label = $Canvas/PartyLabel
@onready var _grid: GridContainer = $Canvas/ItemGrid
@onready var _detail_label: Label = $Canvas/DetailLabel

var _cursor: int = 0
var _slots: Array[ColorRect] = []
var _icons: Array[TextureRect] = []

func _on_enter() -> void:
	EventBus.menu_opened.emit()
	ItemCatalog.ensure_demo_items()
	if _slots.is_empty():
		_build_slots()
	_cursor = 0
	_refresh()

func exit() -> void:
	EventBus.menu_closed.emit()

func update(_delta: float) -> void:
	if InputManager.button_b_just_pressed() or InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.OVERWORLD)
		return
	var d := InputManager.direction_just_pressed()
	if d == Vector2i.ZERO:
		return
	var next := _cursor + d.x + d.y * 3
	if next >= 0 and next < ItemCatalog.COUNT:
		_cursor = next
		_refresh()

func get_slot_count() -> int:
	return _slots.size()

func get_visible_ids() -> Array[StringName]:
	return ItemCatalog.ids()

func _build_slots() -> void:
	var catalog := ItemCatalog.entries()
	for i in catalog.size():
		var frame := ColorRect.new()
		frame.custom_minimum_size = Vector2(SLOT, SLOT)
		frame.color = Color(0.15, 0.15, 0.2, 1)
		var icon := TextureRect.new()
		icon.texture = ItemCatalog.texture_for(catalog[i])
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(1, 1)
		icon.size = Vector2(ICON, ICON)
		frame.add_child(icon)
		_grid.add_child(frame)
		_slots.append(frame)
		_icons.append(icon)

func _refresh() -> void:
	var catalog := ItemCatalog.entries()
	_party_label.text = _party_line()
	for i in _slots.size():
		var selected := i == _cursor
		_slots[i].color = Color(0.95, 0.85, 0.35, 1) if selected else Color(0.15, 0.15, 0.2, 1)
	if _cursor < 0 or _cursor >= catalog.size():
		_detail_label.text = ""
		return
	var entry: Dictionary = catalog[_cursor]
	var id: StringName = entry[&"id"]
	_detail_label.text = "%s  x%d" % [entry[&"name"], GameData.get_item_count(id)]

func _party_line() -> String:
	var parts: PackedStringArray = []
	for i in GameData.party.size():
		var c: Creature = GameData.party[i]
		if c == null:
			continue
		var mark := ">" if i == GameData.active_index else " "
		parts.append("%s%s %d/%d" % [mark, c.name, c.hp, c.max_hp])
	if parts.is_empty():
		return "PARTY  --"
	return "PARTY  " + "  ".join(parts)
