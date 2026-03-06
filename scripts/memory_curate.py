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


def sim(a, b):
    sa = set((a or '').lower().split())
    sb = set((b or '').lower().split())
    if not sa or not sb:
        return 0.0
    return len(sa & sb) / len(sa | sb)


def main():
    ap = argparse.ArgumentParser(description='memory curate v1 (dedupe + supersede)')
    ap.add_argument('--threshold', type=float, default=0.86)
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    items = load_items()
    changed = 0

    for i in range(len(items)):
        a = items[i]
        if a.get('status', 'active') != 'active':
            continue
        for j in range(i + 1, len(items)):
            b = items[j]
            if b.get('status', 'active') != 'active':
                continue
            if a.get('type') != b.get('type'):
                continue
            if sim(a.get('text', ''), b.get('text', '')) >= args.threshold:
                # newer/confident one wins
                a_score = float(a.get('confidence', 0.6))
                b_score = float(b.get('confidence', 0.6))
                if b_score >= a_score:
                    a['status'] = 'superseded'
                    a['superseded_by'] = b.get('id')
                    b.setdefault('contradicted_ids', [])
                    if a.get('id') not in b['contradicted_ids']:
                        b['contradicted_ids'].append(a.get('id'))
                    changed += 1
                    break
                else:
                    b['status'] = 'superseded'
                    b['superseded_by'] = a.get('id')
                    a.setdefault('contradicted_ids', [])
                    if b.get('id') not in a['contradicted_ids']:
                        a['contradicted_ids'].append(b.get('id'))
                    changed += 1

    out = {'changed': changed, 'items': len(items)}
    if not args.dry_run:
        with ITEMS.open('w', encoding='utf-8') as f:
            for it in items:
                f.write(json.dumps(it, ensure_ascii=False) + '\n')

    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
