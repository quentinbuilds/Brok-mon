extends "res://tests/autopilot/probe_base.gd"
## Phase 1: title → overworld, then assert the session and display contract.

const GS = preload("res://core/game_state.gd")


func _ready() -> void:
	await super._ready()
	await settle(3)

	report("display_width", GameConfig.DISPLAY_WIDTH)
	report("display_height", GameConfig.DISPLAY_HEIGHT)
	report("asset_width", GameConfig.ASSET_WIDTH)
	report("asset_height", GameConfig.ASSET_HEIGHT)
	report("boot_state", Game.current_id)

	dump_tree()
	save_frame("00_title")

	if Game.current_id != GS.Id.TITLE:
		report("error", "expected TITLE on boot, got %s" % Game.current_id)
		finish()
		return

	await press(InputManager.BTN_A, 80)
	await settle(3)
	report("after_start_state", Game.current_id)
	save_frame("01_overworld")

	if Game.current_id != GS.Id.OVERWORLD:
		report("error", "A on title did not reach OVERWORLD")
		finish()
		return

	var start: Vector2 = Game.player.position
	await press(InputManager.MOVE_RIGHT, 220)
	await settle(2)
	report("moved", Game.player.position.x > start.x)
	save_frame("02_moved")

	if Game.player.position.x <= start.x:
		report("error", "player did not move right")
		finish()
		return

	await press(InputManager.BTN_MENU, 80)
	await settle(3)
	report("menu_state", Game.current_id)
	save_frame("03_menu")

	if Game.current_id != GS.Id.MENU:
		report("error", "menu button did not open MENU")
		finish()
		return

	await press(InputManager.BTN_B, 80)
	await settle(3)
	report("back_state", Game.current_id)
	save_frame("04_back")

	if Game.current_id != GS.Id.OVERWORLD:
		report("error", "B on menu did not return to OVERWORLD")
		finish()
		return

	if Game.player.active_creature == null or Game.player.active_creature.creature_name != "Emberfox":
		report("error", "starter Emberfox missing")
		finish()
		return

	report("party_size", Game.player.party.size())
	report("viewport", get_viewport().get_visible_rect().size)
	finish()
