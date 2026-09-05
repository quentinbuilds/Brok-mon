class_name GameConfig
extends RefCounted
## Tunable values shared by every subsystem. Edit numbers here, not in gameplay code.

## Party and inventory (Person 5)
const PARTY_SIZE := 3
const START_CAPTURE_ORBS := 5
const START_POTIONS := 3
const START_REVIVES := 2
const POTION_HEAL := 20
const STARTER_PATH := "res://creatures/data/placeholder_starter.tres"

## Encounters (Person 3). Chance per valid movement step, and steps of cooldown after a battle.
const ENCOUNTER_CHANCE := 0.08
const ENCOUNTER_COOLDOWN_STEPS := 4

## Placeholder wild creature used by debug key F1 until Person 3's pool exists.
const DEBUG_WILD_PATH := "res://creatures/data/placeholder_wild.tres"

## Debug controls. 0 = normal, 1 = force next catch to succeed, -1 = force next catch to fail.
static var debug_force_catch: int = 0

static func debug_keys_enabled() -> bool:
	return OS.is_debug_build()
