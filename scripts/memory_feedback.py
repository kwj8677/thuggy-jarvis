#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

ITEMS = Path('/home/humil/.openclaw/workspace/memory/memory_items.jsonl')


def load_items():
    arr = []
    if not ITEMS.exists():
        return arr
    for ln in ITEMS.read_text(encoding='utf-8', errors='replace').splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            arr.append(json.loads(ln))
        except Exception:
            pass
    return arr


def save_items(arr):
    with ITEMS.open('w', encoding='utf-8') as f:
        for it in arr:
            f.write(json.dumps(it, ensure_ascii=False) + '\n')


def clamp(v, lo=0.05, hi=0.99):
    return max(lo, min(hi, v))


def main():
    ap = argparse.ArgumentParser(description='Adjust memory confidence by feedback')
    ap.add_argument('--id', required=True)
    ap.add_argument('--signal', choices=['confirm', 'correct', 'reject'], required=True)
    ap.add_argument('--note', default='')
    args = ap.parse_args()

    items = load_items()
    target = None
    for it in items:
        if it.get('id') == args.id:
            target = it
            break

    if not target:
        print(json.dumps({'ok': False, 'reason': 'id_not_found'}))
        return

    c = float(target.get('confidence', 0.6))
    if args.signal == 'confirm':
        c = clamp(c + 0.07)
    elif args.signal == 'correct':
        c = clamp(c - 0.10)
    elif args.signal == 'reject':
        c = clamp(c - 0.20)

    target['confidence'] = round(c, 3)
    target['updated_at'] = __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat()
    if args.note:
        target.setdefault('feedback_notes', []).append(args.note)

    save_items(items)
    print(json.dumps({'ok': True, 'id': args.id, 'signal': args.signal, 'new_confidence': target['confidence']}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
