extends GameStateBase
## Title screen. Person 6 owns the visuals; world pick stays a Person 2 start hook.

const BiomeSession := preload("res://world/BiomeSession.gd")

func _on_enter() -> void:
	var prompt := get_node_or_null("Prompt")
	if prompt is Label:
		prompt.text = "A JUNGLE   B GRASSLAND"


func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		_start(BiomeSession.WORLD_JUNGLE)
	elif InputManager.button_b_just_pressed():
		_start(BiomeSession.WORLD_GRASSLAND)


func _start(world_id: StringName) -> void:
	GameData.reset()
	BiomeSession.choose(world_id)
	GameState.transition_to(GameState.State.OVERWORLD)
