extends TestCase
## The iris overlay, and the title sequence that drives it.
##
## Headless cannot tell you whether the circle looks right - that is what running the game is for.
## What it can prove is the part that strands a player: the cover going up and never coming down.

func _t():
	return tree.root.get_node("Transition")

func _rect() -> ColorRect:
	return _t()._rect

func after_each() -> void:
	_t().snap_open()

# --- the overlay itself ---

func test_autoload_is_present() -> void:
	assert_true(_t() != null, "Transition autoload missing")

## It sits over every layer forever, so at rest it must be invisible and must not eat input.
func test_idle_overlay_is_invisible_and_ignores_input() -> void:
	assert_false(_t().is_covered())
	assert_false(_rect().visible, "the cover is drawn when nothing is transitioning")
	assert_eq(_rect().mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_it_draws_above_mains_overlay_layer() -> void:
	# Main's OverlayLayer is layer 1; a transition under it would be hidden by menus and battles.
	assert_true(_t().LAYER > 1, "transition layer %d is not above the overlays" % _t().LAYER)

func test_close_covers_and_open_uncovers() -> void:
	await _t().close(Vector2(100, 60), 0.05)
	assert_true(_t().is_covered(), "close() did not cover")
	assert_true(_rect().visible)
	await _t().open(0.05)
	assert_false(_t().is_covered(), "open() did not uncover")
	assert_false(_rect().visible, "the cover is still being drawn after open()")

## Two presses in the same frame must not start two transitions racing each other.
func test_closing_twice_is_harmless() -> void:
	await _t().close(Vector2(100, 60), 0.05)
	await _t().close(Vector2(10, 10), 0.05)
	assert_true(_t().is_covered())
	await _t().open(0.05)
	assert_false(_t().is_covered())

func test_open_on_an_already_open_iris_does_nothing() -> void:
	await _t().open(0.05)
	assert_false(_t().is_covered())
	assert_false(_rect().visible)

func test_snap_open_clears_a_cover_instantly() -> void:
	await _t().close(Vector2(100, 60), 0.05)
	_t().snap_open()
	assert_false(_t().is_covered())
	assert_false(_rect().visible)

## "Fully open" has to clear the furthest corner. Get this wrong for an off-centre iris and the
## game plays on with a black ring round the edge of the screen - subtle, permanent, and easy to
## mistake for a camera bug.
func test_open_radius_clears_the_furthest_corner_from_any_centre() -> void:
	var size: Vector2 = _t()._viewport_size()
	var aspect: Vector2 = _t()._aspect()
	for c in [Vector2(0.5, 0.5), Vector2(0.805, 0.55), Vector2.ZERO, Vector2.ONE, Vector2(1.0, 0.0)]:
		var r: float = _t()._open_radius(c)
		for corner in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1), Vector2.ONE]:
			var d: float = ((corner - c) * aspect).length()
			assert_true(r >= d,
				"centre %s: open radius %.4f leaves corner %s (%.4f) black" % [c, r, corner, d])
	assert_true(size.x > 0.0, "viewport has no size")

## A centre given outside the screen must not throw the iris somewhere unreachable.
func test_offscreen_centre_is_clamped() -> void:
	await _t().close(Vector2(9999, -9999), 0.0)
	var c: Vector2 = _t()._mat.get_shader_parameter("iris_center")
	assert_true(c.x >= 0.0 and c.x <= 1.0 and c.y >= 0.0 and c.y <= 1.0, "centre %s not clamped" % c)

# --- the title sequence ---

func _boot_main() -> Node:
	var main: Node = load("res://core/Main.tscn").instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	return main

func _teardown(main: Node) -> void:
	tree.root.remove_child(main)
	main.free()
	tree.root.get_node("GameState").unbind()
	_t().snap_open()

## Pressing A no longer leaves instantly - it plays the line first. If this ever goes back to a
## same-frame transition the iris is being skipped entirely.
func test_a_at_the_title_plays_the_line_before_leaving() -> void:
	var main := await _boot_main()
	var gs = tree.root.get_node("GameState")
	var title = gs._overlay
	assert_eq(gs.current, gs.State.TITLE)
	title.update(0.0)  # no input: nothing should happen
	assert_eq(gs.current, gs.State.TITLE)
	title._start()
	await tree.process_frame
	assert_eq(gs.current, gs.State.TITLE, "left the title before the line was read")
	assert_true(title._line.visible, "the line never appeared")
	_teardown(main)

## The whole point of the sequence: it must end with the player in the overworld AND able to see
## it. A cover that goes up and never comes down is a black screen and a lost build.
func test_the_sequence_ends_in_the_overworld_with_the_screen_clear() -> void:
	var main := await _boot_main()
	var gs = tree.root.get_node("GameState")
	var title = gs._overlay
	title._skipped = true  # skip the read time; the iris still runs
	title._start()
	for _i in 240:
		await tree.process_frame
		if gs.current == gs.State.OVERWORLD and not _t().is_covered():
			break
	assert_eq(gs.current, gs.State.OVERWORLD, "never reached the overworld")
	assert_false(_t().is_covered(), "the screen was left black in the overworld")
	assert_false(_rect().visible, "the cover is still drawn over the overworld")
	_teardown(main)

## The theme runs from the moment the title appears - it is the first thing anyone hears.
func test_the_title_plays_its_theme() -> void:
	var main := await _boot_main()
	var mgr = tree.root.get_node("AudioManager")
	assert_true(mgr.has_music(TitleState.MUSIC), "assets/music/title.ogg is missing")
	assert_eq(mgr.current_music(), TitleState.MUSIC, "the title came up silent")
	_teardown(main)
	mgr.stop_music()

## And it must be gone by the time the overworld is on screen: music outlives state scenes, so a
## theme left running here plays over the whole game.
func test_the_theme_does_not_follow_the_player_into_the_overworld() -> void:
	var main := await _boot_main()
	var gs = tree.root.get_node("GameState")
	var mgr = tree.root.get_node("AudioManager")
	var title = gs._overlay
	title._skipped = true
	title._start()
	for _i in 240:
		await tree.process_frame
		if gs.current == gs.State.OVERWORLD:
			break
	assert_eq(gs.current, gs.State.OVERWORLD, "never reached the overworld")
	assert_eq(mgr.current_music(), "", "the title theme is still playing in the overworld")
	_teardown(main)
	mgr.stop_music()

## Returning to the title while covered must not inherit the black screen.
func test_entering_the_title_clears_a_leftover_cover() -> void:
	await _t().close(Vector2(100, 60), 0.0)
	assert_true(_t().is_covered())
	var main := await _boot_main()
	assert_false(_t().is_covered(), "the title kept a cover left over from somewhere else")
	_teardown(main)
