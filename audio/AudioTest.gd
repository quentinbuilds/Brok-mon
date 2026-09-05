extends GameStateBase
## Sound test. Proves audio actually reaches the speakers on real hardware — headless tests
## run on the Dummy audio driver and can never tell you that.
## Reached from the menu (MENU -> A), and also runnable on its own with F6.
## A and B play the sampled clips when they are present, and fall back to the synth blips when
## they are not, so this screen still works in a checkout without assets/audio/.
## Entering the screen also starts the battle track, so C then A from the overworld is a one-gesture
## check that music - not just blips - is reaching the speakers.

@onready var _label: Label = $Label

const A_SFX := ["fahhh", "confirm"]
const B_SFX := ["giant", "cancel"]

## Track started on entry. Missing on a checkout without assets/music/, which is not an error here:
## the effects half of this screen still works, so only the music line goes away.
const MUSIC := "battle"

var _last := "-"

func _on_enter() -> void:
	if AudioManager.has_music(MUSIC):
		AudioManager.play_music(MUSIC)
	_render()

## Music lives on the AudioManager autoload and would otherwise keep playing over the menu.
func exit() -> void:
	AudioManager.stop_music(0.4)

func update(_delta: float) -> void:
	# C leaves. Run standalone with F6 there is no menu to return to, so stay put instead of
	# asking an unbound GameState for a transition it would only reject.
	if InputManager.button_menu_just_pressed():
		if not _is_standalone():
			GameState.transition_to(GameState.State.MENU)
		return
	if InputManager.button_a_just_pressed():
		_fire(_first_present(A_SFX))
	elif InputManager.button_b_just_pressed():
		_fire(_first_present(B_SFX))
	elif InputManager.direction_just_pressed() != Vector2i.ZERO:
		_fire("bump")

## First name that AudioManager actually knows; the last entry is the guaranteed synth fallback.
func _first_present(names: Array) -> String:
	for n in names:
		if AudioManager.has_sfx(n):
			return n
	return names[names.size() - 1]

func _fire(sfx_name: String) -> void:
	_last = sfx_name if AudioManager.play_sfx(sfx_name) else "FAILED: " + sfx_name
	_render()

func _render() -> void:
	var music := AudioManager.current_music()
	_label.text = "SOUND TEST\n\nA and B  play a sound\njoystick  blip\nC  back\n\nmusic: %s\nlast: %s" % [
		music if music != "" else "-", _last]
