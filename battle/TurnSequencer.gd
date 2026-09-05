class_name TurnSequencer
extends Node
## Await-based battle choreography. Input lock is structural.

var ui: BattleUI
var instant: bool = false


func _wait(seconds: float) -> void:
	if instant or seconds <= 0.0:
		await get_tree().process_frame
		return
	await get_tree().create_timer(seconds).timeout


func _wait_for_a() -> void:
	if instant:
		await get_tree().process_frame
		return
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if InputManager.button_a_just_pressed():
			return


func say_auto(text: String) -> void:
	ui.mode = BattleUI.Mode.MESSAGE
	ui.message.show_line(text)
	if instant:
		ui.message.skip_to_end()
		await get_tree().process_frame
		return
	while not ui.message.is_complete():
		await get_tree().process_frame
		if InputManager.button_a_just_pressed():
			ui.message.skip_to_end()
		if InputManager.button_menu_just_pressed():
			ui.message.fast = not ui.message.fast
	await _wait(BattleConfig.MESSAGE_HOLD)


func say_wait(text: String) -> void:
	ui.mode = BattleUI.Mode.MESSAGE
	ui.message.show_line(text)
	if instant:
		ui.message.skip_to_end()
		await get_tree().process_frame
		return
	while not ui.message.is_complete():
		await get_tree().process_frame
		if InputManager.button_a_just_pressed():
			ui.message.skip_to_end()
		if InputManager.button_menu_just_pressed():
			ui.message.fast = not ui.message.fast
	await _wait_for_a()


func intro(enemy_name: String) -> void:
	ui.show_enemy_panel = false
	ui.show_player_panel = false
	ui.enemy_view.hidden_until_intro = true
	ui.player_view.hidden_until_intro = true
	if not instant:
		await ui.fx.wipe_in()
	ui.enemy_view.slide_in(Vector2(70, 0))
	ui.show_enemy_panel = true
	await _wait(BattleConfig.SLIDE_IN_TIME)
	ui.player_view.slide_in(Vector2(-70, 0))
	ui.show_player_panel = true
	await _wait(BattleConfig.SLIDE_IN_TIME)
	await say_auto(BattleCopy.intro(enemy_name))


func lunge(view: CreatureView) -> void:
	if instant:
		await get_tree().process_frame
		return
	var t := view.lunge()
	await t.finished


func impact(view: CreatureView, damage: int, at: Vector2) -> void:
	ui.audio.hit()
	if not instant:
		await ui.fx.hitstop()
	view.flash()
	ui.fx.shake()
	if damage > 0:
		ui.fx.popup(str(damage), at)
	await _wait(float(BattleConfig.FLASH_FRAMES) / 60.0)


func drain_enemy_hp() -> void:
	if instant:
		ui.enemy_display_hp = float(ui.enemy.hp)
		await get_tree().process_frame
		return
	var t := create_tween()
	t.tween_property(ui, "enemy_display_hp", float(ui.enemy.hp), BattleConfig.HP_DRAIN_TIME)
	await t.finished


func drain_player_hp() -> void:
	if instant:
		ui.player_display_hp = float(ui.player.hp)
		await get_tree().process_frame
		return
	var t := create_tween()
	t.tween_property(ui, "player_display_hp", float(ui.player.hp), BattleConfig.HP_DRAIN_TIME)
	await t.finished


func faint(view: CreatureView) -> void:
	ui.audio.faint()
	if instant:
		view.faint_progress = 1.0
		await get_tree().process_frame
		return
	var t := view.faint()
	await t.finished


func anger(count: int, wary: bool) -> void:
	ui.fx.anger_burst(ui.enemy_head(), count, wary)
	await _wait(0.0 if instant else 0.35)
