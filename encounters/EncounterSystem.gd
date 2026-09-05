extends Node
## Wild encounter rolls (PRD §7).
##
## Listens for completed player steps on EventBus.player_moved, rolls once per step that
## landed in tall grass, and emits EventBus.encounter_triggered with a fresh wild creature.
## Core turns that into OVERWORLD -> BATTLE; this system never transitions state itself.
##
## It lives as a child of the overworld, which means it is frozen along with the overworld
## while a battle or menu overlay is up (see docs/ARCHITECTURE.md, scene model). It holds no
## reference to any world node: the tile and the tall-grass flag both arrive on the signal.
##
## Rolls happen per completed step, never per frame, so walking speed does not change the
## encounter rate.

const CreaturePool := preload("res://encounters/CreaturePool.gd")

## Steps that must be walked off before another roll is allowed. Counts every step, not just
## grass ones, so leaving the grass and stepping straight back in cannot re-trigger.
var _cooldown_steps: int = 0

## Exposed so tests can seed it. Randomised on _ready for the real game.
var rng := RandomNumberGenerator.new()

## Debug: makes the next eligible step trigger regardless of the roll. Cleared on use.
var force_next: bool = false

var _pool: CreaturePool = null

func _ready() -> void:
	rng.randomize()
	_pool = CreaturePool.new()
	EventBus.player_moved.connect(_on_player_moved)

func _on_player_moved(_tile: Vector2i, in_encounter_zone: bool) -> void:
	try_encounter(in_encounter_zone)

## One roll for one completed step. Returns true when an encounter was started.
##
## Takes the flag rather than a tile because the world already computed it; asking the map
## again would couple encounters to world/.
func try_encounter(in_encounter_zone: bool) -> bool:
	# Cooldown burns down on every step, including steps outside the grass.
	if _cooldown_steps > 0:
		_cooldown_steps -= 1
		return false
	if not in_encounter_zone:
		return false
	# Defensive: core ignores encounters outside OVERWORLD anyway, and the overworld is
	# frozen under an overlay, so this should never be the thing that saves us.
	if GameState.current != GameState.State.OVERWORLD:
		return false
	if not force_next and rng.randf() >= GameConfig.ENCOUNTER_CHANCE:
		return false
	force_next = false
	var wild := generate_wild_creature()
	if wild == null:
		push_error("EncounterSystem: creature pool is empty, no encounter started")
		return false
	start_encounter(wild)
	return true

## A fresh weighted-random wild creature, already healed. Useful on its own for debug menus.
func generate_wild_creature() -> Creature:
	if _pool == null:
		_pool = CreaturePool.new()
	return _pool.generate_wild_creature(rng)

## Announces a wild creature and starts the cooldown. Core performs the state change.
func start_encounter(wild: Creature) -> void:
	_cooldown_steps = GameConfig.ENCOUNTER_COOLDOWN_STEPS
	EventBus.encounter_triggered.emit(wild)

# --- Integration and debug helpers ---

## Steps still to walk before another roll can happen.
func steps_until_ready() -> int:
	return _cooldown_steps

func reset_cooldown() -> void:
	_cooldown_steps = 0

func pool_size() -> int:
	if _pool == null:
		_pool = CreaturePool.new()
	return _pool.size()
