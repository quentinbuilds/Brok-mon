class_name GameStateBase
extends Node2D
## Base for every game state scene (PRD §5 state interface).
## Subclasses override _on_enter(), update(), exit(), debug_payload().
## Root is Node2D so GameState can hide/freeze it; put Controls as children.

## Data handed over by GameState.transition_to(). See docs/ARCHITECTURE.md for keys per state.
var payload: Dictionary = {}

func enter(p_payload: Dictionary) -> void:
	payload = p_payload
	_on_enter()

## Called by GameState each frame while this state is active.
func update(_delta: float) -> void:
	pass

## Called by GameState just before the node is freed (overlay states) or never for OVERWORLD,
## which is frozen instead of destroyed.
func exit() -> void:
	pass

func _on_enter() -> void:
	pass

## Payload used when this scene is run on its own (F6) so every state is independently testable.
func debug_payload() -> Dictionary:
	return {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY and _is_standalone():
		enter(debug_payload())
		set_process(true)

func _process(delta: float) -> void:
	if _is_standalone():
		update(delta)

func _is_standalone() -> bool:
	return is_inside_tree() and get_tree().current_scene == self
