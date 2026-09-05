extends "res://core/game_state.gd"
## Catching stub. Person 5 replaces this. A = force catch, B = fail.


func enter() -> void:
	if Game.pending_wild == null:
		Game.pending_wild = Game.CreatureScript.emberfox()
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("4a1942")
	layer.add_child(bg)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = "CATCHING STUB\nA succeed   B fail"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("f8edeb"))
	layer.add_child(label)


func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		var caught := Game.pending_wild.copy()
		Game.player.add_to_party(caught)
		Events.creature_caught.emit(caught)
		Game.pending_wild = null
		Game.return_to_overworld()
	elif InputManager.button_b_just_pressed():
		Events.catch_failed.emit(Game.pending_wild)
		Game.change_state(Game.GS.Id.BATTLE)
