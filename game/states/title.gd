extends "res://core/game_state.gd"


var _title: Label
var _prompt: Label


func enter() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("1a1c2c")
	layer.add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(box)

	_title = Label.new()
	_title.text = "GOK-MON"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 48)
	_title.add_theme_color_override("font_color", Color("f4d35e"))
	box.add_child(_title)

	_prompt = Label.new()
	_prompt.text = "PRESS START"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color("e8e8e8"))
	box.add_child(_prompt)


func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		Game.change_state(Game.GS.Id.OVERWORLD)
