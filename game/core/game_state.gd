class_name GameState
extends Node
## Base class every major state implements. Person 1 owns the machine;
## other people own the concrete state scenes.

enum Id {
	BOOT,
	TITLE,
	OVERWORLD,
	BATTLE,
	CATCHING,
	MENU,
}


func enter() -> void:
	pass


func update(_delta: float) -> void:
	pass


func exit() -> void:
	pass
