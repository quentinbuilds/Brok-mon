extends Node
## Sound effects (PRD §10). Gameplay calls AudioManager.play_sfx("confirm"), never AudioStreamPlayer.
## Sounds are synthesised at startup by GBSynth, so the repo needs no audio files at all;
## a .wav in assets/audio/ named after an effect overrides that effect if one is present.
##
## Music is separate from effects: AudioManager.play_music("battle") streams from res://assets/music
## on its own player, so it is never cut short by the round-robin sfx pool.
##
## Battle music is wired to EventBus here, in this file only - battle/ emits the signals it
## already emitted and does not know music exists. Effect-to-signal mapping (menu blips, catch
## jingles) is still a creative call and still belongs to Person 6.

## Overlapping effects share this many players. The DMG's four channels are a nice homage but a
## bad cap once sampled clips are in play: a 2s clip would be cut off by the fourth blip after it.
const VOICES := 8

## Drop "<name>.wav" in here and it replaces the synth effect of that name, no code change.
const OVERRIDE_DIR := "res://assets/audio"

## Effects that exist only as files - no synth fallback. Listed explicitly rather than discovered
## by scanning OVERRIDE_DIR, because an exported build remaps imported resources and a directory
## listing of res:// does not reliably show them.
const FILE_ONLY_SFX := ["fahhh", "giant", "hurt"]

## Music lives here as .ogg, not .wav: AudioStreamOggVorbis streams and compresses, and a
## multi-minute track as raw WAV would bloat the .pck on a board with little to spare.
const MUSIC_DIR := "res://assets/music"

## Music sits under effects, not level with them. Both were mastered near 0 dB, so at equal gain
## a 5-second loop simply covers every blip fired over it - the sound test made that obvious.
## -6 dB is the usual game mix: the track still reads as loud, effects still cut through it.
## Effects have no matching boost on purpose; raising them above 0 dB would clip.
const MUSIC_VOLUME_DB := -6.0

## Track started on battle_started. A name, not a path, so swapping the encounter theme is a
## matter of dropping a different assets/music/battle.ogg in.
const BATTLE_MUSIC := "battle"

## Long enough not to sound like a cut, short enough that the victory sting is not sung over.
const BATTLE_FADE := 0.35

## Played when the player's creature takes a hit. A trimmed cut of the same recording as "fahhh":
## the full 2.3 s clip is mostly a decaying room tail, and at one hit per turn those tails pile up
## on each other and smother the fight. "hurt" is the 0.85 s that actually carries the joke.
const HURT_SFX := "hurt"

## A track may ship as two files: "<name>_intro.ogg" plays once, then "<name>.ogg" loops forever.
## Downloaded game music is usually mastered exactly this way - an opening flourish followed by a
## seamless body - and looping the whole thing would replay the flourish every time round.
## A track with no _intro file simply loops from the first sample; nothing else changes.
const MUSIC_INTRO_SUFFIX := "_intro"

var _sfx: Dictionary = {}
var _overridden: Array[String] = []
var _players: Array[AudioStreamPlayer] = []
var _next := 0

## Deliberately not part of _players. Music outlives every state scene and must never be stolen
## by an effect, which is exactly what sharing the pool would do.
var _music_intro: AudioStreamPlayer
var _music_loop: AudioStreamPlayer
var _music_name := ""
var _fade: Tween

func _ready() -> void:
	_build_library()
	for _i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_intro = AudioStreamPlayer.new()
	_music_loop = AudioStreamPlayer.new()
	add_child(_music_intro)
	add_child(_music_loop)
	_music_intro.finished.connect(_on_intro_finished)
	_connect_music_to_battle()
	# Only the player getting hit is worth a sound. Firing on the enemy's turn too would mean two
	# screams per exchange, which stops being funny by the second battle.
	EventBus.damage_dealt.connect(func(amount: int, to_player: bool) -> void:
		if to_player and amount > 0 and has_sfx(HURT_SFX):
			play_sfx(HURT_SFX))

## Battle music, driven entirely by signals battle/ already emits. Nothing in battle/ changed to
## make this work and nothing there needs to know about it.
##
## battle_started fires only on a fresh encounter, not when BattleState resumes after a failed
## catch throw - so the track deliberately plays straight through a catch attempt, the way it
## does in the games, instead of restarting when the wild creature breaks free.
##
## Every ending stops the music rather than letting it run under the next screen. On a win that
## also clears the way for BattleAudio's victory sting, which until now was competing with a
## full-volume loop.
func _connect_music_to_battle() -> void:
	EventBus.battle_started.connect(func(_p, _w): play_music(BATTLE_MUSIC))
	EventBus.battle_won.connect(func(_w): stop_music(BATTLE_FADE))
	EventBus.battle_lost.connect(func(): stop_music(BATTLE_FADE))
	EventBus.battle_escaped.connect(func(): stop_music(BATTLE_FADE))
	# Catching is a detour out of BATTLE that may or may not come back; only a successful catch
	# ends the encounter, and CatchingState is what knows that.
	EventBus.creature_caught.connect(func(_w): stop_music(BATTLE_FADE))

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

