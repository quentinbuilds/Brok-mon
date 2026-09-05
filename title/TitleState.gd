extends GameStateBase
class_name TitleState
## Fake 1998 cartridge boot on Person 6's title art: BOOT -> LABEL -> TITLE.
##
## A does not leave immediately: it plays the line, then irises down onto the trainer before
## handing over to the overworld. The iris itself lives on the Transition autoload, not in this
## scene - GameState frees this node during the swap, so an effect owned here could only ever play
## the closing half and would vanish before the overworld appeared.
##
## Pressing A again during the intro skips it. Nobody wants to sit through the same joke on their
## twentieth playtest run, and it gives the tests a way to reach OVERWORLD in two frames.

enum Beat { BOOT, LABEL, TITLE }

const BOOT_SECS := 0.7
const LABEL_SECS := 1.1

## The LABEL beat used to carry a two-line copyright gag. Two lines at font size 10 did not fit
## the 20 px prompt label and spilled out of its panel, and the joke was not worth the layout,
## so the beat now just brings the logo up on its own before the prompt joins it.
const TITLE_PROMPT := "PRESS A TO START"

## How long the line sits on screen before the iris starts closing.
const READ_TIME := 1.1

const IRIS_TIME := 0.55

## The title theme, started on entry and faded out under the iris so the overworld opens on its
## own silence. Absent in a checkout without assets/music/, which is not an error here - the
## screen still boots, glitches and leaves, it just does it quietly.
const MUSIC := "title"

@onready var _trainer: Sprite2D = $Trainer
@onready var _title: Label = $Title
@onready var _prompt: Label = $Prompt
@onready var _prompt_panel: ColorRect = $PromptPanel
@onready var _line: Label = $Line
@onready var _line_panel: ColorRect = $LinePanel

var beat: int = Beat.BOOT
var _elapsed := 0.0
var _starting := false
var _skipped := false


func _on_enter() -> void:
	# Arriving here with the screen still black (a return to title) would leave it black forever.
	Transition.snap_open()
	_set_beat(Beat.BOOT)
	if AudioManager.has_sfx("confirm"):
		AudioManager.play_sfx("confirm")
	_start_music()


func update(delta: float) -> void:
	# The boot sequence stops the moment the player commits: the cartridge chrome has nothing left
	# to say once the line is on screen.
	if _starting:
		if InputManager.button_a_just_pressed():
			_skipped = true
		return
	if InputManager.button_a_just_pressed():
		_start()
		return
	_elapsed += delta
	match beat:
		Beat.BOOT:
			if _elapsed >= BOOT_SECS:
				_set_beat(Beat.LABEL)
		Beat.LABEL:
			if _elapsed >= LABEL_SECS:
				_set_beat(Beat.TITLE)


func _start() -> void:
	_starting = true
	AudioManager.play_sfx("sigh")
	_line.visible = true
	_line_panel.visible = true
	await _hold(READ_TIME)
	# Fade with the iris rather than at the handover: the theme is 94 s of music that has been
	# playing since boot, and cutting it dead on the transition is the most audible way to end it.
	AudioManager.stop_music(0.0 if _skipped else IRIS_TIME)
	# Close onto the trainer rather than the middle of the screen: it is the only thing on the
	# title that will still be there, in a manner of speaking, after the cut.
	await Transition.close(_trainer.position, 0.0 if _skipped else IRIS_TIME)
	if _is_standalone():
		# Run on its own with F6 there is no GameState to hand over to. Reopen so the screen is
		# not left black, and allow another go.
		await Transition.open(IRIS_TIME)
		_starting = false
		_skipped = false
		_line.visible = false
		_line_panel.visible = false
		_set_beat(Beat.TITLE)
		_start_music()
		return
	GameData.reset()
	GameState.transition_to(GameState.State.OVERWORLD)
	# Not awaited on purpose: transition_to() queues this node for deletion, and awaiting past
	# that point resumes inside a freed object. The autoload finishes the reveal on its own.
	Transition.open(0.0 if _skipped else IRIS_TIME)


func _start_music() -> void:
	if AudioManager.has_music(MUSIC):
		AudioManager.play_music(MUSIC)


## A wait that a skip can cut short, checked per frame rather than as one long timer.
func _hold(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not _skipped:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		left -= get_process_delta_time()


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
				_title.text = "Brokémon"
			if _prompt:
				_prompt.text = ""
			_show_prompt(false)
			if AudioManager.has_sfx("menu"):
				AudioManager.play_sfx("menu")
		Beat.TITLE:
			_show_chrome(true)
			if _title:
				_title.text = "Brokémon"
			if _prompt:
				_prompt.text = TITLE_PROMPT
			_show_prompt(true)


func _show_chrome(on: bool) -> void:
	if _trainer:
		_trainer.visible = on
	if _title:
		_title.visible = on
	_show_prompt(on)


## The prompt and the panel behind it travel together; an empty panel is just a cream bar.
func _show_prompt(on: bool) -> void:
	if _prompt:
		_prompt.visible = on
	if _prompt_panel:
		_prompt_panel.visible = on

