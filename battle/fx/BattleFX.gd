class_name BattleFX
extends Node2D
## Hitstop, shake, damage popups, anger icons, intro wipe.

signal wipe_covered

var shake_offset: Vector2 = Vector2.ZERO
var _shake_time: float = 0.0
var _popups: Array = []
var _icons: Array = []
var _wipe_progress: float = -1.0


class DamagePopup:
	extends RefCounted
	var text: String
	var pos: Vector2
	var age: float = 0.0
	const LIFETIME := 0.7


class AngerIcon:
	extends RefCounted
	var pos: Vector2
	var age: float = 0.0
	var lifetime: float = BattleConfig.ANGER_ICON_TIME
	var wary: bool = false


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		var strength := clampf(_shake_time / BattleConfig.SHAKE_TIME, 0.0, 1.0)
		var amp := BattleConfig.SHAKE_PIXELS * strength
		shake_offset = Vector2(round(randf_range(-amp, amp)), round(randf_range(-amp, amp)))
		if _shake_time <= 0.0:
			shake_offset = Vector2.ZERO
	for p in _popups:
		p.age += delta
	_popups = _popups.filter(func(p): return p.age < DamagePopup.LIFETIME)
	for i in _icons:
		i.age += delta
	_icons = _icons.filter(func(i): return i.age < i.lifetime)
	queue_redraw()


func hitstop() -> void:
	var previous := Engine.time_scale
	Engine.time_scale = 0.0
	await get_tree().create_timer(float(BattleConfig.HITSTOP_FRAMES) / 60.0, true, false, true).timeout
	Engine.time_scale = previous


func shake() -> void:
	_shake_time = BattleConfig.SHAKE_TIME


func popup(text: String, at: Vector2) -> void:
	var p := DamagePopup.new()
	p.text = text
	p.pos = at
	_popups.append(p)


func anger_burst(at: Vector2, count: int, wary: bool) -> void:
	for i in maxi(1, count):
		var icon := AngerIcon.new()
		icon.pos = at + Vector2(float(i - 1) * 9.0 - float(count - 1) * 4.5, 0)
		icon.wary = wary
		_icons.append(icon)


func wipe_in() -> void:
	_wipe_progress = 0.0
	var t := create_tween()
	t.tween_property(self, "_wipe_progress", 1.0, BattleConfig.INTRO_WIPE_TIME * 0.5)
	await t.finished
	wipe_covered.emit()
	var t2 := create_tween()
	t2.tween_property(self, "_wipe_progress", 0.0, BattleConfig.INTRO_WIPE_TIME * 0.5)
	await t2.finished
	_wipe_progress = -1.0


func _draw() -> void:
	for p in _popups:
		var rise: float = -10.0 * (p.age / DamagePopup.LIFETIME)
		Dmg.text_outlined(self, Vector2i(int(p.pos.x), int(p.pos.y + rise)), p.text)
	for i in _icons:
		if fmod(i.age, BattleConfig.ANGER_ICON_CYCLE * 2.0) > BattleConfig.ANGER_ICON_CYCLE:
			continue
		if i.wary:
			_draw_sweat(i.pos)
		else:
			_draw_anger(i.pos)
	if _wipe_progress >= 0.0:
		_draw_wipe()


func _draw_anger(at: Vector2) -> void:
	var c := BattleConfig.DARKEST
	draw_rect(Rect2(at.x - 3, at.y - 1, 3, 2), c, true)
	draw_rect(Rect2(at.x + 1, at.y - 1, 3, 2), c, true)
	draw_rect(Rect2(at.x - 1, at.y - 4, 2, 3), c, true)
	draw_rect(Rect2(at.x - 1, at.y + 2, 2, 3), c, true)


func _draw_sweat(at: Vector2) -> void:
	var c := BattleConfig.DARKEST
	draw_rect(Rect2(at.x - 1, at.y - 4, 2, 3), c, true)
	draw_rect(Rect2(at.x - 2, at.y - 1, 4, 3), c, true)
	draw_rect(Rect2(at.x - 1, at.y + 2, 2, 1), BattleConfig.LIGHTEST, true)


func _draw_wipe() -> void:
	var bands := 8
	var band_h := float(BattleConfig.SCREEN.y) / float(bands)
	var covered := band_h * clampf(_wipe_progress, 0.0, 1.0)
	for b in bands:
		draw_rect(Rect2(0, float(b) * band_h, float(BattleConfig.SCREEN.x), covered), BattleConfig.DARKEST, true)
