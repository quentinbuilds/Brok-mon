extends GameStateBase
## Placeholder catching screen. Person 5 replaces this. Contract to keep:
##   payload["wild"]: Creature
##   success -> GameData.add_to_party(wild); EventBus.creature_caught.emit(wild)
##   failure -> EventBus.catch_failed.emit(wild)
##   honour GameConfig.debug_force_catch (1 success, -1 fail), then reset it to 0.
## Stub: A = succeed, B = fail.

@onready var _label: Label = $Label
@onready var _wild_sprite: Sprite2D = $WildSprite

func debug_payload() -> Dictionary:
	return {"wild": (load(GameConfig.DEBUG_WILD_PATH) as Creature).make_instance()}

func _on_enter() -> void:
	var wild: Creature = payload.get("wild")
	_label.text = "Catch %s?\nA THROW   B BACK" % (wild.name if wild else "?")
	_wild_sprite.texture = wild.sprite if wild else null
	if _wild_sprite.texture:
		var size := Vector2(_wild_sprite.texture.get_size())
		_wild_sprite.scale = Vector2.ONE * minf(58.0 / size.x, 54.0 / size.y)
	EventBus.catch_started.emit(wild)

func update(_delta: float) -> void:
	var wild: Creature = payload.get("wild")
	var forced := GameConfig.debug_force_catch
	var success := forced == 1 or (forced == 0 and InputManager.button_a_just_pressed())
	var failure := forced == -1 or (forced == 0 and InputManager.button_b_just_pressed())
	if not (success or failure):
		return
	GameConfig.debug_force_catch = 0
	if success:
		if not GameData.add_to_party(wild):
			print("party full; %s released" % wild.name)
		EventBus.creature_caught.emit(wild)
	else:
		EventBus.catch_failed.emit(wild)
