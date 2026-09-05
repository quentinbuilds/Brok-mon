class_name Dmg
extends RefCounted
## 4-shade DMG drawing helpers.


static func font() -> Font:
	return ThemeDB.fallback_font


static func panel(ci: CanvasItem, rect: Rect2i, border: int = BattleConfig.BOX_BORDER) -> void:
	ci.draw_rect(Rect2(rect), BattleConfig.DARKEST, true)
	var inner := Rect2(
		rect.position.x + border, rect.position.y + border,
		rect.size.x - border * 2, rect.size.y - border * 2
	)
	ci.draw_rect(inner, BattleConfig.LIGHTEST, true)


static func text(
	ci: CanvasItem, pos: Vector2i, s: String,
	color: Color = BattleConfig.DARKEST, size: int = BattleConfig.FONT_SIZE
) -> void:
	ci.draw_string(font(), Vector2(pos.x, pos.y + size), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func text_outlined(ci: CanvasItem, pos: Vector2i, s: String, size: int = BattleConfig.FONT_SIZE) -> void:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			text(ci, Vector2i(pos.x + dx, pos.y + dy), s, BattleConfig.DARKEST, size)
	text(ci, pos, s, BattleConfig.LIGHTEST, size)


static func text_width(s: String, size: int = BattleConfig.FONT_SIZE) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func hp_bar(ci: CanvasItem, rect: Rect2i, fraction: float, flash_on: bool = false) -> void:
	ci.draw_rect(Rect2(rect), BattleConfig.DARKEST, true)
	var inner_w := rect.size.x - 2
	var inner_h := rect.size.y - 2
	var fill_w := int(round(clampf(fraction, 0.0, 1.0) * float(inner_w)))
	if fraction > 0.0:
		fill_w = maxi(1, fill_w)
	var fill_color := BattleConfig.DARK
	if flash_on:
		fill_color = BattleConfig.LIGHT
	if fill_w > 0:
		ci.draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1, fill_w, inner_h), fill_color, true)


static func cursor(ci: CanvasItem, pos: Vector2i) -> void:
	var pts := PackedVector2Array([
		Vector2(pos.x, pos.y),
		Vector2(pos.x + 4, pos.y + 3),
		Vector2(pos.x, pos.y + 6),
	])
	ci.draw_colored_polygon(pts, BattleConfig.DARKEST)


static func platform(ci: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(Vector2(center.x + cos(a) * radius.x, center.y + sin(a) * radius.y))
	ci.draw_colored_polygon(pts, color)
