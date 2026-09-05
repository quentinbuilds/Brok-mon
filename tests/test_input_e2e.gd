extends TestCase
## End-to-end input: boots the real Main.tscn and pushes real InputEventKeys through it,
## proving key -> InputMap -> InputManager -> GameState.update() -> transition actually works.
## The per-action binding contract lives in test_input_bindings.gd; this guards the whole chain.

var _main: Node
var _gs

func before_each() -> void:
	_gs = tree.root.get_node("GameState")
	_main = load("res://core/Main.tscn").instantiate()
	tree.root.add_child(_main)

func after_each() -> void:
	tree.root.remove_child(_main)
	_main.free()
	_gs.unbind()

func _tap(code: Key) -> void:
	var down := InputEventKey.new()
	down.physical_keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	Input.flush_buffered_events()

func _lift(code: Key) -> void:
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()

func _name_of(s) -> String:
	return _gs.State.keys()[s]

func test_boots_to_title() -> void:
	await tree.process_frame
	assert_eq(_name_of(_gs.current), "TITLE", "boot state")

func test_enter_leaves_title() -> void:
	await tree.process_frame
	_tap(KEY_ENTER)
	await tree.process_frame
	_lift(KEY_ENTER)
	assert_eq(_name_of(_gs.current), "OVERWORLD", "Enter at title")

func test_space_leaves_title() -> void:
	await tree.process_frame
	_tap(KEY_SPACE)
	await tree.process_frame
	_lift(KEY_SPACE)
	assert_eq(_name_of(_gs.current), "OVERWORLD", "Space at title")

func test_escape_opens_menu_from_overworld() -> void:
	await tree.process_frame
	_tap(KEY_ENTER)
	await tree.process_frame
	_lift(KEY_ENTER)
	await tree.process_frame
	_tap(KEY_ESCAPE)
	await tree.process_frame
	_lift(KEY_ESCAPE)
	assert_eq(_name_of(_gs.current), "MENU", "Escape in overworld")
	for i in 10:
		await tree.process_frame
	assert_eq(_name_of(_gs.current), "MENU", "opening Escape must not immediately close menu")

func test_tab_opens_menu_from_overworld() -> void:
	await tree.process_frame
	_tap(KEY_ENTER)
	await tree.process_frame
	_lift(KEY_ENTER)
	await tree.process_frame
	_tap(KEY_TAB)
	await tree.process_frame
	_lift(KEY_TAB)
	assert_eq(_name_of(_gs.current), "MENU", "Tab in overworld")
	for i in 10:
		await tree.process_frame
	assert_eq(_name_of(_gs.current), "MENU", "opening Tab must not immediately close menu")
