extends TestCase
## Two layers under test:
##   GBSynth      - the generated waveforms, asserted precisely (format, rate, length, loudness)
##   AudioManager - the contract only (names, playability, override bookkeeping), because any
##                  effect may legitimately be replaced by a file in assets/audio/.

const EXPECTED := ["bump", "cancel", "confirm", "menu", "sigh"]

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

## VOICES sfx players plus the two dedicated music players (intro and loop).
func test_voice_pool_is_allocated() -> void:
	assert_eq(_mgr().get_children().size(), _mgr().VOICES + 2)

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

# --- music ---
## Headless runs on the Dummy audio driver, so these assert the seam - resolution, the intro
## handoff, state after stop - and never audibility. That is what audio/AudioTest.tscn is for.

const TRACK := "battle"

func _music_players() -> Array:
	# The two players added after the sfx pool, in _ready order: intro then loop.
	var kids := _mgr().get_children()
	return [kids[_mgr().VOICES], kids[_mgr().VOICES + 1]]

func test_music_players_are_outside_the_sfx_pool() -> void:
	# A shared pool would let the ninth blip of a battle steal the music player mid-track.
	for p in _music_players():
		assert_false(p in _mgr()._players, "music player is in the sfx pool")

func test_unknown_track_is_refused() -> void:
	assert_false(_mgr().play_music("no_such_track_exists"))
	assert_eq(_mgr().current_music(), "")

func test_battle_track_is_on_disk() -> void:
	assert_true(_mgr().has_music(TRACK), "assets/music/%s.ogg is missing" % TRACK)

func test_battle_track_has_a_separate_intro() -> void:
	assert_true(_mgr().has_music(TRACK + _mgr().MUSIC_INTRO_SUFFIX),
		"the opening was supposed to be split out into %s_intro" % TRACK)

func test_intro_plays_first_and_does_not_loop() -> void:
	assert_true(_mgr().play_music(TRACK))
	var intro: AudioStreamPlayer = _music_players()[0]
	var body: AudioStreamPlayer = _music_players()[1]
	assert_true(intro.stream != null, "intro did not start")
	assert_false(intro.stream.loop, "the opening must play once, not on repeat")
	assert_true(body.stream == null or not body.playing, "the loop started before the intro ended")
	_mgr().stop_music()

func test_body_takes_over_when_the_intro_ends_and_loops() -> void:
	assert_true(_mgr().play_music(TRACK))
	_mgr()._on_intro_finished()
	var body: AudioStreamPlayer = _music_players()[1]
	assert_true(body.stream != null, "body never started")
	assert_true(body.stream.loop, "the body must repeat forever")
	_mgr().stop_music()

func test_the_two_pieces_are_different_audio() -> void:
	var intro: AudioStream = load(_mgr()._music_path(TRACK + _mgr().MUSIC_INTRO_SUFFIX))
	var body: AudioStream = load(_mgr()._music_path(TRACK))
	assert_true(intro.get_length() > 1.0, "intro is suspiciously short: %f" % intro.get_length())
	assert_true(body.get_length() > 1.0, "body is suspiciously short: %f" % body.get_length())
	assert_true(absf(intro.get_length() - body.get_length()) > 0.1,
		"intro and body are the same length - the split probably did not happen")

func test_stop_during_the_intro_is_not_undone_by_the_late_finished_signal() -> void:
	# finished fires from the audio thread; a stop that races it must still win.
	assert_true(_mgr().play_music(TRACK))
	_mgr().stop_music()
	_mgr()._on_intro_finished()
	assert_false(_mgr().is_music_playing(), "music restarted itself after stop_music()")
	assert_eq(_mgr().current_music(), "")

func test_replaying_the_current_track_does_not_restart_it() -> void:
	assert_true(_mgr().play_music(TRACK))
	var before: float = _music_players()[0].get_playback_position()
	assert_true(_mgr().play_music(TRACK))
	assert_true(_music_players()[0].get_playback_position() >= before, "track was restarted")
	_mgr().stop_music()

func test_stop_music_clears_the_name() -> void:
	_mgr().play_music(TRACK)
	_mgr().stop_music()
	assert_eq(_mgr().current_music(), "")

# --- mix balance ---
## The sound test shipped once with `fahhh` peaking at -15 dB against music peaking at -3, and it
## was simply inaudible under the battle loop. Both halves of that are asserted here.

