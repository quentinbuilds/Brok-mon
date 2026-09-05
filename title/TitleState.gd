extends GameStateBase
class_name TitleState
## Fake 1998 cartridge boot on Person 6's title art. A always starts the game.

enum Beat { BOOT, LABEL, TITLE }

const BOOT_SECS := 0.7
const LABEL_SECS := 1.1
const GLITCH_CYCLE := 2.4
const GLITCH_ON := 0.14

const LABEL_PROMPT := "(C)1998 QUENTIN SOFT\nLICENSED BY NOBODY"
const TITLE_PROMPT := "PRESS A TO START"
const GLITCH_PROMPT := "PRESS A TO CONSENT TO TRAINING"

@onready var _trainer: Sprite2D = $Trainer
@onready var _title: Label = $Title
@onready var _prompt: Label = $Prompt
@onready var _prompt_panel: ColorRect = $PromptPanel

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
	match beat:
		Beat.BOOT:
			_show_chrome(false)
			if _title:
				_title.text = ""
			if _prompt:
				_prompt.text = ""
		Beat.LABEL:
			_show_chrome(true)
			if _title:
				_title.text = "GOK-MON"
			if _prompt:
				_prompt.text = LABEL_PROMPT
			if AudioManager.has_sfx("menu"):
				AudioManager.play_sfx("menu")
		Beat.TITLE:
			_show_chrome(true)
			if _title:
				_title.text = "GOK-MON"
			if _prompt:
				_prompt.text = TITLE_PROMPT


func _show_chrome(on: bool) -> void:
	if _trainer:
		_trainer.visible = on
	if _title:
		_title.visible = on
	if _prompt:
		_prompt.visible = on
	if _prompt_panel:
		_prompt_panel.visible = on


func _refresh_title_glitch() -> void:
	if _prompt == null:
		return
	if fmod(_elapsed, GLITCH_CYCLE) < GLITCH_ON:
		_prompt.text = GLITCH_PROMPT
	else:
		_prompt.text = TITLE_PROMPT
