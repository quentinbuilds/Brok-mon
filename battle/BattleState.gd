extends GameStateBase
## Lightweight battle presentation. Contract to keep:
##   payload["wild"]: Creature, payload.get("resume"): true after a failed catch
##   A -> request catch; B -> run.

@onready var _wild_sprite: Sprite2D = $WildSprite
@onready var _player_sprite: Sprite2D = $PlayerSprite
@onready var _wild_label: Label = $WildLabel
@onready var _player_label: Label = $PlayerLabel

func debug_payload() -> Dictionary:
	return {"wild": (load(GameConfig.DEBUG_WILD_PATH) as Creature).make_instance()}

func _on_enter() -> void:
	var wild: Creature = payload.get("wild")
	var mine: Creature = GameData.get_active_creature()
	_present_creature(_wild_sprite, wild, Vector2(54, 42))
	_present_creature(_player_sprite, mine, Vector2(48, 38))
	_wild_label.text = _status(wild)
	_player_label.text = _status(mine)
	if not payload.get("resume", false):
		EventBus.battle_started.emit(mine, wild)

func update(_delta: float) -> void:
	if InputManager.button_a_just_pressed():
		GameState.transition_to(GameState.State.CATCHING, {"wild": payload.get("wild")})
	elif InputManager.button_b_just_pressed():
		EventBus.battle_escaped.emit()

func _status(creature: Creature) -> String:
	if not creature:
		return "?"
	return "%s\nHP %d/%d" % [creature.name, creature.hp, creature.max_hp]

func _present_creature(node: Sprite2D, creature: Creature, max_size: Vector2) -> void:
	node.texture = creature.sprite if creature else null
	if not node.texture:
		return
	var size := Vector2(node.texture.get_size())
	var factor := minf(max_size.x / size.x, max_size.y / size.y)
	node.scale = Vector2.ONE * factor