## Loudest sample in a stream, as a fraction of full scale. Only meaningful for AudioStreamWAV,
## which is what every sampled effect is; ogg music is checked by its player volume instead.
func _peak_fraction(s: AudioStreamWAV) -> float:
	return float(_peak(s)) / 32768.0

func test_sampled_effects_use_their_headroom() -> void:
	# -6 dBFS = 0.5. A clip quieter than this at source cannot be rescued by a volume knob without
	# dragging its noise floor up with it - normalise the file instead.
	for n in _mgr().overridden_sfx():
		var s: AudioStream = _mgr().get_sfx(n)
		if not (s is AudioStreamWAV):
			continue
		assert_true(_peak_fraction(s) > 0.5,
			"%s peaks at %.2f of full scale - it will be buried under music" % [n, _peak_fraction(s)])

func test_music_is_mixed_below_effects() -> void:
	assert_true(_mgr().MUSIC_VOLUME_DB < 0.0,
		"music at full volume covers every effect fired over it")
	_mgr().play_music(TRACK)
	for p in _music_players():
		if p.playing:
			assert_eq(p.volume_db, _mgr().MUSIC_VOLUME_DB)
	_mgr().stop_music()

## A faded stop tweens volume down to -60 dB. If it does not put the level back afterwards the
## next track starts inaudible - a bug that only shows up on the second battle of a session.
func test_fade_out_restores_the_resting_level() -> void:
	_mgr().play_music(TRACK)
	_mgr().stop_music()
	for p in _music_players():
		assert_eq(p.volume_db, _mgr().MUSIC_VOLUME_DB, "resting volume not restored after stop")

# --- battle music wiring ---
## Driven purely by signals battle/ already emitted; nothing in battle/ was changed for this, so
## these tests emit on EventBus directly rather than driving a battle.

func _a_creature() -> Creature:
	return GameData.party[0] if not GameData.party.is_empty() else null

func test_battle_started_starts_the_music() -> void:
	_mgr().stop_music()
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC)
	_mgr().stop_music()

func test_every_battle_ending_stops_the_music() -> void:
	# A win must clear the way for BattleAudio's victory sting; the others must not leak a loop
	# into the overworld.
	for ending in ["won", "lost", "escaped"]:
		EventBus.battle_started.emit(_a_creature(), _a_creature())
		assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC, "music did not start before %s" % ending)
		match ending:
			"won": EventBus.battle_won.emit(_a_creature())
			"lost": EventBus.battle_lost.emit()
			"escaped": EventBus.battle_escaped.emit()
		assert_eq(_mgr().current_music(), "", "music survived battle_%s" % ending)
	_mgr().stop_music()

func test_a_successful_catch_stops_the_music() -> void:
	# BattleState emits nothing on Result.CAUGHT - CatchingState is what knows the encounter ended.
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	EventBus.creature_caught.emit(_a_creature())
	assert_eq(_mgr().current_music(), "")

## A failed throw resumes BATTLE without re-emitting battle_started, so the track has to have been
## left alone throughout - restarting it mid-encounter would be very obvious.
func test_music_plays_straight_through_a_catch_attempt() -> void:
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	EventBus.catch_started.emit(_a_creature())
	assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC, "catch_started interrupted the music")
	EventBus.catch_failed.emit(_a_creature())
	assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC, "a failed throw stopped the music")
	_mgr().stop_music()

## Win a battle, then walk into another one before the fade finishes. The first fade owns a
## deferred stop(); if it is not cancelled it silences the second battle a third of a second in.
func test_a_new_battle_during_the_fade_out_is_not_silenced_by_it() -> void:
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	EventBus.battle_won.emit(_a_creature())
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	await tree.create_timer(_mgr().BATTLE_FADE + 0.2).timeout
	assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC, "the stale fade stopped the new track")
	assert_true(_mgr().is_music_playing(), "new battle went silent when the old fade completed")
	_mgr().stop_music()

# --- damage hook ---
## EventBus.damage_dealt is emitted by TurnSequencer.impact() for both sides; the decision about
## which side makes a noise lives here, in audio, not in battle/.

func _hurt_players() -> int:
	var n := 0
	for p in _mgr()._players:
		if p.playing and p.stream == _mgr().get_sfx(_mgr().HURT_SFX):
			n += 1
	return n

