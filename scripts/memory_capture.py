#!/usr/bin/env python3
import argparse
import json
import time
import uuid
from pathlib import Path

ITEMS = Path('/home/humil/.openclaw/workspace/memory/memory_items.jsonl')

TTL_DEFAULT = {
    'fact': 180,
    'preference': 90,
    'decision': 120,
    'task_state': 14,
}


def iso_now():
    return __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat()


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


def text_sim(a, b):
    a = set((a or '').lower().split())
    b = set((b or '').lower().split())
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def should_store(text, force=False):
    if force:
        return True
    txt = (text or '').lower()
    triggers = ['기억해', 'remember', '앞으로', '규칙', '원칙', '정책', '항상']
    return any(t in txt for t in triggers)


def confidence_by_source(source: str, base: float) -> float:
    s = (source or '').lower()
    if 'user' in s or 'manual' in s:
        return min(1.0, max(base, 0.82))
    if 'auto' in s:
        return min(1.0, max(0.6, base))
    return min(1.0, max(0.5, base))


def main():
    ap = argparse.ArgumentParser(description='Memory capture v1')
    ap.add_argument('--type', choices=['fact', 'preference', 'decision', 'task_state'], required=True)
    ap.add_argument('--text', required=True)
    ap.add_argument('--source', default='manual')
    ap.add_argument('--confidence', type=float, default=0.75)
    ap.add_argument('--entity', default='')
    ap.add_argument('--project', default='')
    ap.add_argument('--depends-on', default='')
    ap.add_argument('--force', action='store_true')
    args = ap.parse_args()

    if not should_store(args.text, force=args.force):
        print(json.dumps({'stored': False, 'reason': 'trigger_not_met'}, ensure_ascii=False))
        return

    items = load_items()

    # 단순 중복 차단
    for it in reversed(items[-80:]):
        if it.get('type') == args.type and text_sim(it.get('text', ''), args.text) >= 0.85 and it.get('status', 'active') == 'active':
            print(json.dumps({'stored': False, 'reason': 'duplicate', 'existing_id': it.get('id')}, ensure_ascii=False))
            return

    now = iso_now()
    conf = confidence_by_source(args.source, float(args.confidence))

    deps = [x.strip() for x in (args.depends_on or '').split(',') if x.strip()]

    item = {
        'id': str(uuid.uuid4()),
        'type': args.type,
        'text': args.text.strip(),
        'created_at': now,
        'updated_at': now,
        'last_used_at': None,
        'confidence': round(conf, 3),
        'ttl_days': TTL_DEFAULT[args.type],
        'status': 'active',
        'source': args.source,
        'entity': args.entity.strip() or None,
        'project': args.project.strip() or None,
        'depends_on': deps,
        'tags': []
    }

    ITEMS.parent.mkdir(parents=True, exist_ok=True)
    with ITEMS.open('a', encoding='utf-8') as f:
        f.write(json.dumps(item, ensure_ascii=False) + '\n')

    print(json.dumps({'stored': True, 'item': item}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
