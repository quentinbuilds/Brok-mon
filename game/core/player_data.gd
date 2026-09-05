extends RefCounted

const PARTY_MAX := 3

var position: Vector2 = Vector2.ZERO
var movement_speed: float = 80.0
var direction: Vector2 = Vector2.DOWN
var party: Array = []
var inventory = load("res://core/inventory.gd").new()
var active_creature = null


func add_to_party(creature) -> bool:
	if party.size() >= PARTY_MAX:
		return false
	party.append(creature)
	if active_creature == null:
		set_active_creature(creature)
	Events.party_changed.emit()
	return true


func set_active_creature(creature) -> void:
	active_creature = creature
	Events.active_creature_changed.emit(creature)
