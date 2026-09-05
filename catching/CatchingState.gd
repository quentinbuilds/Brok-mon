extends GameStateBase
class_name CatchingState
## Catching screen with handshake copy. Person 5 owns real odds later.
##   payload["wild"]: Creature
##   payload["catch_multiplier"]: float (from Ragebait; optional)
##   success -> GameData.add_to_party(wild); EventBus.creature_caught.emit(wild)
##   failure -> EventBus.catch_failed.emit(wild)
##   honour GameConfig.debug_force_catch (1 success, -1 fail), then reset it to 0.
##   A = succeed, B = fail (works during the handshake).

const BEAT_SECS := 0.45
const BEAT_LAST := 3

@onready var _label: Label = $Label
@onready var _wild_sprite: Sprite2D = $WildSprite

var _wild: Creature
var _multiplier := 1.0
var _beat := 0
var _elapsed := 0.0
var _resolved := false


func debug_payload() -> Dictionary:
	return {"wild": (load(GameConfig.DEBUG_WILD_PATH) as Creature).make_instance()}


func _on_enter() -> void:
	_wild = payload.get("wild") as Creature
	_multiplier = float(payload.get("catch_multiplier", 1.0))
	_beat = 0
	_elapsed = 0.0
	_resolved = false
	_bind_sprite()
	_refresh()
	EventBus.catch_started.emit(_wild)


func update(delta: float) -> void:
	if _resolved:
		return
	var forced := GameConfig.debug_force_catch
	var success := forced == 1 or (forced == 0 and InputManager.button_a_just_pressed())
	var failure := forced == -1 or (forced == 0 and InputManager.button_b_just_pressed())
	if success or failure:
		_resolve(success)
		return
	_elapsed += delta
	if _beat < BEAT_LAST and _elapsed >= BEAT_SECS:
		_beat += 1
		_elapsed = 0.0
		_refresh()


func _bind_sprite() -> void:
	if _wild_sprite == null:
		return
	_wild_sprite.texture = _wild.sprite if _wild else null
	if _wild_sprite.texture:
		var size := Vector2(_wild_sprite.texture.get_size())
		_wild_sprite.scale = Vector2.ONE * minf(58.0 / size.x, 54.0 / size.y)


func _refresh() -> void:
	if _label == null:
		return
	var name := _wild.name if _wild else "?"
	_label.text = CatchCopy.beat_text(_beat, name)


func _resolve(success: bool) -> void:
	_resolved = true
	GameConfig.debug_force_catch = 0
	if success:
		var added := GameData.add_to_party(_wild)
		if _label:
			if added:
				_label.text = CatchCopy.success()
			else:
				_label.text = CatchCopy.party_full(_wild.name if _wild else "?")
				print("party full; %s released" % (_wild.name if _wild else "?"))
		EventBus.creature_caught.emit(_wild)
	else:
		if _label:
			_label.text = CatchCopy.failure(_multiplier)
		EventBus.catch_failed.emit(_wild)
