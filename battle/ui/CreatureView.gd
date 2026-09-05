class_name CreatureView
extends Node2D
## One creature on the battle field: sprite (or silhouette), bob, lunge, flash, faint.

var creature: Creature
var rect: Rect2i = Rect2i(0, 0, 40, 40)
var use_back_sprite: bool = false
var lunge_direction: Vector2 = Vector2(1, -1)
var anim_offset: Vector2 = Vector2.ZERO
var bob_phase: float = 0.0
var faint_progress: float = 0.0
var hidden_until_intro: bool = false
var flash_amount: float = 0.0

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_refresh_texture()
	set_process(true)


func bind(c: Creature) -> void:
	creature = c
	faint_progress = 0.0
	anim_offset = Vector2.ZERO
	if is_inside_tree():
		_refresh_texture()


func _refresh_texture() -> void:
	if creature == null or _sprite == null:
		return
	_sprite.texture = creature.sprite
	if creature.sprite != null:
		var size := creature.sprite.get_size()
		if size.x > 0.0 and size.y > 0.0:
			_sprite.scale = Vector2(float(rect.size.x) / size.x, float(rect.size.y) / size.y)


func _process(delta: float) -> void:
	bob_phase += delta * BattleConfig.IDLE_BOB_SPEED
	if _sprite != null:
		_sprite.position = _draw_origin()
		_sprite.visible = _sprite.texture != null and not hidden_until_intro
		_sprite.modulate = Color(1, 1, 1, 1).lerp(BattleConfig.LIGHTEST, flash_amount)
	queue_redraw()


func _draw_origin() -> Vector2:
	var bob := sin(bob_phase) * BattleConfig.IDLE_BOB_PIXELS
	var fall := faint_progress * float(rect.size.y) * 0.9
	return Vector2(rect.position.x, rect.position.y) + anim_offset + Vector2(0, bob + fall)


func _draw() -> void:
	if hidden_until_intro:
		return
	if _sprite != null and _sprite.texture != null:
		return
	_draw_fallback()


func _draw_fallback() -> void:
	if creature == null:
		return
	var origin := _draw_origin()
	var w := float(rect.size.x)
	var h := float(rect.size.y)
	var body := Rect2(origin.x + w * 0.18, origin.y + h * 0.35, w * 0.64, h * 0.5)
	draw_rect(body, BattleConfig.DARK, true)
	draw_circle(Vector2(origin.x + w * 0.5, origin.y + h * 0.34), w * 0.26, BattleConfig.DARK)
	draw_rect(Rect2(origin.x + w * 0.24, origin.y + h * 0.82, w * 0.16, h * 0.14), BattleConfig.DARKEST, true)
	draw_rect(Rect2(origin.x + w * 0.60, origin.y + h * 0.82, w * 0.16, h * 0.14), BattleConfig.DARKEST, true)
	if not use_back_sprite:
		draw_rect(Rect2(origin.x + w * 0.38, origin.y + h * 0.28, 3, 3), BattleConfig.LIGHTEST, true)
		draw_rect(Rect2(origin.x + w * 0.56, origin.y + h * 0.28, 3, 3), BattleConfig.LIGHTEST, true)


func flash() -> void:
	var frames := float(BattleConfig.FLASH_FRAMES) / 60.0
	var t := create_tween()
	t.tween_callback(func(): flash_amount = 1.0)
	t.tween_interval(frames)
	t.tween_callback(func(): flash_amount = 0.0)


func lunge() -> Tween:
	var reach := Vector2(6, 6) * lunge_direction
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "anim_offset", -reach * 0.4, BattleConfig.WINDUP_TIME)
	t.tween_property(self, "anim_offset", reach, BattleConfig.LUNGE_TIME)
	t.tween_property(self, "anim_offset", Vector2.ZERO, BattleConfig.LUNGE_TIME)
	return t


func slide_in(from: Vector2) -> Tween:
	anim_offset = from
	hidden_until_intro = false
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "anim_offset", Vector2.ZERO, BattleConfig.SLIDE_IN_TIME)
	return t


func faint() -> Tween:
	var t := create_tween()
	t.set_ease(Tween.EASE_IN)
	t.tween_property(self, "faint_progress", 1.0, BattleConfig.FAINT_TIME)
	return t
