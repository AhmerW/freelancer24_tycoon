#!/usr/bin/env python3
"""Builds assets/data/skills.json from tool/skills_source.json.

Content (names, descriptions, icons, tracks) lives in skills_source.json.
Economy numbers (price, rate, rank) are derived here so every skill sits on
one consistent curve. Re-run after editing either file:

    python3 tool/build_skills.py
"""
import json
import math
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'tool' / 'skills_source.json'
OUT = ROOT / 'assets' / 'data' / 'skills.json'

# When each track opens (number of skills learned in total) and where its
# first skill sits on the economy curve.
TRACKS = {
    'web':       {'unlockAtSkills': 0,  'rankStart': 0.0},
    'writing':   {'unlockAtSkills': 2,  'rankStart': 1.0},
    'marketing': {'unlockAtSkills': 4,  'rankStart': 2.0},
    'design':    {'unlockAtSkills': 7,  'rankStart': 3.5},
    'media':     {'unlockAtSkills': 10, 'rankStart': 5.0},
    'software':  {'unlockAtSkills': 14, 'rankStart': 6.5},
}
RANK_PER_STEP = 2.4
PRICE_BASE = 10
PRICE_GROWTH = 3.0
UNLOCK_ON_PREVIOUS_LEVEL = 5

# Ids of the original 2024 skills, kept so existing saves stay valid.
LEGACY_IDS = {
    'html': 0, 'css_websites': 1, 'content_writing': 2, 'javascript': 3,
    'python': 4, 'software_principles': 5, 'java': 6, 'cplusplus': 7,
    'machine_learning': 8, 'copywriting': 9, 'seo': 10,
    'email_marketing': 11, 'social_media': 12, 'digital_strategy': 13,
    'photo_editing': 14, 'video_editing': 15, 'rendering_3d': 16,
    'product_design': 17, 'fullstack_cloud': 18,
}


def nice(x):
    """Round to 2 significant digits so prices look intentional."""
    if x < 100:
        return round(x)
    digits = int(math.floor(math.log10(x))) - 1
    return int(round(x / 10 ** digits) * 10 ** digits)


def main():
    src = json.loads(SOURCE.read_text())
    tracks = []
    for t in src['tracks']:
        extra = TRACKS[t['id']]
        tracks.append({**t, 'unlockAtSkills': extra['unlockAtSkills']})

    next_id = max(LEGACY_IDS.values()) + 1
    skills = []
    for s in sorted(src['skills'], key=lambda s: (list(TRACKS).index(s['track']), s['step'])):
        rank = TRACKS[s['track']]['rankStart'] + (s['step'] - 1) * RANK_PER_STEP
        if s['key'] in LEGACY_IDS:
            sid = LEGACY_IDS[s['key']]
        else:
            sid = next_id
            next_id += 1
        skills.append({
            'id': sid,
            'key': s['key'],
            'track': s['track'],
            'step': s['step'],
            'tier': s['step'],
            'rank': round(rank, 2),
            'name': s['name'],
            'description': s['description'],
            'icon': s['icon'],
            'price': nice(PRICE_BASE * PRICE_GROWTH ** rank),
            'rate': round(1.1 + rank * 0.18, 2),
            'levelPriceRate': round(1.3 + rank * 0.17, 2),
            'unlockOnPreviousLevel': 0 if s['step'] == 1 else UNLOCK_ON_PREVIOUS_LEVEL,
        })

    OUT.write_text(json.dumps({'tracks': tracks, 'skills': skills}, indent=2, ensure_ascii=False) + '\n')
    print(f'Wrote {len(skills)} skills in {len(tracks)} tracks to {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
