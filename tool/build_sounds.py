#!/usr/bin/env python3
"""Synthesizes the game's sound effects into assets/sounds/*.wav.

Everything is generated from math (no samples), so there is nothing to
license. Tweak a recipe below and re-run:

    python3 tool/build_sounds.py
"""
import math
import pathlib
import random
import struct
import wave

RATE = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / 'assets' / 'sounds'
random.seed(7)


# ---- building blocks --------------------------------------------------------

def silence(seconds):
    return [0.0] * int(RATE * seconds)


def tone(freq, seconds, *, wave_shape='sine', attack=0.004, decay=None,
         freq_end=None, harmonics=None, vibrato=0.0):
    """One note. `decay` is an exponential decay time constant in seconds."""
    n = int(RATE * seconds)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq if freq_end is None else freq + (freq_end - freq) * (i / n)
        if vibrato:
            f *= 1 + vibrato * math.sin(2 * math.pi * 6 * t)
        phase += 2 * math.pi * f / RATE
        if wave_shape == 'sine':
            s = math.sin(phase)
        elif wave_shape == 'triangle':
            s = 2 / math.pi * math.asin(math.sin(phase))
        elif wave_shape == 'square':
            # Soft square: first few odd harmonics (less harsh than a true square).
            s = sum(math.sin(k * phase) / k for k in (1, 3, 5, 7)) * 0.9
        else:
            raise ValueError(wave_shape)
        if harmonics:
            s += sum(a * math.sin(m * phase) for m, a in harmonics)
        env = min(1.0, t / attack) if attack else 1.0
        if decay:
            env *= math.exp(-t / decay)
        # Short fade-out so notes never click at the end.
        tail = min(1.0, (n - i) / (RATE * 0.004))
        out.append(s * env * tail)
    return out


def noise(seconds, *, decay=None, lowpass=0.2, sweep_to=None):
    """Filtered noise; `lowpass` 0-1 (higher = brighter), optionally sweeping."""
    n = int(RATE * seconds)
    out, y = [], 0.0
    for i in range(n):
        t = i / RATE
        a = lowpass if sweep_to is None else lowpass + (sweep_to - lowpass) * (i / n)
        y += a * (random.uniform(-1, 1) - y)
        env = math.exp(-t / decay) if decay else math.sin(math.pi * i / n)
        out.append(y * env)
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * RATE) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * length
    for t, o in zip(tracks, offsets):
        start = int(o * RATE)
        for i, s in enumerate(t):
            out[start + i] += s
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def gain(track, g):
    return [s * g for s in track]


def write(name, track, peak=0.8):
    m = max(abs(s) for s in track) or 1.0
    scale = peak / m
    path = OUT / f'{name}.wav'
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, s * scale)) * 32767))
            for s in track))
    print(f'{path.name:14s} {len(track) / RATE:.2f}s  {path.stat().st_size // 1024} KB')


NOTE = {n: 440 * 2 ** ((i - 9) / 12) for i, n in enumerate(
    ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'])}


def note(name, octave):
    return NOTE[name] * 2 ** (octave - 4)


# ---- recipes ----------------------------------------------------------------

def main():
    OUT.mkdir(parents=True, exist_ok=True)

    # Button press: a soft, round "pop".
    write('tap', mix(
        tone(520, 0.07, freq_end=360, decay=0.018, harmonics=[(2, 0.25)]),
        gain(noise(0.012, decay=0.004, lowpass=0.6), 0.35),
    ), peak=0.55)

    # Small UI click (tabs, chips).
    write('click', tone(1150, 0.035, freq_end=900, decay=0.008), peak=0.4)

    # Coin: the classic two-step chime.
    write('coin', seq(
        tone(note('B', 5), 0.06, wave_shape='square', decay=0.08),
        tone(note('E', 6), 0.28, wave_shape='square', decay=0.09),
    ), peak=0.45)

    # Level up: quick rising arpeggio with a sparkly top.
    arp = [note('C', 5), note('E', 5), note('G', 5), note('C', 6)]
    write('levelup', mix(
        *[tone(f, 0.11 if i < 3 else 0.45, wave_shape='triangle',
               decay=0.06 if i < 3 else 0.2, harmonics=[(2, 0.2)])
          for i, f in enumerate(arp)],
        gain(tone(note('E', 7), 0.3, decay=0.08), 0.25),
        offsets=[0.0, 0.07, 0.14, 0.21, 0.24],
    ), peak=0.6)

    # Fanfare: big celebration (new skill, new office, goal claimed).
    melody = [(note('G', 4), 0.0), (note('C', 5), 0.1), (note('E', 5), 0.2),
              (note('G', 5), 0.3)]
    chord = [note('C', 5), note('E', 5), note('G', 5), note('C', 6)]
    write('fanfare', mix(
        *[tone(f, 0.16, wave_shape='square', decay=0.12) for f, _ in melody],
        *[gain(tone(f, 0.9, wave_shape='triangle', decay=0.45, vibrato=0.004), 0.6)
          for f in chord],
        *[gain(tone(note('C', 7) * (1 + 0.12 * k), 0.15, decay=0.05), 0.2)
          for k in range(4)],
        offsets=[o for _, o in melody] + [0.42] * 4 + [0.45, 0.52, 0.6, 0.68],
    ), peak=0.6)

    # Error: two low "nope" notes.
    write('error', seq(
        tone(330, 0.09, wave_shape='square', decay=0.08),
        silence(0.02),
        tone(247, 0.16, wave_shape='square', decay=0.1),
    ), peak=0.35)

    # Notification ding (job finished, achievement reached).
    write('ding', mix(
        tone(note('G', 6), 0.6, decay=0.18, harmonics=[(2.76, 0.3), (5.4, 0.1)]),
        gain(tone(note('C', 7), 0.5, decay=0.15), 0.5),
        offsets=[0.0, 0.06],
    ), peak=0.45)

    # Whoosh: accepting a job, opening a city.
    write('whoosh', noise(0.28, lowpass=0.05, sweep_to=0.5), peak=0.4)


if __name__ == '__main__':
    main()
