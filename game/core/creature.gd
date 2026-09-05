extends RefCounted

var id: String = ""
var creature_name: String = ""
var type: String = ""
var max_hp: int = 1
var hp: int = 1
var attack: int = 1
var defense: int = 1
var catch_rate: float = 0.35


static func emberfox():
	var c = load("res://core/creature.gd").new()
	c.id = "001"
	c.creature_name = "Emberfox"
	c.type = "FIRE"
	c.max_hp = 30
	c.hp = 30
	c.attack = 8
	c.defense = 5
	c.catch_rate = 0.35
	return c


func copy():
	var c = load("res://core/creature.gd").new()
	c.id = id
	c.creature_name = creature_name
	c.type = type
	c.max_hp = max_hp
	c.hp = hp
	c.attack = attack
	c.defense = defense
	c.catch_rate = catch_rate
	return c
