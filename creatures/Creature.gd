class_name Creature
extends Resource
## Shared creature contract (PRD §4). Definitions live in creatures/data/*.tres.
## Never mutate a definition in battle: call make_instance() first.

@export var id: int = 0
@export var name: String = ""
@export var sprite: Texture2D
@export var type: StringName = &"NORMAL"
@export var max_hp: int = 10
@export var hp: int = 10
@export var attack: int = 5
@export var defense: int = 5
@export_range(0.0, 1.0) var catch_rate: float = 0.5

## Returns a distinct copy at full HP, suitable for a wild encounter or a party member.
func make_instance() -> Creature:
	var c := duplicate(true) as Creature
	c.hp = c.max_hp
	return c

func is_fainted() -> bool:
	return hp <= 0