## --- music ---
## Music is one continuous track, not an effect: it must survive state transitions, never be
## cut off by an unrelated blip, and loop for as long as the state lasts.

## True when a track of this name is on disk and could be played.
func has_music(track: String) -> bool:
	return _music_path(track) != ""

## Name of the track currently playing, or "" when music is stopped.
func current_music() -> String:
	return _music_name

func is_music_playing() -> bool:
	return _music_intro.playing or _music_loop.playing

## Starts a track: its intro once if it has one, then its body on repeat until stop_music().
## Returns false when nothing of that name is on disk - a missing track should be visible, not
## a silent shrug. Restarting the track that is already playing is a no-op so that a state which
## re-enters does not stutter its own music.
func play_music(track: String) -> bool:
	if track == _music_name and is_music_playing():
		return true
	var body := _music_path(track)
	if body == "":
		push_error("AudioManager: no music named '%s' in %s" % [track, MUSIC_DIR])
		return false
	stop_music()
	_music_name = track
	var intro := _music_path(track + MUSIC_INTRO_SUFFIX)
	if intro != "":
		_start(_music_intro, intro, false)
	else:
		_start(_music_loop, body, true)
	return true

## Stops whatever is playing. A fade is worth the extra lines: cutting a track dead mid-note on a
## state change is the most obvious way for game audio to sound broken.
func stop_music(fade := 0.0) -> void:
	_music_name = ""
	_kill_fade()
	var playing: Array[AudioStreamPlayer] = []
	for p in [_music_intro, _music_loop]:
		if p.playing:
			playing.append(p)
		else:
			p.volume_db = MUSIC_VOLUME_DB
	if playing.is_empty():
		return
	if fade <= 0.0:
		for p in playing:
			p.stop()
			p.volume_db = MUSIC_VOLUME_DB
		return
	_fade = create_tween().set_parallel(true)
	for p in playing:
		_fade.tween_property(p, "volume_db", -60.0, fade)
	# Restore the resting level along with the stop, or the next play_music() starts silent.
	_fade.chain().tween_callback(func() -> void:
		for p in playing:
			p.stop()
			p.volume_db = MUSIC_VOLUME_DB)

## A fade in flight owns a deferred stop(). Left running it would silence a track started during
## the fade - which is exactly what winning a battle and walking straight into another one does.
func _kill_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = null

## The intro is one-shot; the body takes over the moment it ends. Guarded on _music_name so a
## stop_music() during the intro cannot be undone by a late finished signal.
func _on_intro_finished() -> void:
	if _music_name == "":
		return
	_start(_music_loop, _music_path(_music_name), true)

func _start(player: AudioStreamPlayer, path: String, looping: bool) -> void:
	var stream: AudioStream = load(path)
	# Looping is set here rather than in the .import file so that dropping a track in works with
	# no import settings to remember, and so the intent is readable from the code.
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = looping
	player.stream = stream
	player.volume_db = MUSIC_VOLUME_DB
	player.play()

## Resolves a track name to a file. .ogg first, per MUSIC_DIR's convention; .mp3 is accepted so a
## downloaded track works before anyone gets round to converting it.
func _music_path(track: String) -> String:
	for ext in ["ogg", "mp3"]:
		var path := "%s/%s.%s" % [MUSIC_DIR, track, ext]
		if ResourceLoader.exists(path):
			return path
	return ""

func _build_library() -> void:
	# Rising two-note blip: the "yes".
	_sfx["confirm"] = GBSynth.arp([880.0, 1318.0], 0.035, GBSynth.DUTY_50)
	# Low, thinner buzz: the "no".
	_sfx["cancel"] = GBSynth.square(196.0, 0.09, GBSynth.DUTY_25)
	# Quiet click for opening and closing panels.
	_sfx["menu"] = GBSynth.arp([587.0, 880.0], 0.028, GBSynth.DUTY_12_5, 0.25)
	# Noise-channel tick, for footsteps and bumps.
	_sfx["bump"] = GBSynth.noise(0.05, 12, 0.2)
	# Two notes falling instead of rising: the "confirm" blip played backwards, near enough.
	# Used when leaving the title, under "ah shit, here we go again".
	_sfx["sigh"] = GBSynth.arp([740.0, 466.0], 0.11, GBSynth.DUTY_25, 0.5)
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
