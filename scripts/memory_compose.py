#!/usr/bin/env python3
import argparse
import json
from collections import defaultdict
from pathlib import Path

CTX = Path('/tmp/openclaw/memory-context-latest.json')

LIMITS = {
    'fact': 2,
    'preference': 1,
    'decision': 1,
    'task_state': 1,
}


def main():
    ap = argparse.ArgumentParser(description='Compose concise memory cues for response generation')
    ap.add_argument('--max-total', type=int, default=4)
    ap.add_argument('--out', default='/tmp/openclaw/memory-compose-latest.json')
    args = ap.parse_args()

    if not CTX.exists():
        print(json.dumps({'ok': False, 'reason': 'context_missing'}))
        return

    d = json.loads(CTX.read_text(encoding='utf-8'))
    items = ((d.get('recall') or {}).get('items') or [])

    picked = []
    type_count = defaultdict(int)

    for it in items:
        t = it.get('type', 'fact')
        if type_count[t] >= LIMITS.get(t, 1):
            continue
        picked.append({
            'id': it.get('id'),
            'type': t,
            'text': it.get('text'),
            'score': it.get('score'),
            'confidence': it.get('confidence'),
            'entity': it.get('entity'),
            'project': it.get('project'),
        })
        type_count[t] += 1
        if len(picked) >= args.max_total:
            break

    # human-readable cue lines
    cues = []
    for p in picked:
        cues.append(f"[{p['type']}] {p['text']}")

    payload = {
        'ok': True,
        'picked_count': len(picked),
        'picked': picked,
        'cues': cues,
        'limits': LIMITS,
    }

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'ok': True, 'out': str(out), 'picked_count': len(picked)}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
