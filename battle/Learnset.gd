class_name Learnset
extends RefCounted
## Type-based learnsets. Empty known_move_ids means "not seeded yet".

const BY_TYPE := {
	"NORMAL": [
		{"level": 1, "id": &"tackle"},
		{"level": 3, "id": &"side_eye"},
		{"level": 5, "id": &"quick_post"},
		{"level": 8, "id": &"hard_refresh"},
		{"level": 12, "id": &"ratio"},
	],
	"FIRE": [
		{"level": 1, "id": &"tackle"},
		{"level": 3, "id": &"ember"},
		{"level": 6, "id": &"hot_take"},
		{"level": 10, "id": &"hard_refresh"},
	],
	"GRASS": [
		{"level": 1, "id": &"tackle"},
		{"level": 3, "id": &"vine_whip"},
		{"level": 6, "id": &"thread"},
		{"level": 10, "id": &"hard_refresh"},
	],
	"WATER": [
		{"level": 1, "id": &"tackle"},
		{"level": 4, "id": &"water_gun"},
		{"level": 7, "id": &"reply_all"},
		{"level": 11, "id": &"hard_refresh"},
	],
	"ROCK": [
		{"level": 1, "id": &"tackle"},
		{"level": 4, "id": &"rock_throw"},
		{"level": 8, "id": &"crash_log"},
		{"level": 12, "id": &"hard_refresh"},
	],
	"ELECTRIC": [
		{"level": 1, "id": &"tackle"},
		{"level": 4, "id": &"static"},
		{"level": 7, "id": &"lag_spike"},
		{"level": 11, "id": &"hard_refresh"},
	],
}


static func entries_for(creature: Creature) -> Array:
	var key := String(creature.type) if creature != null else "NORMAL"
	if BY_TYPE.has(key):
		return BY_TYPE[key]
	return BY_TYPE["NORMAL"]


static func ensure_moves(creature: Creature) -> void:
	if creature == null or not creature.known_move_ids.is_empty():
		return
	var ids: Array[StringName] = []
	for entry in entries_for(creature):
		if int(entry["level"]) <= creature.level:
			ids.append(entry["id"])
	if ids.is_empty():
		ids.append(&"tackle")
	var start := 0
	if ids.size() > BattleConfig.MAX_MOVES:
		start = ids.size() - BattleConfig.MAX_MOVES
	var packed := PackedStringArray()
	for i in range(start, ids.size()):
		packed.append(String(ids[i]))
	creature.known_move_ids = packed


static func try_learn_at_level(creature: Creature, new_level: int) -> Dictionary:
	var result := {"learned": "", "replaced": ""}
	if creature == null:
		return result
	for entry in entries_for(creature):
		if int(entry["level"]) != new_level:
			continue
		var id: StringName = entry["id"]
		if _has(creature, id):
			return result
		if creature.known_move_ids.size() >= BattleConfig.MAX_MOVES:
			result["replaced"] = String(creature.known_move_ids[0])
			creature.known_move_ids.remove_at(0)
		creature.known_move_ids.append(String(id))
		result["learned"] = String(id)
		return result
	return result


static func _has(creature: Creature, id: StringName) -> bool:
	for existing in creature.known_move_ids:
		if StringName(existing) == id:
			return true
	return false
