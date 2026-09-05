extends Node
## Integration owner. Owns the state machine and shared session data.

const GS = preload("res://core/game_state.gd")
const CreatureScript = preload("res://core/creature.gd")
const PlayerDataScript = preload("res://core/player_data.gd")

var scenes := {}
var current_id = GS.Id.BOOT
var current_state: Node = null
var player = PlayerDataScript.new()
var pending_wild = null
var last_overworld_id = GS.Id.OVERWORLD

var _host: Node = null
var _held_debug: int = 0


func _ready() -> void:
	scenes = {
		GS.Id.TITLE: "res://states/title.tscn",
		GS.Id.OVERWORLD: "res://states/overworld.tscn",
		GS.Id.BATTLE: "res://states/battle.tscn",
		GS.Id.CATCHING: "res://states/catching.tscn",
		GS.Id.MENU: "res://states/menu.tscn",
	}
	player.add_to_party(CreatureScript.emberfox())
	Events.encounter_triggered.connect(_on_encounter_triggered)
	Events.catch_started.connect(_on_catch_started)


func bind_host(host: Node) -> void:
	_host = host
	change_state(GS.Id.TITLE)


func change_state(next_id) -> void:
	if _host == null:
		push_error("Game.bind_host() must run before change_state()")
		return
	if next_id == GS.Id.BOOT:
		next_id = GS.Id.TITLE
	if current_id == GS.Id.OVERWORLD:
		last_overworld_id = current_id
	if current_state != null:
		if current_state.has_method("exit"):
			current_state.exit()
		current_state.queue_free()
		current_state = null
	current_id = next_id
	if not scenes.has(next_id):
		push_error("No scene registered for state %s" % next_id)
		return
	var packed: PackedScene = load(scenes[next_id])
	current_state = packed.instantiate()
	_host.add_child(current_state)
	if current_state.has_method("enter"):
		current_state.enter()


func start_battle(wild) -> void:
	pending_wild = wild
	Events.battle_started.emit(player.active_creature, wild)
	change_state(GS.Id.BATTLE)


func return_to_overworld() -> void:
	change_state(GS.Id.OVERWORLD)


func _process(delta: float) -> void:
	if current_state != null and current_state.has_method("update"):
		current_state.update(delta)
	if GameConfig.DEBUG_STATE_JUMPS:
		_debug_jumps()


func _on_encounter_triggered(creature) -> void:
	start_battle(creature)


func _on_catch_started(creature) -> void:
	pending_wild = creature
	change_state(GS.Id.CATCHING)


func _debug_jumps() -> void:
	if Input.is_key_pressed(KEY_F1):
		_debug_once(KEY_F1, GS.Id.TITLE)
	elif Input.is_key_pressed(KEY_F2):
		_debug_once(KEY_F2, GS.Id.OVERWORLD)
	elif Input.is_key_pressed(KEY_F3):
		_debug_once(KEY_F3, GS.Id.BATTLE)
	elif Input.is_key_pressed(KEY_F4):
		_debug_once(KEY_F4, GS.Id.CATCHING)
	elif Input.is_key_pressed(KEY_F5):
		_debug_once(KEY_F5, GS.Id.MENU)
	elif Input.is_key_pressed(KEY_F6):
		_debug_once(KEY_F6, GS.Id.TITLE)


func _debug_once(key: int, next_id) -> void:
	if _held_debug == key:
		return
	_held_debug = key
	if next_id == GS.Id.BATTLE and pending_wild == null:
		pending_wild = CreatureScript.emberfox()
	if next_id == GS.Id.CATCHING and pending_wild == null:
		pending_wild = CreatureScript.emberfox()
	change_state(next_id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.pressed:
		if (event as InputEventKey).keycode in [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6]:
			_held_debug = 0
