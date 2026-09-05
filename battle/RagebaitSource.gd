class_name RagebaitSource
extends RefCounted
## Where taunt lines come from. Swap for a generated pool later.


func get_line(_creature: Creature, _rage_level: int) -> String:
	return ""


class SingleLine:
	extends RagebaitSource
	const LINE := "Bet you can't even throw a punch!"

	func get_line(_creature: Creature, _rage_level: int) -> String:
		return LINE
