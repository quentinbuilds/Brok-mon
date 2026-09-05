extends Node
## Sound effects (PRD §10). Gameplay calls AudioManager.play_sfx("confirm"), never AudioStreamPlayer.
## Sounds are synthesised at startup by GBSynth, so the repo needs no audio files at all;
## a .wav in assets/audio/ named after an effect overrides that effect if one is present.
##
## Nothing here is wired to EventBus yet: which sound plays on battle_won, creature_caught or
## menu_opened is a creative call and belongs to Person 6. Wiring one up later is a single
## EventBus.<signal>.connect(...) line in _ready().

## Overlapping effects share this many players. The DMG's four channels are a nice homage but a
## bad cap once sampled clips are in play: a 2s clip would be cut off by the fourth blip after it.
const VOICES := 8

## Drop "<name>.wav" in here and it replaces the synth effect of that name, no code change.
const OVERRIDE_DIR := "res://assets/audio"

## Effects that exist only as files - no synth fallback. Listed explicitly rather than discovered
## by scanning OVERRIDE_DIR, because an exported build remaps imported resources and a directory
## listing of res:// does not reliably show them.
const FILE_ONLY_SFX := ["fahhh", "giant"]

var _sfx: Dictionary = {}
var _overridden: Array[String] = []
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	_build_library()
	for _i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func has_sfx(sfx_name: String) -> bool:
	return _sfx.has(sfx_name)

func sfx_names() -> Array:
	var names := _sfx.keys()
	names.sort()
	return names

func get_sfx(sfx_name: String) -> AudioStream:
	return _sfx.get(sfx_name)

## Names currently served by a file in OVERRIDE_DIR rather than by the synth.
func overridden_sfx() -> Array[String]:
	return _overridden.duplicate()

## Plays a named effect. Returns false on an unknown name, which is a programming error:
## fail loudly rather than going silently quiet and leaving someone to wonder why.
func play_sfx(sfx_name: String) -> bool:
	if not _sfx.has(sfx_name):
		push_error("AudioManager: unknown sfx '%s'. Known: %s" % [sfx_name, ", ".join(sfx_names())])
		return false
	if _players.is_empty():
		return false
	var p := _free_player()
	p.stream = _sfx[sfx_name]
	p.play()
	return true

## Prefer a voice that is not busy. Only steal one when every voice is genuinely in use - the
## naive round-robin cut long sounds short while other players sat idle.
func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	var stolen := _players[_next]
	_next = (_next + 1) % _players.size()
	return stolen

func _build_library() -> void:
	# Rising two-note blip: the "yes".
	_sfx["confirm"] = GBSynth.arp([880.0, 1318.0], 0.035, GBSynth.DUTY_50)
	# Low, thinner buzz: the "no".
	_sfx["cancel"] = GBSynth.square(196.0, 0.09, GBSynth.DUTY_25)
	# Quiet click for opening and closing panels.
	_sfx["menu"] = GBSynth.arp([587.0, 880.0], 0.028, GBSynth.DUTY_12_5, 0.25)
	# Noise-channel tick, for footsteps and bumps.
	_sfx["bump"] = GBSynth.noise(0.05, 12, 0.2)
	_apply_overrides()

## A real recording beats a synth blip once someone has authored one, so let a file win.
## Missing files are the normal case and simply leave the synth version in place - that way a
## checkout without the audio folder still makes noise instead of failing.
func _apply_overrides() -> void:
	_overridden.clear()
	for sfx_name in _sfx.keys() + FILE_ONLY_SFX:
		var path := "%s/%s.wav" % [OVERRIDE_DIR, sfx_name]
		if not ResourceLoader.exists(path):
			continue
		var stream = load(path)
		if stream is AudioStream:
			_sfx[sfx_name] = stream
			_overridden.append(sfx_name)
		else:
			push_error("AudioManager: %s is not an AudioStream" % path)
