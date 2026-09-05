extends GameStateBase
## Placeholder battle. Person 4 replaces this. Contract to keep:
##   payload["wild"]: Creature, payload.get("resume"): true when returning from a failed catch
##   A -> request catch (transition to CATCHING with the same wild)
##   B -> run (emit battle_escaped). Emit battle_won / battle_lost when resolved.

@onready var _label: Label = $Label

func debug_payload() -> Dictionary:
	return {"wild": (load(GameConfig.DEBUG_WILD_PATH) as Creature).make_instance()}

func _on_enter() -> void:
	var wild: Creature = payload.get("wild")
	var mine := GameData.get_active_creature()
	_label.text = "BATTLE\n%s (HP %d)  vs  wild %s (HP %d)\n\nA: catch   B: run" % [
		mine.name if mine else "?", mine.hp if mine else 0,
		wild.name if wild else "?", wild.hp if wild else 0]
	if not payload.get("resume", false):
		EventBus.battle_started.emit(mine, wild)

func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		GameState.transition_to(GameState.State.CATCHING, {"wild": payload.get("wild")})
	elif InputManager.button_b_just_pressed():
		EventBus.battle_escaped.emit()
