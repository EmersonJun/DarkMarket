#!/usr/bin/env python3
"""Gera SFX placeholders (WAV PCM 16-bit, mono) sem dependencias externas.
Sons curtos e 'candy' para um idle game: coin, collect, levelup, click, unlock, error.
"""
import wave, struct, math, os

SR = 44100
OUT = os.path.dirname(os.path.abspath(__file__))


def write_wav(name, samples):
	path = os.path.join(OUT, name + ".wav")
	with wave.open(path, "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(SR)
		frames = bytearray()
		for s in samples:
			v = int(max(-1.0, min(1.0, s)) * 32767)
			frames += struct.pack("<h", v)
		w.writeframes(bytes(frames))
	print("wrote", path, len(samples), "samples")


def env(i, n, attack=0.01, release=0.25):
	t = i / SR
	dur = n / SR
	a = min(1.0, t / attack) if attack > 0 else 1.0
	rel_start = dur - release
	r = 1.0 if t < rel_start else max(0.0, 1.0 - (t - rel_start) / release)
	return a * r


def tone(freq, n, i):
	return math.sin(2.0 * math.pi * freq * i / SR)


def gen_blip(freqs, dur, attack=0.005, release=0.08, vib=0.0, detune=1.0):
	n = int(SR * dur)
	out = []
	for i in range(n):
		e = env(i, n, attack, release)
		v = 0.0
		for f in freqs:
			ff = f * (1.0 + vib * math.sin(2 * math.pi * 6 * i / SR))
			v += tone(ff, n, i)
			v += 0.4 * tone(ff * detune, n, i)
		out.append(0.22 * e * v)
	return out


def gen_sweep(f0, f1, dur, attack=0.005, release=0.06):
	n = int(SR * dur)
	out = []
	phase = 0.0
	for i in range(n):
		t = i / n
		f = f0 + (f1 - f0) * t
		phase += 2.0 * math.pi * f / SR
		e = env(i, n, attack, release)
		out.append(0.25 * e * (math.sin(phase) + 0.3 * math.sin(2 * phase)))
	return out


def gen_arp(notes, note_dur, attack=0.004, release=0.05):
	out = []
	for f in notes:
		out += gen_blip([f], note_dur, attack, release)
	return out


# Coin: dois tons agudos rapidos brilhantes (ka-ching!)
coin = gen_arp([1318.5, 1975.5], 0.085, attack=0.003, release=0.06)

# Collect: arpejo curto subindo, mais cheio
collect = gen_arp([783.99, 1046.5, 1318.5], 0.075, attack=0.003, release=0.07)

# Levelup: fanfarra subindo (maior triade + oitava)
levelup = gen_arp([523.25, 659.25, 783.99, 1046.5], 0.11, attack=0.004, release=0.12)

# Click: blip curtinho neutro
click = gen_blip([520.0], 0.04, attack=0.002, release=0.03)

# Unlock: sweep ascendente brilhante
unlock = gen_sweep(330.0, 1320.0, 0.32, attack=0.005, release=0.12)

# Error: dois tons graves descendentes (negado)
error = gen_arp([311.13, 233.08], 0.11, attack=0.004, release=0.09)

write_wav("coin", coin)
write_wav("collect", collect)
write_wav("levelup", levelup)
write_wav("click", click)
write_wav("unlock", unlock)
write_wav("error", error)
print("done")