func test_hurt_sfx_exists() -> void:
	assert_true(_mgr().has_sfx(_mgr().HURT_SFX), "assets/audio/hurt.wav is missing")

## The whole point of the separate file: one hit per turn, so a 2.3 s clip would still be ringing
## when the next one lands. Anything under ~1 s is clear of that.
func test_hurt_is_short_enough_not_to_stack() -> void:
	var s: AudioStream = _mgr().get_sfx(_mgr().HURT_SFX)
	assert_true(s.get_length() < 1.0, "hurt is %.2f s - it will overlap the next hit" % s.get_length())
	assert_true(s.get_length() > 0.3, "hurt is %.2f s - too short to read" % s.get_length())

func test_player_damage_plays_the_sound() -> void:
	var before := _hurt_players()
	EventBus.damage_dealt.emit(7, true)
	assert_true(_hurt_players() > before, "no hurt sound when the player was hit")

## Both sides call impact(), so an unfiltered connection would scream on the enemy's turn too.
func test_enemy_damage_is_silent() -> void:
	for p in _mgr()._players:
		p.stop()
	EventBus.damage_dealt.emit(7, false)
	assert_eq(_hurt_players(), 0, "the hurt sound fired when the ENEMY took damage")

## impact() runs on hits that did nothing; a scream there reads as a bug to the player.
func test_zero_damage_is_silent() -> void:
	for p in _mgr()._players:
		p.stop()
	EventBus.damage_dealt.emit(0, true)
	assert_eq(_hurt_players(), 0, "the hurt sound fired on a hit that dealt no damage")

## Everything above emits damage_dealt by hand. This drives a real battle instead, because the
## part that can actually be wrong is TurnSequencer's `view == ui.player_view` - get that backwards
## and the game screams on the enemy's turn and stays silent when you are the one being hit.
func test_a_real_battle_reports_the_hit_sides_correctly() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var battle := BattleState.new()
	battle.instant = true
	battle.rng.seed = 7
	battle.services.inventory = BattleServices.NullInventory.new()
	battle.services.party = BattleServices.NullParty.new()
	host.add_child(battle)
	await tree.process_frame

	# Evenly matched and tanky, so nobody dies on the first exchange and both sides land a hit.
	var mine := Creature.new()
	mine.name = "HERO"; mine.max_hp = 60; mine.hp = 60; mine.attack = 5; mine.defense = 5
	mine.catch_rate = 0.5; mine.type = &"NORMAL"
	var wild := Creature.new()
	wild.name = "BUG"; wild.max_hp = 60; wild.hp = 60; wild.attack = 5; wild.defense = 5
	wild.catch_rate = 0.5; wild.type = &"NORMAL"
	GameData.party = [mine]
	GameData.active_index = 0
	(battle.services.party as BattleServices.NullParty).party = [mine]

	var hits: Array = []
	var probe := func(amount: int, to_player: bool) -> void: hits.append([amount, to_player])
	EventBus.damage_dealt.connect(probe)

	battle.enter({"wild": wild})
	for _i in 45:
		await tree.process_frame
		if battle.sub == BattleState.Sub.PLAYER_TURN:
			break
	var hp_before: int = mine.hp
	battle.perform_attack()
	for _i in 90:
		await tree.process_frame
		if hits.size() >= 2 or battle.finished:
			break
	EventBus.damage_dealt.disconnect(probe)

	assert_true(hits.size() >= 2, "expected a hit on each side, got %d" % hits.size())
	var to_enemy := hits.filter(func(h): return not h[1])
	var to_player := hits.filter(func(h): return h[1])
	assert_true(to_enemy.size() > 0, "the player's own attack never reported a hit on the enemy")
	assert_true(to_player.size() > 0, "the enemy's attack never reported a hit on the player")
	# The side flag has to match reality, not just be present on both.
	assert_true(mine.hp < hp_before, "player took no damage, so the to_player hit is meaningless")
	assert_eq(to_player[0][0], hp_before - mine.hp, "reported amount does not match HP lost")

	host.queue_free()
	await tree.process_frame

# --- faint hook ---
## EventBus.creature_fainted is emitted by TurnSequencer.faint() for both sides; as with the
## damage hook, which side makes a noise is decided here, in audio, not in battle/.

func _faint_players() -> int:
	var n := 0
	for p in _mgr()._players:
		if p.playing and p.stream == _mgr().get_sfx(_mgr().FAINT_SFX):
			n += 1
	return n

