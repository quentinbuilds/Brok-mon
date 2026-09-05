extends Node
## Root scene. Binds the two layers into GameState and boots to TITLE.
## OverlayLayer is a CanvasLayer so overlays ignore the overworld Camera2D.

func _ready() -> void:
	GameState.bind($WorldLayer, $OverlayLayer)
	GameState.transition_to(GameState.State.TITLE)
