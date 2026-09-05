class_name BattleServices
extends RefCounted
## Inventory/party seams. Production talks to GameData; tests inject Null*.


class InventoryService:
	extends RefCounted
	func get_battle_items() -> Array[Dictionary]:
		return []
	func use_item(_item_id: StringName) -> bool:
		return false


class GameDataInventory:
	extends InventoryService
	func get_battle_items() -> Array[Dictionary]:
		return [
			{"id": GameData.ITEM_CAPTURE_ORB, "name": "CAPTURE ORB",
				"count": GameData.get_item_count(GameData.ITEM_CAPTURE_ORB)},
			{"id": GameData.ITEM_POTION, "name": "POTION",
				"count": GameData.get_item_count(GameData.ITEM_POTION)},
		]
	func use_item(item_id: StringName) -> bool:
		return GameData.use_item(item_id)


class NullInventory:
	extends InventoryService
	var counts: Dictionary = {&"capture_orb": 5, &"potion": 3}
	func get_battle_items() -> Array[Dictionary]:
		return [
			{"id": &"capture_orb", "name": "CAPTURE ORB", "count": int(counts.get(&"capture_orb", 0))},
			{"id": &"potion", "name": "POTION", "count": int(counts.get(&"potion", 0))},
		]
	func use_item(item_id: StringName) -> bool:
		if int(counts.get(item_id, 0)) <= 0:
			return false
		counts[item_id] = int(counts[item_id]) - 1
		return true


class PartyService:
	extends RefCounted
	func get_party() -> Array[Creature]:
		return []
	func get_active_index() -> int:
		return 0
	func set_active_index(_index: int) -> void:
		pass


class GameDataParty:
	extends PartyService
	func get_party() -> Array[Creature]:
		return GameData.get_party()
	func get_active_index() -> int:
		return GameData.active_index
	func set_active_index(index: int) -> void:
		GameData.set_active(index)


class NullParty:
	extends PartyService
	var party: Array[Creature] = []
	var active: int = 0
	func get_party() -> Array[Creature]:
		return party
	func get_active_index() -> int:
		return active
	func set_active_index(index: int) -> void:
		if index >= 0 and index < party.size():
			active = index


var inventory: InventoryService = GameDataInventory.new()
var party: PartyService = GameDataParty.new()
