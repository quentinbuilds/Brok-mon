class_name MessageBox
extends RefCounted
## Character-by-character battle text.

var line: String = ""
var revealed: float = 0.0
var fast: bool = false
var awaiting_advance: bool = false
var prompt_phase: float = 0.0


func show_line(text: String) -> void:
	line = text
	revealed = 0.0
	awaiting_advance = false
	prompt_phase = 0.0


func clear() -> void:
	line = ""
	revealed = 0.0
	awaiting_advance = false


func is_complete() -> bool:
	return revealed >= float(line.length())


func visible_text() -> String:
	return line.substr(0, int(revealed))


func tick(delta: float) -> void:
	prompt_phase += delta
	if is_complete():
		awaiting_advance = true
		return
	var rate := BattleConfig.TEXT_CHARS_PER_SEC_FAST if fast else BattleConfig.TEXT_CHARS_PER_SEC
	revealed = minf(revealed + rate * delta, float(line.length()))
	if is_complete():
		awaiting_advance = true


func skip_to_end() -> void:
	revealed = float(line.length())
	awaiting_advance = true


func prompt_visible() -> bool:
	return awaiting_advance and fmod(prompt_phase, 0.8) < 0.5


static func wrap_lines(
	text: String,
	max_width: float = BattleConfig.TEXT_MAX_WIDTH,
	max_lines: int = BattleConfig.TEXT_MAX_LINES
) -> Array[String]:
	var out: Array[String] = []
	var current := ""
	var max_chars := maxi(1, int(max_width / float(BattleConfig.FONT_SIZE)))
	for word in text.split(" ", false):
		var candidate := word if current.is_empty() else current + " " + word
		if candidate.length() <= max_chars:
			current = candidate
		else:
			if not current.is_empty():
				out.append(current)
			current = word
		if out.size() >= max_lines:
			break
	if not current.is_empty() and out.size() < max_lines:
		out.append(current)
	return out