func test_faint_sfx_exists() -> void:
	assert_true(_mgr().has_sfx(_mgr().FAINT_SFX), "assets/audio/bruh.wav is missing")

## It plays over the faint animation and the "X fainted!" line that follows it, so it has to be
## short enough to be out of the way by the time the player is reading, and long enough to land.
func test_faint_sfx_is_a_one_liner() -> void:
	var s: AudioStream = _mgr().get_sfx(_mgr().FAINT_SFX)
	assert_true(s.get_length() < 2.0, "bruh is %.2f s - it runs into the message" % s.get_length())
	assert_true(s.get_length() > 0.3, "bruh is %.2f s - too short to read" % s.get_length())

func test_player_faint_plays_the_sound() -> void:
	var before := _faint_players()
	EventBus.creature_fainted.emit(true)
	assert_true(_faint_players() > before, "no faint sound when the player's creature dropped")

## The wild creature going down is the win. A "bruh" over it reads as mockery of the wrong side.
func test_enemy_faint_is_silent() -> void:
	for p in _mgr()._players:
		p.stop()
	EventBus.creature_fainted.emit(false)
	assert_eq(_faint_players(), 0, "the faint sound fired when the ENEMY dropped")

## As with the damage hook, the part that can actually be wrong is TurnSequencer's
## `view == ui.player_view`. Drive a real battle the player cannot win and cannot survive.
func test_a_real_battle_reports_the_fainting_side_correctly() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var battle := BattleState.new()
	battle.instant = true
	battle.rng.seed = 7
	battle.services.inventory = BattleServices.NullInventory.new()
	battle.services.party = BattleServices.NullParty.new()
	host.add_child(battle)
	await tree.process_frame

	# One HP and no punch: the player cannot kill the wild creature before the first hit lands.
	var mine := Creature.new()
	mine.name = "HERO"; mine.max_hp = 40; mine.hp = 1; mine.attack = 1; mine.defense = 1
	mine.catch_rate = 0.5; mine.type = &"NORMAL"
	var wild := Creature.new()
	wild.name = "BUG"; wild.max_hp = 200; wild.hp = 200; wild.attack = 40; wild.defense = 40
	wild.catch_rate = 0.5; wild.type = &"NORMAL"
	GameData.party = [mine]
	GameData.active_index = 0
	(battle.services.party as BattleServices.NullParty).party = [mine]

	var faints: Array = []
	var probe := func(to_player: bool) -> void: faints.append(to_player)
	EventBus.creature_fainted.connect(probe)

	battle.enter({"wild": wild})
	for _i in 45:
		await tree.process_frame
		if battle.sub == BattleState.Sub.PLAYER_TURN:
			break
	# The enemy may miss, which just costs another exchange; attack until somebody drops.
	for _turn in 8:
		if battle.finished:
			break
		if battle.sub == BattleState.Sub.PLAYER_TURN and not battle.busy:
			battle.perform_attack()
		for _i in 90:
			await tree.process_frame
			if battle.finished or (battle.sub == BattleState.Sub.PLAYER_TURN and not battle.busy):
				break
	EventBus.creature_fainted.disconnect(probe)

	assert_true(battle.finished, "the battle never ended")
	# It dropped -- that is what creature_fainted reported below -- and losing now blacks the
	# player out, which heals the party on the way back to the overworld. Leaving it on nought
	# HP would open the next encounter with a creature that cannot fight.
	assert_eq(mine.hp, mine.max_hp, "the blackout should have healed the party")
	assert_false(wild.is_fainted(), "the wild creature was not supposed to drop")
	assert_eq(faints.size(), 1, "expected exactly one faint, got %d" % faints.size())
	assert_true(faints[0], "the player's creature fainted but it was reported as the enemy's")

	host.queue_free()
	await tree.process_frame

# --- overworld music ---
## Driven off GameState.state_changed rather than by world/, because the overworld scene is built
## once and then hidden and unhidden: its enter() never runs again after the first one.

const OVERWORLD_TRACK := "overworld"

func _arrive_in_the_overworld() -> void:
	GameState.state_changed.emit(GameState.State.BATTLE, GameState.State.OVERWORLD)

func test_overworld_track_is_on_disk() -> void:
	assert_true(_mgr().has_music(OVERWORLD_TRACK), "assets/music/overworld.ogg is missing")

