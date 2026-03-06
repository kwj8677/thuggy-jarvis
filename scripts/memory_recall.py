#!/usr/bin/env python3
import argparse
import json
import math
import time
from pathlib import Path

ITEMS = Path('/home/humil/.openclaw/workspace/memory/memory_items.jsonl')

TYPE_WEIGHT = {
    'decision': 1.0,
    'task_state': 0.9,
    'preference': 0.8,
    'fact': 0.7,
}
TTL_DEFAULT = {
    'fact': 180,
    'preference': 90,
    'decision': 120,
    'task_state': 14,
}


def now_ts():
    return int(time.time())


def parse_ts(v):
    if isinstance(v, int):
        return v
    if not v:
        return now_ts()
    try:
        if v.endswith('Z'):
            v = v[:-1] + '+00:00'
        return int(__import__('datetime').datetime.fromisoformat(v).timestamp())
    except Exception:
        return now_ts()


def load_items():
    out = []
    if not ITEMS.exists():
        return out
    for line in ITEMS.read_text(encoding='utf-8', errors='replace').splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except Exception:
            continue
    return out


def keyword_score(q, txt):
    q_terms = [t for t in q.lower().split() if t]
    if not q_terms:
        return 0.0
    txt_l = (txt or '').lower()
    hit = sum(1 for t in q_terms if t in txt_l)
    return hit / len(q_terms)


def freshness_score(item, n):
    t = parse_ts(item.get('updated_at') or item.get('created_at'))
    age_days = max(0.0, (n - t) / 86400)
    ttl = item.get('ttl_days') or TTL_DEFAULT.get(item.get('type', ''), 90)
    if age_days <= ttl:
        return max(0.2, 1.0 - (age_days / max(ttl, 1)))
    # ttl 초과: 강감점
    return 0.05


def final_score(q, item, n):
    if item.get('status', 'active') != 'active':
        return -1
    sem = keyword_score(q, item.get('text', ''))
    # graph bonus: entity/project/depends_on keyword hits
    graph_text = ' '.join([
        str(item.get('entity') or ''),
        str(item.get('project') or ''),
        ' '.join(item.get('depends_on') or []),
    ]).strip()
    graph_bonus = keyword_score(q, graph_text) if graph_text else 0.0
    fresh = freshness_score(item, n)
    conf = float(item.get('confidence', 0.6))
    tw = TYPE_WEIGHT.get(item.get('type', ''), 0.5)
    return 0.50 * sem + 0.15 * graph_bonus + 0.20 * fresh + 0.10 * conf + 0.05 * tw


def main():
    ap = argparse.ArgumentParser(description='Memory recall v1 (Top-k + freshness + confidence + type)')
    ap.add_argument('--query', required=True)
    ap.add_argument('--top-k', type=int, default=3)
    ap.add_argument('--min-score', type=float, default=0.45)
    args = ap.parse_args()

    n = now_ts()
    items = load_items()
    scored = []
    for it in items:
        s = final_score(args.query, it, n)
        if s <= 0:
            continue
        scored.append((s, it))
    scored.sort(key=lambda x: x[0], reverse=True)

    out = []
    for s, it in scored[: args.top_k]:
        if s < args.min_score:
            continue
        x = dict(it)
        x['score'] = round(s, 4)
        out.append(x)

    print(json.dumps({'query': args.query, 'count': len(out), 'min_score': args.min_score, 'items': out}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
