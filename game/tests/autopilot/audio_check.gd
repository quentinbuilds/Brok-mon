extends "res://tests/autopilot/probe_base.gd"
## Proves every background-music asset loads, loops, and actually produces audio.
##
## The verify instance forces the Dummy audio driver, but AudioServer still mixes,
## so bus peak volume is a real measurement here: silence reads -200 dB.

const AUDIO_DIR := "res://assets/audio/"

# filename -> expected length in seconds (asserted within a tolerance, not exactly)
const TRACKS := {
	"jungle_theme.ogg": 27.4,
	"beach_theme.ogg": 51.7,
	"title_theme.ogg": 94.0,
	"jungle_theme.mp3": 27.4,
	"beach_theme.mp3": 51.7,
	"title_theme.mp3": 94.0,
}

const SILENCE_DB := -100.0
const LENGTH_TOLERANCE := 1.5


func _ready() -> void:
	await super._ready()
	await settle(2)

	var player := AudioStreamPlayer.new()
	player.bus = &"Master"
	add_child(player)
	await settle(1)

	var failures: Array = []
	var peaks: Dictionary = {}
	var lengths: Dictionary = {}

	for filename in TRACKS:
		var path: String = AUDIO_DIR + filename

		if not ResourceLoader.exists(path):
			failures.append("%s: not found at %s" % [filename, path])
			continue

		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			failures.append("%s: did not load as an AudioStream" % filename)
			continue

		# Background music must loop, or it plays once and leaves the map silent.
		if not ("loop" in stream) or not stream.loop:
			failures.append("%s: loop is not enabled on the imported stream" % filename)

		var length: float = stream.get_length()
		lengths[filename] = snappedf(length, 0.1)
		var expected: float = TRACKS[filename]
		if absf(length - expected) > LENGTH_TOLERANCE:
			failures.append(
				"%s: length %.1fs, expected ~%.1fs" % [filename, length, expected])

		# Seek a quarter in so a quiet intro cannot be mistaken for a dead file.
		player.stream = stream
		player.play()
		player.seek(length * 0.25)

		var peak: float = -200.0
		for _i in 45:
			await get_tree().process_frame
			peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(0, 0))
			peak = maxf(peak, AudioServer.get_bus_peak_volume_right_db(0, 0))
		player.stop()
		await settle(1)

		peaks[filename] = snappedf(peak, 0.01)
		if peak <= SILENCE_DB:
			failures.append(
				"%s: produced no audio (peak %.1f dB)" % [filename, peak])

	report("lengths_seconds", lengths)
	report("peak_db", peaks)
	report("tracks_checked", TRACKS.size())

	if failures.is_empty():
		report("audio_ok", true)
	else:
		report("error", "; ".join(failures))

	finish()
