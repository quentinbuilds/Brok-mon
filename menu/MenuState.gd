extends GameStateBase
## Placeholder menu listing party and inventory. Person 6 replaces the UI.
## Keep: emit menu_opened / menu_closed; B or menu key closes back to OVERWORLD.
## A opens the SOUND_TEST screen (dev tool for checking audio on real hardware).

@onready var _label: Label = $Label

func _on_enter() -> void:
	EventBus.menu_opened.emit()
	_refresh()

func exit() -> void:
	EventBus.menu_closed.emit()

func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		GameState.transition_to(GameState.State.SOUND_TEST)
	elif InputManager.button_b_just_pressed() or InputManager.button_menu_just_pressed():
		GameState.transition_to(GameState.State.OVERWORLD)

func _refresh() -> void:
	var lines: Array[String] = ["PARTY"]
	for i in GameData.party.size():
		var c := GameData.party[i]
		lines.append("%s %s  HP %d/%d" % [">" if i == GameData.active_index else " ", c.name, c.hp, c.max_hp])
	lines.append("")
	lines.append("INVENTORY")
	for item in GameData.inventory:
		lines.append("  %s x %d" % [item, GameData.inventory[item]])
	lines.append("")
	lines.append("A: sound test   B: close")
	_label.text = "\n".join(lines)
