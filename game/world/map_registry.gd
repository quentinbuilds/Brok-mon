extends RefCounted
## Resolves deterministic map definitions by id.

const Jungle = preload("res://world/jungle_map_data.gd")
const Beach = preload("res://world/beach_map_data.gd")


static func definition(map_id: StringName) -> Dictionary:
	match map_id:
		&"jungle":
			return Jungle.build()
		&"beach":
			return Beach.build()
		_:
			return {}
