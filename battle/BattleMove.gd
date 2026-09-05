class_name BattleMove
extends RefCounted
## Battle-local move. Person 3 owns real moves later; battle keeps this so it
## does not depend on creatures/ growing new fields mid-hackathon.

var id: StringName = &"tackle"
var name: String = "TACKLE"
var type: StringName = &"NORMAL"
var power: int = 10
var accuracy: float = 1.0


static func make(p_id: StringName, p_name: String, p_type: StringName, p_power: int, p_acc: float = 1.0) -> BattleMove:
	var m := BattleMove.new()
	m.id = p_id
	m.name = p_name
	m.type = p_type
	m.power = p_power
	m.accuracy = p_acc
	return m
