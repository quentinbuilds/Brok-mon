class_name RagebaitSource
extends RefCounted
## Where taunt lines come from. Default is LineTable (type + rage band).


func get_line(_creature: Creature, _rage_level: int) -> String:
	return ""


class SingleLine:
	extends RagebaitSource
	const LINE := "Bet you can't punch."

	func get_line(_creature: Creature, _rage_level: int) -> String:
		return LINE


class LineTable:
	extends RagebaitSource
	## Insults keyed by type and rage band. Keep every line short enough that
	## `You: "<line>"` wraps to <= 3 battle-box lines (23 chars each).

	const GENERIC := {
		"wary": ["Is this a safe space?", "I'll log off first."],
		"mild": ["8 pixels of sad.", "Bet you can't punch."],
		"hot": ["Ratio. Chart's fake.", "Statistically mid."],
		"max": ["TOUCH GRASS. YOU ARE.", "SKILL ISSUE FOREVER."],
	}
	const BY_TYPE := {
		"FIRE": {
			"wary": ["Sorry. Too spicy?", "I'll evaporate..."],
			"mild": ["Your fire is a candle.", "8 pixels of sad."],
			"hot": ["Ratio. Ember? Cute.", "Statistically mid."],
			"max": ["YOU'RE JUST HOT AIR.", "SKILL ISSUE FOREVER."],
		},
		"GRASS": {
			"wary": ["I'll compost myself.", "Is this a safe space?"],
			"mild": ["You ARE the grass.", "8 pixels of sad."],
			"hot": ["Touch grass. Wait.", "Ratio. Chart's fake."],
			"max": ["TOUCH GRASS. YOU ARE.", "UNINSTALL YOURSELF."],
		},
		"WATER": {
			"wary": ["I'll evaporate...", "I'll log off first."],
			"mild": ["You're just wet data.", "8 pixels of sad."],
			"hot": ["Hydrated AND wrong.", "Statistically mid."],
			"max": ["404: OCEAN NOT FOUND", "SKILL ISSUE FOREVER."],
		},
		"ROCK": {
			"wary": ["I'm sedimentary...", "I'll log off first."],
			"mild": ["NPC energy. Solid.", "Bet you can't punch."],
			"hot": ["You skipped a jump.", "Ratio. Chart's fake."],
			"max": ["CRACKED LIKE YOUR API.", "UNINSTALL YOURSELF."],
		},
		"NORMAL": {
			"wary": ["I'll log off first.", "Is this a safe space?"],
			"mild": ["Main character who?", "Bet you can't punch."],
			"hot": ["Statistically mid.", "Your hitbox is a vibe."],
			"max": ["UNINSTALL YOURSELF.", "SKILL ISSUE FOREVER."],
		},
	}

	static func band_for(rage_level: int) -> String:
		if rage_level < 0:
			return "wary"
		if rage_level >= 3:
			return "max"
		if rage_level >= 1:
			return "hot"
		return "mild"

	func get_line(creature: Creature, rage_level: int) -> String:
		var pool: Array = pool_for(creature, rage_level)
		if pool.is_empty():
			return "8 pixels of sad."
		var idx := _index(creature, rage_level, pool.size())
		return str(pool[idx])

	func pool_for(creature: Creature, rage_level: int) -> Array:
		var band := band_for(rage_level)
		var type_key := "NORMAL"
		if creature != null:
			type_key = String(creature.type)
		var typed: Variant = BY_TYPE.get(type_key, {})
		if typed is Dictionary and (typed as Dictionary).has(band):
			return (typed as Dictionary)[band]
		return GENERIC.get(band, GENERIC["mild"])

	func _index(creature: Creature, rage_level: int, size: int) -> int:
		if size <= 0:
			return 0
		var h := 17 * rage_level
		if creature != null:
			h += creature.id * 31 + creature.name.hash()
		return absi(h) % size
