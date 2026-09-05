extends Node
## Root scene. Binds the two layers into GameState and boots to TITLE.
## OverlayLayer is a CanvasLayer so overlays ignore the overworld Camera2D.

func _ready() -> void:
	# The handheld has no pointer; the UNO Q bridge also injects a virtual mouse we never want drawn.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameState.bind($WorldLayer, $OverlayLayer)
	GameState.transition_to(GameState.State.TITLE)
