extends Node
## Hardware seam. Gameplay talks to this, never to joystick/Arduino APIs.
## PC mapping is central and can be swapped for UNO Q later.

const MOVE_UP := "move_up"
const MOVE_DOWN := "move_down"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const BTN_A := "btn_a"
const BTN_B := "btn_b"
const BTN_MENU := "btn_menu"


func _ready() -> void:
	_bind(MOVE_UP, [KEY_W, KEY_UP])
	_bind(MOVE_DOWN, [KEY_S, KEY_DOWN])
	_bind(MOVE_LEFT, [KEY_A, KEY_LEFT])
	_bind(MOVE_RIGHT, [KEY_D, KEY_RIGHT])
	_bind(BTN_A, [KEY_Z, KEY_ENTER, KEY_SPACE])
	_bind(BTN_B, [KEY_X, KEY_ESCAPE])
	_bind(BTN_MENU, [KEY_C, KEY_TAB])


func is_up() -> bool:
	return Input.is_action_pressed(MOVE_UP)


func is_down() -> bool:
	return Input.is_action_pressed(MOVE_DOWN)


func is_left() -> bool:
	return Input.is_action_pressed(MOVE_LEFT)


func is_right() -> bool:
	return Input.is_action_pressed(MOVE_RIGHT)


func button_a_pressed() -> bool:
	return Input.is_action_pressed(BTN_A)


func button_b_pressed() -> bool:
	return Input.is_action_pressed(BTN_B)


func button_menu_pressed() -> bool:
	return Input.is_action_pressed(BTN_MENU)


func button_a_just_pressed() -> bool:
	return Input.is_action_just_pressed(BTN_A)


func button_b_just_pressed() -> bool:
	return Input.is_action_just_pressed(BTN_B)


func button_menu_just_pressed() -> bool:
	return Input.is_action_just_pressed(BTN_MENU)


func move_vector() -> Vector2:
	## Four-direction only. Vertical wins if both axes are held.
	if is_up():
		return Vector2.UP
	if is_down():
		return Vector2.DOWN
	if is_left():
		return Vector2.LEFT
	if is_right():
		return Vector2.RIGHT
	return Vector2.ZERO


func _bind(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode as Key
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
