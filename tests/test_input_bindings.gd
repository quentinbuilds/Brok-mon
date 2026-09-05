extends TestCase
## The UNO Q Modulino bridge delivers input as keyboard keys (summer-uno-q):
## joystick -> W/A/S/D (arrows also fine), button A -> J, button B -> K, button C -> L.
## This guards the project.godot [input] contract so nobody breaks hardware play.

func _has_key(action: String, keycode: Key) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev.physical_keycode == keycode or ev.keycode == keycode):
			return true
	return false

func test_joystick_wasd_bound_to_movement() -> void:
	assert_true(_has_key("move_up", KEY_W), "W -> move_up")
	assert_true(_has_key("move_down", KEY_S), "S -> move_down")
	assert_true(_has_key("move_left", KEY_A), "A -> move_left")
	assert_true(_has_key("move_right", KEY_D), "D -> move_right")

func test_arrows_still_bound_for_desktop() -> void:
	assert_true(_has_key("move_up", KEY_UP))
	assert_true(_has_key("move_right", KEY_RIGHT))

func test_modulino_buttons_bound() -> void:
	assert_true(_has_key("confirm", KEY_J), "button A (J) -> confirm")
	assert_true(_has_key("cancel", KEY_K), "button B (K) -> cancel")
	assert_true(_has_key("menu", KEY_L), "button C (L) -> menu")

func test_desktop_keys_bound() -> void:
	# Most playtesting happens on a Mac or Windows keyboard, not the handheld.
	# Space/Enter and Escape are what testers reach for first.
	assert_true(_has_key("confirm", KEY_SPACE), "Space -> confirm")
	assert_true(_has_key("confirm", KEY_ENTER), "Enter -> confirm")
	assert_true(_has_key("cancel", KEY_ESCAPE), "Escape -> cancel")
	assert_true(_has_key("menu", KEY_ESCAPE), "Escape -> menu")

func test_all_seven_actions_exist() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right", "confirm", "cancel", "menu"]:
		assert_true(InputMap.has_action(a), "missing action %s" % a)
