class_name BattleAudio
extends Node
## Procedural blips. Safe under --headless (playback may be null).

const MIX_RATE := 22050.0

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _notes: Array = []
var _phase: float = 0.0
var _low_hp_timer: float = 0.0
var _low_hp_active: bool = false


class Note:
	extends RefCounted
	var freq: float
	var remaining: float
	var volume: float
	var noise: bool


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.1
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(true)


func _process(delta: float) -> void:
	if _low_hp_active:
		_low_hp_timer -= delta
		if _low_hp_timer <= 0.0:
			_low_hp_timer = 0.6
			_push(660.0, 0.08, 0.18)
	_fill()


func _push(freq: float, duration: float, volume: float = 0.22, noise: bool = false) -> void:
	var n := Note.new()
	n.freq = freq
	n.remaining = duration
	n.volume = volume
	n.noise = noise
	_notes.append(n)


func _fill() -> void:
	if _playback == null:
		_notes.clear()
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var step := 1.0 / MIX_RATE
	for _i in frames:
		var sample := 0.0
		if not _notes.is_empty():
			var n: Note = _notes[0]
			if n.noise:
				sample = randf_range(-1.0, 1.0) * n.volume
			else:
				_phase += n.freq * step
				sample = (1.0 if fmod(_phase, 1.0) < 0.5 else -1.0) * n.volume
			n.remaining -= step
			if n.remaining <= 0.0:
				_notes.pop_front()
				_phase = 0.0
		_playback.push_frame(Vector2(sample, sample))


func menu_move() -> void: _push(520.0, 0.035, 0.14)
func confirm() -> void:
	_push(700.0, 0.04, 0.18)
	_push(950.0, 0.05, 0.18)
func cancel() -> void: _push(400.0, 0.05, 0.16)
func denied() -> void: _push(200.0, 0.10, 0.18)
func hit() -> void:
	_push(150.0, 0.06, 0.28, true)
	_push(110.0, 0.05, 0.20, true)
func faint() -> void:
	for i in 6:
		_push(500.0 - float(i) * 60.0, 0.06, 0.20)
func taunt() -> void:
	_push(300.0, 0.05, 0.20)
	_push(240.0, 0.05, 0.20)
	_push(380.0, 0.09, 0.22)
func victory() -> void:
	for f in [523.0, 659.0, 784.0, 1046.0]:
		_push(f, 0.10, 0.20)
func start_low_hp() -> void:
	if _low_hp_active: return
	_low_hp_active = true
	_low_hp_timer = 0.0
func stop_low_hp() -> void:
	_low_hp_active = false
