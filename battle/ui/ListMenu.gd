class_name ListMenu
extends RefCounted
## Vertical cursor for BAG and PARTY submenus.

var items: Array[Dictionary] = []
var index: int = 0
var window: int = 2
var scroll: int = 0


func set_items(new_items: Array[Dictionary]) -> void:
	items = new_items
	index = 0
	scroll = 0


func is_empty() -> bool:
	return items.is_empty()


func current() -> Dictionary:
	if items.is_empty():
		return {}
	return items[index]


func move(delta: int) -> bool:
	if items.size() <= 1:
		return false
	var before := index
	index = wrapi(index + delta, 0, items.size())
	_follow_cursor()
	return index != before


func _follow_cursor() -> void:
	if index < scroll:
		scroll = index
	elif index >= scroll + window:
		scroll = index - window + 1
	scroll = clampi(scroll, 0, maxi(0, items.size() - window))


func visible_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in range(scroll, mini(scroll + window, items.size())):
		var row := items[i].duplicate()
		row["_index"] = i
		row["_selected"] = i == index
		rows.append(row)
	return rows
