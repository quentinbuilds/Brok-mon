extends GameStateBase
## Placeholder title screen. Person 6 replaces the visuals; keep the transition.

func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		GameData.reset()
		GameState.transition_to(GameState.State.OVERWORLD)
