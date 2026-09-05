extends TestCase
## InputManager wraps InputMap actions. Gameplay never reads Input directly.

func _im() -> Node:
	return tree.root.get_node("InputManager")

func after_each() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right", "confirm", "cancel", "menu"]:
		Input.action_release(a)

func test_idle_direction_is_zero() -> void:
	assert_eq(_im().direction(), Vector2i.ZERO)

func test_direction_left() -> void:
	Input.action_press("move_left")
	assert_true(_im().is_left())
	assert_eq(_im().direction(), Vector2i(-1, 0))

func test_vertical_wins_over_horizontal_no_diagonals() -> void:
	Input.action_press("move_up")
	Input.action_press("move_left")
	assert_eq(_im().direction(), Vector2i(0, -1))

func test_button_names_map_to_actions() -> void:
	Input.action_press("confirm")
	assert_true(_im().button_a_pressed())
	assert_false(_im().button_b_pressed())
	Input.action_press("cancel")
	assert_true(_im().button_b_pressed())
	Input.action_press("menu")
	assert_true(_im().button_menu_pressed())

func test_just_pressed_is_edge_triggered() -> void:
	Input.action_press("confirm")
	assert_true(_im().button_a_just_pressed(), "true on the press frame")
	await tree.process_frame
	assert_true(_im().button_a_pressed(), "still held")
	assert_false(_im().button_a_just_pressed(), "false on the following frame")