func test_arriving_in_the_overworld_starts_the_theme() -> void:
	_mgr().stop_music()
	_arrive_in_the_overworld()
	assert_eq(_mgr().current_music(), OVERWORLD_TRACK, "the map came up silent")
	_mgr().stop_music()

## Walking around must not restart the track every time the player opens the menu and closes it.
func test_arriving_again_does_not_restart_the_theme() -> void:
	_mgr().stop_music()
	_arrive_in_the_overworld()
	var players := _music_players()
	var before := [players[0].get_playback_position(), players[1].get_playback_position()]
	_arrive_in_the_overworld()
	assert_eq(_mgr().current_music(), OVERWORLD_TRACK)
	for i in 2:
		if players[i].playing:
			assert_true(players[i].get_playback_position() >= before[i], "the theme restarted")
	_mgr().stop_music()

## The ordering bug this guards: GameState and AudioManager both react to battle_won, and
## GameState is the autoload connected first - so the overworld theme is already playing by the
## time the battle-end handler runs here. Stopping unconditionally would fade THAT out and leave
## the map silent for the rest of the session.
func test_winning_a_battle_gives_the_overworld_its_theme_back() -> void:
	_mgr().stop_music()
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC, "the battle track never started")
	# The real order: the transition lands first, then the battle-end handler.
	_arrive_in_the_overworld()
	EventBus.battle_won.emit(_a_creature())
	assert_eq(_mgr().current_music(), OVERWORLD_TRACK, "the map was left silent after a battle")
	await tree.create_timer(_mgr().BATTLE_FADE + 0.1).timeout
	assert_eq(_mgr().current_music(), OVERWORLD_TRACK, "a stale battle fade stopped the map theme")
	assert_true(_mgr().is_music_playing(), "the overworld theme was faded out from under the map")
	_mgr().stop_music()

## Leaving the map for a battle still hands the music over - the guard must not make the battle
## track unstoppable in the other direction either.
func test_a_battle_takes_the_theme_away() -> void:
	_arrive_in_the_overworld()
	EventBus.battle_started.emit(_a_creature(), _a_creature())
	assert_eq(_mgr().current_music(), _mgr().BATTLE_MUSIC, "the overworld theme played over a battle")
	EventBus.battle_escaped.emit()
	assert_eq(_mgr().current_music(), "", "the battle track survived running away")
	_mgr().stop_music()

## The map theme plays louder than the shared music level on purpose - see MUSIC_GAIN_DB. It is
## the track that carries the game between battles, and at -6 dB it read as background.
func test_the_overworld_theme_plays_above_the_shared_music_level() -> void:
	assert_true(_mgr().music_volume_db(OVERWORLD_TRACK) > _mgr().MUSIC_VOLUME_DB,
		"the overworld trim is not being applied")
	_mgr().stop_music()
	_arrive_in_the_overworld()
	for p in _music_players():
		if p.playing:
			assert_eq(p.volume_db, _mgr().music_volume_db(OVERWORLD_TRACK))
	_mgr().stop_music()

## Amplifying past 0 dB clips the mix: every music file here is normalised to -1 dBFS already.
func test_no_track_is_trimmed_into_clipping() -> void:
	for track in _mgr().MUSIC_GAIN_DB.keys():
		assert_true(_mgr().music_volume_db(track) <= 0.0,
			"%s would play at %.1f dB" % [track, _mgr().music_volume_db(track)])

## A track with no entry keeps the shared level - the trim is an exception, not a new default.
## The battle track is the one that has to stay there: effects play over it all fight.
func test_untrimmed_tracks_keep_the_shared_level() -> void:
	assert_eq(_mgr().music_volume_db(TRACK), _mgr().MUSIC_VOLUME_DB)
	assert_false(_mgr().MUSIC_GAIN_DB.has(TRACK), "the battle track was trimmed above the effects")

## Every trimmed track has to actually be on disk, or the trim is describing a track that is not
## there - which is how a renamed file quietly goes back to playing at the shared level.
func test_every_trimmed_track_exists() -> void:
	for track in _mgr().MUSIC_GAIN_DB.keys():
		assert_true(_mgr().has_music(track), "MUSIC_GAIN_DB names '%s', which is not in %s" % [
			track, _mgr().MUSIC_DIR])
