extends RefCounted

const CAPTURE_ORB := "Capture Orb"
const POTION := "Potion"

var items: Dictionary = {
	CAPTURE_ORB: 5,
	POTION: 3,
}


func get_count(item_name: String) -> int:
	return int(items.get(item_name, 0))


func add_item(item_name: String, amount: int = 1) -> void:
	items[item_name] = get_count(item_name) + amount
	Events.inventory_changed.emit()


func use_item(item_name: String) -> bool:
	if get_count(item_name) <= 0:
		return false
	items[item_name] = get_count(item_name) - 1
	Events.inventory_changed.emit()
	return true
