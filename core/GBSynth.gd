class_name GBSynth
extends RefCounted
## Tiny Game Boy-flavoured tone generator.
## The DMG APU had two pulse channels with selectable duty, a programmable wave channel and an
## LFSR noise channel. These helpers cover pulse and noise, which is all the UI needs.
## Everything is synthesised at runtime, so the repo ships no audio binaries and every sound is
## original by construction (PRD §20: original assets only).

const RATE := 22050

## The four duty cycles the DMG pulse channels could select.
const DUTY_12_5 := 0.125
const DUTY_25 := 0.25
const DUTY_50 := 0.5
const DUTY_75 := 0.75

## One pulse tone with a decaying envelope.
static func square(freq: float, secs: float, duty: float = DUTY_50, peak: float = 0.35) -> AudioStreamWAV:
	var n := maxi(1, int(RATE * secs))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var phase := fposmod(float(i) * freq / float(RATE), 1.0)
		var amp := peak * _envelope(i, n)
		var v: float = amp if phase < duty else -amp
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

## Percussive hiss from a 15-bit LFSR, the same trick the DMG noise channel used.
static func noise(secs: float, divider: int = 8, peak: float = 0.25) -> AudioStreamWAV:
	var n := maxi(1, int(RATE * secs))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var lfsr := 0x7FFF
	var hold := 0
	var level := 1.0
	for i in n:
		hold -= 1
		if hold <= 0:
			hold = maxi(1, divider)
			var bit := (lfsr ^ (lfsr >> 1)) & 1
			lfsr = (lfsr >> 1) | (bit << 14)
			level = 1.0 if (lfsr & 1) == 0 else -1.0
		var v := level * peak * _envelope(i, n)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

## Tones back to back: the classic two-note handheld blip.
static func arp(freqs: Array[float], secs_each: float, duty: float = DUTY_50, peak: float = 0.35) -> AudioStreamWAV:
	var out := PackedByteArray()
	for f in freqs:
		out.append_array(square(f, secs_each, duty, peak).data)
	return _wav(out)

## Linear decay, rounded to the DMG's 16 envelope steps so it keeps its grit.
static func _envelope(i: int, n: int) -> float:
	var env := 1.0 - float(i) / float(n)
	return floorf(clampf(env, 0.0, 1.0) * 15.0) / 15.0

static func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s
