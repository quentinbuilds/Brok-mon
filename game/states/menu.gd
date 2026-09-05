extends "res://core/game_state.gd"
## Menu stub. Person 6 owns the real UI. B returns to overworld.


func enter() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("22223b")
	layer.add_child(bg)

	var lines: PackedStringArray = ["MENU STUB", "", "PARTY"]
	for creature in Game.player.party:
		var mark := ">" if creature == Game.player.active_creature else " "
		lines.append("%s %s" % [mark, creature.creature_name])
	lines.append("")
	lines.append("INVENTORY")
	for item_name in Game.player.inventory.items:
		lines.append("%s x %d" % [item_name, Game.player.inventory.get_count(item_name)])
	lines.append("")
	lines.append("B close")

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = "\n".join(lines)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("f2e9e4"))
	layer.add_child(label)


func update(_delta: float) -> void:
	if InputManager.button_b_just_pressed() or InputManager.button_menu_just_pressed():
		Events.menu_closed.emit()
		Game.return_to_overworld()
