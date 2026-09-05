extends "res://core/game_state.gd"
## Battle stub. Person 4 replaces this. A = catch, B = run.


var _label: Label


func enter() -> void:
	if Game.pending_wild == null:
		Game.pending_wild = Game.CreatureScript.emberfox()
	var wild := Game.pending_wild
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("2b2d42")
	layer.add_child(bg)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hero := "None"
	if Game.player.active_creature != null:
		hero = Game.player.active_creature.creature_name
	_label.text = "BATTLE STUB\n%s vs %s\nA catch   B run" % [hero, wild.creature_name]
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color("edf2f4"))
	layer.add_child(_label)


func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		Events.catch_started.emit(Game.pending_wild)
	elif InputManager.button_b_just_pressed():
		Events.battle_escaped.emit()
		Game.return_to_overworld()
