extends RefCounted
## The grassland wild pool (PRD §7). Owns which creatures can appear and how often.
##
## Weights are relative, not percentages: the tankiest and the fastest creature are rare so
## that finding one feels like something. Only one biome is required for the MVP, so this is
## the whole pool.

const POOL := [
	{"path": "res://creatures/data/mossbug.tres", "weight": 35},
	{"path": "res://creatures/data/pebblit.tres", "weight": 25},
	{"path": "res://creatures/data/aquafin.tres", "weight": 20},
	{"path": "res://creatures/data/emberfox.tres", "weight": 15},
	{"path": "res://creatures/data/voltkit.tres", "weight": 5},
]

var _definitions: Array[Creature] = []
var _weights: Array[int] = []
var _total_weight: int = 0

func _init() -> void:
	for entry in POOL:
		var c := load(entry["path"]) as Creature
		if c == null:
			push_error("CreaturePool: missing definition %s" % entry["path"])
			continue
		_definitions.append(c)
		_weights.append(entry["weight"])
		_total_weight += entry["weight"]

func size() -> int:
	return _definitions.size()

## The shared definitions. Never mutate these; call make_instance() first.
func get_definitions() -> Array[Creature]:
	return _definitions

## A fresh healed copy of a weighted-random creature, safe for battle to mutate.
## Returns null only when every definition failed to load.
func generate_wild_creature(rng: RandomNumberGenerator) -> Creature:
	if _definitions.is_empty():
		return null
	var roll := rng.randi_range(1, _total_weight)
	var acc := 0
	for i in _definitions.size():
		acc += _weights[i]
		if roll <= acc:
			return _definitions[i].make_instance()
	return _definitions[_definitions.size() - 1].make_instance()
