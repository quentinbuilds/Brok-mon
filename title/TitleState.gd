extends GameStateBase
## Title stays in the state machine but auto-advances to OVERWORLD (no PRESS A).
## Contract: _on_enter / update / exit / debug_payload. Standalone F6 uses debug_payload.

func debug_payload() -> Dictionary:
	return {}

func _ready() -> void:
	_hide_title_visuals()

func _on_enter() -> void:
	_hide_title_visuals()
	# GameState sets current=TITLE only after enter() returns, so a same-stack
	# TITLE→OVERWORLD call would be seen as illegal BOOT→OVERWORLD.
	call_deferred("_advance_to_overworld")

func update(_delta: float) -> void:
	pass

func _hide_title_visuals() -> void:
	visible = false
	var label := get_node_or_null("Label") as CanvasItem
	if label:
		label.visible = false

func _advance_to_overworld() -> void:
	if GameState.current != GameState.State.TITLE:
		return
	GameData.reset()
	GameState.transition_to(GameState.State.OVERWORLD)
