class_name MoveDex
extends RefCounted
## Battle-owned move catalog. Person 3 owns real creature data; we keep the
## list here so fight / learnsets do not wait on new .tres fields.

const CATALOG := {
	&"tackle": {"name": "TACKLE", "type": &"NORMAL", "power": 10, "acc": 1.0},
	&"side_eye": {"name": "SIDE EYE", "type": &"NORMAL", "power": 6, "acc": 1.0},
	&"quick_post": {"name": "QUICK POST", "type": &"NORMAL", "power": 12, "acc": 0.95},
	&"hard_refresh": {"name": "HARD REFRESH", "type": &"NORMAL", "power": 14, "acc": 0.9},
	&"ratio": {"name": "RATIO", "type": &"NORMAL", "power": 16, "acc": 0.85},
	&"ember": {"name": "EMBER", "type": &"FIRE", "power": 11, "acc": 1.0},
	&"hot_take": {"name": "HOT TAKE", "type": &"FIRE", "power": 13, "acc": 0.95},
	&"vine_whip": {"name": "VINE WHIP", "type": &"GRASS", "power": 9, "acc": 1.0},
	&"thread": {"name": "THREAD", "type": &"GRASS", "power": 12, "acc": 0.95},
	&"water_gun": {"name": "WATER GUN", "type": &"WATER", "power": 10, "acc": 1.0},
	&"reply_all": {"name": "REPLY ALL", "type": &"WATER", "power": 12, "acc": 0.95},
	&"rock_throw": {"name": "ROCK THROW", "type": &"ROCK", "power": 10, "acc": 1.0},
	&"crash_log": {"name": "CRASH LOG", "type": &"ROCK", "power": 13, "acc": 0.9},
	&"static": {"name": "STATIC", "type": &"ELECTRIC", "power": 10, "acc": 1.0},
	&"lag_spike": {"name": "LAG SPIKE", "type": &"ELECTRIC", "power": 13, "acc": 0.95},
}


static func get_move(id: StringName) -> BattleMove:
	if not CATALOG.has(id):
		return null
	var d: Dictionary = CATALOG[id]
	return BattleMove.make(id, String(d["name"]), d["type"], int(d["power"]), float(d["acc"]))


static func display_name(id: StringName) -> String:
	var move := get_move(id)
	if move == null:
		return String(id).to_upper()
	return move.name
