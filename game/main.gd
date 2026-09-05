extends Node2D
## Thin host. Game swaps one child state scene under StateRoot.


func _ready() -> void:
	Game.bind_host($StateRoot)
