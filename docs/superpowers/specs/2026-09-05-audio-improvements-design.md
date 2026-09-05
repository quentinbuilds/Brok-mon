# Audio system — current state and what to build next

Written 2026-09-05, after the MVP-blocking work was deliberately deferred. Nothing here is
required for the MVP. It exists so the next person does not rebuild what is already there.

Owner of the *content* decisions (which sound plays when, music mood): **Person 6**, per PRD §10.
Owner of the *seam* (autoloads, EventBus, state machine): **Person 1**.

## What exists today

| Piece | File | What it does |
|---|---|---|
| `AudioManager` | `core/AudioManager.gd` | Autoload. `play_sfx(name)`, 8-voice pool, file overrides |
| `GBSynth` | `core/GBSynth.gd` | Square/noise/arp generators, DMG duty cycles, 16-step envelopes |
| Sound test | `audio/AudioTest.tscn` | `SOUND_TEST` state, reached MENU → A, or F6 standalone |
| Music | `core/AudioManager.gd` | `play_music()`/`stop_music()`, own players, intro-then-loop |
| Board audio bridge | `hardware/audio-bridge.sh` | Plays the UNO Q's audio through a Mac while testing |
| Battle audio | `battle/fx/BattleAudio.gd` | **A second, independent system.** See "Convergence" below |

Effects today: `confirm`, `cancel`, `menu`, `bump`, `sigh` (synth) plus `bruh`, `fahhh`, `giant`,
`hurt` (files).
Music today: `battle`, started on entering the sound test so that C then A from the overworld
is a one-gesture check that music reaches the speakers.

Two properties worth preserving:

- **No audio files are required.** The synth means a checkout with an empty `assets/audio/` still
  makes noise. Never make a sound mandatory that only exists as a file.
- **Files win over synth, by filename.** Dropping `assets/audio/confirm.wav` replaces the confirm
  blip with no code change. This is how Person 6 adds real sounds.

## Convergence with BattleAudio (decide before adding more sounds)

`battle/fx/BattleAudio.gd` is a live `AudioStreamGenerator`: it pushes computed frames every
frame and exposes `hit()`, `faint()`, `victory()`, `confirm()`, `cancel()`, `menu_move()`,
`denied()`, `taunt()`, `start_low_hp()`/`stop_low_hp()`. `TurnSequencer.impact()` already calls
`ui.audio.hit()`.

They are not redundant today, because each does something the other cannot:

- `BattleAudio` can hold a **continuous** tone and modulate it — that is how the low-HP heartbeat
  works. `AudioManager` plays fixed, pre-baked streams and cannot do that.
- `AudioManager` can play **sampled** audio (a recorded clip). `BattleAudio` is a pure oscillator
  and cannot play a file at all.

So the recommendation is **not** to delete either one, but to stop them growing into each other:

1. `AudioManager` owns every **one-shot** sound, sampled or synthesised, game-wide.
2. `BattleAudio` keeps only what needs a **live generator** — currently just the low-HP heartbeat.
3. Its one-shot methods (`hit`, `faint`, `victory`, `confirm`, `cancel`, `menu_move`, `denied`,
   `taunt`) become thin forwards to `AudioManager.play_sfx(...)`, so battle sounds gain file
   overrides for free and there is one place to change a sound.

Do step 3 with Person 4, not around them. It touches their subsystem, and the forwarding shims
mean no call site in `battle/` has to change.

## Improvement 1 — music seam — **built 2026-09-05**

`play_sfx()` cannot carry music: the pool round-robins, so a track started that way is cut off
once every other voice has been used. Music has its own players.

```gdscript
func has_music(track: String) -> bool
func play_music(track: String) -> bool      # intro once, then body on repeat
func stop_music(fade := 0.0) -> void
func current_music() -> String
func is_music_playing() -> bool
```

Two `AudioStreamPlayer`s on the autoload, `_music_intro` and `_music_loop`, deliberately outside
`_players` so no effect can ever steal them. Tracks resolve from `res://assets/music`, `.ogg`
first then `.mp3`.

**The intro/body convention.** Downloaded game music is usually mastered as an opening flourish
followed by a seamless body, and looping the whole file replays the flourish every cycle. So a
track may ship as two files: `<name>_intro.ogg` plays once, and when it ends `<name>.ogg` takes
over with `loop = true` forever. A track with no `_intro` file just loops from sample zero;
nothing else about the call changes.

Looping is set in code (`stream.loop`) rather than in the `.import` file, so dropping a track in
works with no import settings to remember.

### The `battle` track, and how its split point was found

`audio/old-pokemon-battle-music.mp3` (14.6365 s, gitignored like the other raw downloads) is an
opening plus **exactly two iterations** of the body. That was not a guess. Decoding it and
searching every (loop length, intro end) pair anchored to the file's end gives one clear winner:

