extends GameStateBase
class_name TitleState
## Fake 1998 cartridge boot, then PRESS A. Person 6 may restyle; keep the transition.

enum Beat { BOOT, LABEL, TITLE }

const BOOT_SECS := 0.7
const LABEL_SECS := 1.1
const GLITCH_CYCLE := 2.4
const GLITCH_ON := 0.14

const LABEL_TEXT := "GOK-MON\n(C)1998 QUENTIN SOFT\nLICENSED BY NOBODY"
const TITLE_TEXT := "GOK-MON\n\nPRESS A"
const GLITCH_TEXT := "GOK-MON\n\nPRESS A TO\nCONSENT TO TRAINING"

const LIGHTEST := Color8(0x9b, 0xbc, 0x0f)
const DARKEST := Color8(0x0f, 0x38, 0x0f)

@onready var _backdrop: ColorRect = $Backdrop
@onready var _label: Label = $Label

var beat: int = Beat.BOOT
var _elapsed := 0.0


func _on_enter() -> void:
	_set_beat(Beat.BOOT)
	if AudioManager.has_sfx("confirm"):
		AudioManager.play_sfx("confirm")


func update(delta: float) -> void:
	if InputManager.button_a_just_pressed():
		GameData.reset()
		GameState.transition_to(GameState.State.OVERWORLD)
		return
	_elapsed += delta
	match beat:
		Beat.BOOT:
			if _elapsed >= BOOT_SECS:
				_set_beat(Beat.LABEL)
		Beat.LABEL:
			if _elapsed >= LABEL_SECS:
				_set_beat(Beat.TITLE)
		Beat.TITLE:
			_refresh_title_glitch()


func _set_beat(next: int) -> void:
	beat = next
	_elapsed = 0.0
	if _backdrop:
		_backdrop.color = LIGHTEST
	if _label == null:
		return
	_label.add_theme_color_override("font_color", DARKEST)
	match beat:
		Beat.BOOT:
			_label.text = ""
		Beat.LABEL:
			_label.text = LABEL_TEXT
			if AudioManager.has_sfx("menu"):
				AudioManager.play_sfx("menu")
		Beat.TITLE:
			_label.text = TITLE_TEXT


func _refresh_title_glitch() -> void:
	if _label == null:
		return
	if fmod(_elapsed, GLITCH_CYCLE) < GLITCH_ON:
		_label.text = GLITCH_TEXT
	else:
		_label.text = TITLE_TEXT
