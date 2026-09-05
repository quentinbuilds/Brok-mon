extends Node
## Central state machine (PRD §1, §5). Owns transitions and the two-layer scene model:
##   WorldLayer   -> OVERWORLD, created once, hidden + frozen while an overlay is up
##   OverlayLayer -> TITLE / BATTLE / CATCHING / MENU / SOUND_TEST, one at a time, freed on exit
## States never call each other. They call transition_to() for their own exit, or emit
## EventBus signals that this node reacts to.

signal state_changed(from: State, to: State)

## SOUND_TEST is a dev screen reached from the menu. Appended last so the existing
## ordinals stay put for anything that persisted them.
enum State { BOOT, TITLE, OVERWORLD, BATTLE, CATCHING, MENU, SOUND_TEST }

const LEGAL := {
	State.BOOT: [State.TITLE],
	State.TITLE: [State.OVERWORLD],
	State.OVERWORLD: [State.BATTLE, State.MENU],
	State.BATTLE: [State.CATCHING, State.OVERWORLD],
	State.CATCHING: [State.OVERWORLD, State.BATTLE],
	State.MENU: [State.OVERWORLD, State.SOUND_TEST, State.TITLE],
	State.SOUND_TEST: [State.MENU],
}

const SCENES := {
	State.TITLE: "res://title/TitleState.tscn",
	State.OVERWORLD: "res://world/OverworldState.tscn",
	State.BATTLE: "res://battle/BattleState.tscn",
	State.CATCHING: "res://catching/CatchingState.tscn",
	State.MENU: "res://menu/MenuState.tscn",
	State.SOUND_TEST: "res://audio/AudioTest.tscn",
}

var current: State = State.BOOT

## Optional hook for Person 6: Callable(from: State, to: State) run before the swap (fade out etc).
## Note this is called synchronously and is NOT awaited, so it cannot hold a transition open for
## an animation. Anything that has to span the swap belongs on the Transition autoload instead -
## see title/TitleState.gd for the shape (await Transition.close(), transition_to(), open()).
var transition_hook: Callable = Callable()

var _world_layer: Node
var _overlay_layer: Node
var _overworld: GameStateBase
var _overlay: GameStateBase

func _ready() -> void:
	EventBus.encounter_triggered.connect(_on_encounter_triggered)
	EventBus.battle_won.connect(func(_wild): _leave_battle())
	EventBus.battle_lost.connect(_leave_battle)
	EventBus.battle_escaped.connect(_leave_battle)
	EventBus.creature_caught.connect(_on_creature_caught)
	EventBus.catch_failed.connect(_on_catch_failed)

## Called by Main once its layers exist. Resets to BOOT.
func bind(world_layer: Node, overlay_layer: Node) -> void:
	unbind()
	_world_layer = world_layer
	_overlay_layer = overlay_layer
	current = State.BOOT

func unbind() -> void:
	if is_instance_valid(_overlay):
		_overlay.exit()
		_overlay.get_parent().remove_child(_overlay)
		_overlay.free()
	if is_instance_valid(_overworld):
		_overworld.exit()
		_overworld.get_parent().remove_child(_overworld)
		_overworld.free()
	_overlay = null
	_overworld = null
	_world_layer = null
	_overlay_layer = null
	current = State.BOOT

func can_transition(to: State) -> bool:
	return to in LEGAL.get(current, [])

## Returns false and changes nothing if the transition is illegal or GameState is unbound.
func transition_to(to: State, payload: Dictionary = {}) -> bool:
	if not can_transition(to):
		push_error("GameState: illegal transition %s -> %s" % [State.keys()[current], State.keys()[to]])
		return false
	if _world_layer == null or _overlay_layer == null:
		push_error("GameState: not bound to Main layers")
		return false
	var from := current
	if transition_hook.is_valid():
		transition_hook.call(from, to)

	if is_instance_valid(_overlay):
		_overlay.exit()
		_overlay_layer.remove_child(_overlay)
		_overlay.queue_free()
		_overlay = null

	if to == State.TITLE:
		_free_overworld()
	if to == State.OVERWORLD:
		if not is_instance_valid(_overworld):
			_overworld = _instantiate(to)
			_world_layer.add_child(_overworld)
			_overworld.enter(payload)
		else:
			_overworld.visible = true
			_overworld.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		if is_instance_valid(_overworld):
			_overworld.visible = false
			_overworld.process_mode = Node.PROCESS_MODE_DISABLED
		_overlay = _instantiate(to)
		_overlay_layer.add_child(_overlay)
		_overlay.enter(payload)

	current = to
	state_changed.emit(from, to)
	return true

func _process(delta: float) -> void:
	if is_instance_valid(_overlay):
		_overlay.update(delta)
	elif current == State.OVERWORLD and is_instance_valid(_overworld):
		_overworld.update(delta)

func _free_overworld() -> void:
	if not is_instance_valid(_overworld):
		return
	_overworld.exit()
	if _overworld.get_parent() != null:
		_overworld.get_parent().remove_child(_overworld)
	_overworld.queue_free()
	_overworld = null


func _instantiate(state: State) -> GameStateBase:
	var scene := load(SCENES[state]) as PackedScene
	var node := scene.instantiate()
	assert(node is GameStateBase, "%s root must extend GameStateBase" % SCENES[state])
	return node

# --- EventBus reactions (the coupling firewall) ---

func _on_encounter_triggered(wild: Creature) -> void:
	if current == State.OVERWORLD:
		transition_to(State.BATTLE, {"wild": wild})

func _leave_battle() -> void:
	if current == State.BATTLE:
		transition_to(State.OVERWORLD)

func _on_creature_caught(_wild: Creature) -> void:
	if current == State.CATCHING:
		transition_to(State.OVERWORLD)

func _on_catch_failed(wild: Creature) -> void:
	if current == State.CATCHING:
		transition_to(State.BATTLE, {"wild": wild, "resume": true})

# --- Debug keys (PRD §7/§9 asks for manual triggers). Off in release builds. ---

func _unhandled_key_input(event: InputEvent) -> void:
	if not GameConfig.debug_keys_enabled() or not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_F1:
			var wild := load(GameConfig.DEBUG_WILD_PATH) as Creature
			if wild and current == State.OVERWORLD:
				EventBus.encounter_triggered.emit(wild.make_instance())
		KEY_F2:
			GameConfig.debug_force_catch = 1
			print("[debug] next catch forced: SUCCESS")
		KEY_F3:
			GameConfig.debug_force_catch = -1
			print("[debug] next catch forced: FAIL")
		KEY_F4:
			print("[debug] state=%s party=%s active=%s inv=%s" % [
				State.keys()[current],
				GameData.party.map(func(c): return c.name),
				GameData.get_active_creature().name if GameData.get_active_creature() else "none",
				GameData.inventory])