| loop length | intro end | correlation |
|---|---|---|
| **5.225 s** | **4.187 s** | **0.574** |
| 3.897 s | 6.843 s | 0.195 |
| 6.531 s | 1.575 s | 0.177 |

The runner-up is three times worse, and `14.6365 − 2 × 5.2247 = 4.1872` lands on the boundary to
five decimal places — the file was mastered that way. The cut is therefore sample-exact:

- `assets/music/battle_intro.ogg` — samples `[0, 184654)`, 4.1872 s
- `assets/music/battle.ogg` — samples `[184654, 415062)`, 5.2247 s, one iteration

Taking **one** iteration rather than both is what makes the loop seamless: in the source, the
sample after the segment's last one is the segment's own first sample, so the wrap is already
continuous and needs no crossfade. (The source's second iteration diverges in its final ~1.2 s —
a variation — which is why the correlation is 0.574 and not higher, and why iteration one is the
one to keep.)

Re-encoded with `sox -C 4`: 72 KB + 92 KB, against ~2.5 MB had this been WAV.

**Measured, not assumed:** the intro→body handoff runs on `AudioStreamPlayer.finished`, which is
one frame late. Against CoreAudio that is **14 ms** — inaudible. Do not re-measure this headless:
the Dummy driver mixes in coarse chunks and reports **232 ms** for the same code, which is an
artifact of the driver and not something a player would ever hear.

## Improvement 2 — damage hook — **built 2026-09-05**

Built as specced. Three files, one line of which is Person 4's:

1. `core/EventBus.gd` — `signal damage_dealt(amount: int, to_player: bool)`
2. `battle/TurnSequencer.gd` — one line in `impact()`, next to the existing `ui.audio.hit()`:
   `EventBus.damage_dealt.emit(damage, view == ui.player_view)`
3. `core/AudioManager.gd` — connects it and plays `hurt`, **only** when `to_player` and
   `amount > 0`. That filter lives in audio, not in battle: `impact()` fires for both sides and
   on hits that did nothing, and other consumers (shake, rumble, HUD) will want those.

**`hurt` is a separate file from `fahhh`, not a replacement.** The spec's warning was right —
the full 2.324 s recording is mostly a decaying room tail (the scream is over by 0.65 s, the rest
sits at -25 dB), and at one hit per turn those tails pile up on each other. `assets/audio/hurt.wav`
is that recording cut to **0.85 s** with a 0.15 s fade, normalised to -1 dBFS: RMS -14.6 dB, which
is 3 dB above the music. `fahhh` keeps its full length for the sound test.

Tested at both levels: the side filter by emitting on `EventBus` directly, and then by driving a
real battle and asserting the reported amount equals the HP the player actually lost — because the
failure that matters is `view == ui.player_view` being backwards, and that reads as correct in
every synthetic test.

## Faint hook — **built 2026-09-05**

The damage hook again, one step further down the turn. `EventBus.creature_fainted(to_player)` is
emitted by `TurnSequencer.faint()` next to the existing `ui.audio.faint()`, and `AudioManager`
plays `bruh` on it — **only** when `to_player`. The wild creature dropping is the win, and it
already has BattleAudio's falling arpeggio over it; a "bruh" there mocks the wrong side.

`assets/audio/bruh.wav` is the source mp3 at 22.05 kHz mono, normalised to -1 dBFS, 0.864 s — it
finishes under the faint animation, before the "X fainted!" line is done typing.

## Improvement 3 — wire the remaining EventBus signals

All one-liners in `AudioManager._ready()` once the sounds exist. Left undone deliberately: the
mapping is a creative decision.

| Signal | Suggested |
|---|---|
| `battle_started` | encounter sting, then battle music |
| `battle_won` | victory jingle |
| `battle_lost` | defeat sting |
| `creature_caught` | catch jingle |
| `menu_opened` / `menu_closed` | `menu` blip |
| `player_moved` | `bump` footstep — needs a cooldown, this fires per tile |

`battle_started` / `battle_won` / `battle_lost` / `battle_escaped` / `creature_caught` are wired
(music), as is `damage_dealt`. The rest of this table is still open.

## Known limitations, recorded so they are not rediscovered

- **Headless cannot prove audibility.** Tests run on the Dummy driver. They assert stream format,
  length, non-silence and the override contract; whether sound reaches a speaker is only provable
  by a human, which is what `audio/AudioTest.tscn` is for.
- **The board has no speaker.** Output is headphone/line out (`Arduino-Imola-HPH-LOUT`). With
  nothing plugged in, a perfectly working game is silent — verify the jack before debugging code.
- **`FILE_ONLY_SFX` is an explicit list, not a directory scan.** An exported build remaps imported
  resources, so listing `res://assets/audio` at runtime does not reliably show them. Adding a
  file-only sound means adding its name to that constant.
- **The audio bridge accumulates lag.** The board-side capture file is an unbounded queue; once
  the Mac falls behind it never catches up. Restart the script rather than debugging it.
