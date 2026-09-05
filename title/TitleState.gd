extends GameStateBase
## Placeholder title screen. Person 6 replaces the visuals; keep the transition.
##
## A does not leave immediately any more: it plays the line, then irises down onto the trainer
## before handing over to the overworld. The iris itself lives on the Transition autoload, not in
## this scene - GameState frees this node during the swap, so an effect owned here could only ever
## play the closing half and would vanish before the overworld appeared.
##
## Pressing A again during the intro skips it. Nobody wants to sit through the same joke on their
## twentieth playtest run, and it gives the tests a way to reach OVERWORLD in two frames.

@onready var _line: Label = $Line
@onready var _line_panel: ColorRect = $LinePanel
@onready var _trainer: Sprite2D = $Trainer

## How long the line sits on screen before the iris starts closing.
const READ_TIME := 1.1

const IRIS_TIME := 0.55

var _starting := false
var _skipped := false

func _on_enter() -> void:
	# Arriving here with the screen still black (a return to title) would leave it black forever.
	Transition.snap_open()

func update(_delta: float) -> void:
	if _starting:
		if InputManager.button_a_just_pressed():
			_skipped = true
		return
	if InputManager.button_a_just_pressed():
		_start()

func _start() -> void:
	_starting = true
	AudioManager.play_sfx("sigh")
	_line.visible = true
	_line_panel.visible = true
	await _hold(READ_TIME)
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
		return
	GameData.reset()
	GameState.transition_to(GameState.State.OVERWORLD)
	# Not awaited on purpose: transition_to() queues this node for deletion, and awaiting past
	# that point resumes inside a freed object. The autoload finishes the reveal on its own.
	Transition.open(0.0 if _skipped else IRIS_TIME)

## A wait that a skip can cut short, checked per frame rather than as one long timer.
func _hold(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not _skipped:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		left -= get_process_delta_time()
