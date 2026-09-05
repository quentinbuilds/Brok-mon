extends Node
## Input abstraction (PRD §5, §11). Gameplay code calls these, never Input directly.
## Physical bindings live in project.godot [input]; remap there, not here.

const A := "confirm"
const B := "cancel"
const MENU := "menu"

func is_up() -> bool:
	return Input.is_action_pressed("move_up")

func is_down() -> bool:
	return Input.is_action_pressed("move_down")

func is_left() -> bool:
	return Input.is_action_pressed("move_left")

func is_right() -> bool:
	return Input.is_action_pressed("move_right")

## 4-way direction, no diagonals. Vertical wins ties so diagonal stick input is deterministic.
func direction() -> Vector2i:
	if is_up():
		return Vector2i.UP
	if is_down():
		return Vector2i.DOWN
	if is_left():
		return Vector2i.LEFT
	if is_right():
		return Vector2i.RIGHT
	return Vector2i.ZERO

func button_a_pressed() -> bool:
	return Input.is_action_pressed(A)

func button_b_pressed() -> bool:
	return Input.is_action_pressed(B)

func button_menu_pressed() -> bool:
	return Input.is_action_pressed(MENU)

func button_a_just_pressed() -> bool:
	return Input.is_action_just_pressed(A)

func button_b_just_pressed() -> bool:
	return Input.is_action_just_pressed(B)

func button_menu_just_pressed() -> bool:
	return Input.is_action_just_pressed(MENU)

## Edge-triggered direction, handy for menus. Returns ZERO unless a direction was pressed this frame.
func direction_just_pressed() -> Vector2i:
	if Input.is_action_just_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_just_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_just_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_just_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO
