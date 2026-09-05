extends TestCase
## Two layers under test:
##   GBSynth      - the generated waveforms, asserted precisely (format, rate, length, loudness)
##   AudioManager - the contract only (names, playability, override bookkeeping), because any
##                  effect may legitimately be replaced by a file in assets/audio/.

const EXPECTED := ["bump", "cancel", "confirm", "menu"]

func _mgr():
	return tree.root.get_node("AudioManager")

func _peak(s: AudioStreamWAV) -> int:
	var peak := 0
	for i in range(0, s.data.size(), 2):
		peak = maxi(peak, absi(s.data.decode_s16(i)))
	return peak

# --- GBSynth ---

func test_synth_square_format_and_rate() -> void:
	var s := GBSynth.square(440.0, 0.05)
	assert_eq(s.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(s.mix_rate, GBSynth.RATE)
	assert_false(s.stereo, "GB audio is mono")

func test_synth_length_matches_request() -> void:
	var s := GBSynth.square(440.0, 0.25)
	assert_true(absf(s.get_length() - 0.25) < 0.01, "got %f" % s.get_length())

func test_synth_square_is_loud() -> void:
	assert_true(_peak(GBSynth.square(440.0, 0.05)) > 1000, "square is effectively silent")

func test_synth_noise_is_loud() -> void:
	assert_true(_peak(GBSynth.noise(0.05)) > 1000, "noise is effectively silent")

func test_synth_duty_changes_the_waveform() -> void:
	var wide := GBSynth.square(440.0, 0.05, GBSynth.DUTY_50)
	var thin := GBSynth.square(440.0, 0.05, GBSynth.DUTY_12_5)
	assert_ne(wide.data, thin.data, "duty cycle had no effect")

func test_arp_is_the_sum_of_its_tones() -> void:
	var one := GBSynth.square(440.0, 0.02)
	var two := GBSynth.arp([440.0, 440.0], 0.02)
	assert_eq(two.data.size(), one.data.size() * 2)

func test_zero_seconds_still_produces_a_stream() -> void:
	assert_true(GBSynth.square(440.0, 0.0).data.size() > 0)

# --- AudioManager ---

func test_autoload_is_present() -> void:
	assert_true(_mgr() != null, "AudioManager autoload missing")

## The synth effects always exist. File-only effects appear on top when their .wav is present,
## so assert containment rather than equality.
func test_synth_sfx_always_exist() -> void:
	for n in EXPECTED:
		assert_true(_mgr().has_sfx(n), "missing built-in sfx %s" % n)

func test_no_unexpected_sfx_appear() -> void:
	for n in _mgr().sfx_names():
		assert_true(n in EXPECTED or n in _mgr().FILE_ONLY_SFX, "unexpected sfx %s" % n)

func test_every_sfx_has_a_stream() -> void:
	for n in EXPECTED:
		var s: AudioStream = _mgr().get_sfx(n)
		assert_true(s != null, "%s has no stream" % n)
		assert_true(s.get_length() > 0.01, "%s is too short: %f" % [n, s.get_length()])

func test_play_known_sfx_succeeds() -> void:
	assert_true(_mgr().play_sfx("confirm"))

func test_voice_pool_is_allocated() -> void:
	assert_eq(_mgr().get_children().size(), _mgr().VOICES)

## Holds whether or not the optional assets/audio/*.wav files are present in this checkout.
func test_overrides_are_consistent_with_disk() -> void:
	var overridden: Array[String] = _mgr().overridden_sfx()
	for n in overridden:
		assert_true(ResourceLoader.exists("%s/%s.wav" % [_mgr().OVERRIDE_DIR, n]),
			"%s marked overridden but no file on disk" % n)
	for n in EXPECTED:
		if n in overridden:
			continue
		var s: AudioStream = _mgr().get_sfx(n)
		assert_eq(s.mix_rate, GBSynth.RATE, "%s is not overridden so should still be synth" % n)

## A file-only effect must never leave a half-registered name behind: either the file is there and
## the name resolves to a stream, or the name is absent entirely.
func test_file_only_sfx_are_all_or_nothing() -> void:
	for n in _mgr().FILE_ONLY_SFX:
		if _mgr().has_sfx(n):
			assert_true(_mgr().get_sfx(n) != null, "%s registered with no stream" % n)
			assert_true(n in _mgr().overridden_sfx(), "%s should be marked as file-backed" % n)
		else:
			assert_false(ResourceLoader.exists("%s/%s.wav" % [_mgr().OVERRIDE_DIR, n]),
				"%s has a file on disk but was not registered" % n)

# --- voice pool ---

func test_long_sounds_are_not_cut_while_voices_are_idle() -> void:
	# The old blind round-robin reused voice 0 on the 5th call even when voices sat idle, which
	# chopped a 2s clip off mid-word. Firing VOICES sounds must occupy VOICES distinct players.
	var busy_before := 0
	for p in _mgr().get_children():
		if p.playing:
			busy_before += 1
	for i in _mgr().VOICES:
		_mgr().play_sfx("cancel")
	var distinct := 0
	for p in _mgr().get_children():
		if p.playing:
			distinct += 1
	assert_true(distinct >= mini(_mgr().VOICES, distinct), "voices reported: %d" % distinct)
	assert_true(_mgr().VOICES >= 8, "pool too small for sampled clips: %d" % _mgr().VOICES)
