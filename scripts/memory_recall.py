#!/usr/bin/env python3
import argparse
import json
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
        if isinstance(v, str) and v.endswith('Z'):
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


def terms(s: str):
    return [t for t in (s or '').lower().replace(',', ' ').split() if t]


def keyword_score(q, txt):
    q_terms = terms(q)
    if not q_terms:
        return 0.0
    txt_l = (txt or '').lower()
    hit = sum(1 for t in q_terms if t in txt_l)
    return hit / len(q_terms)


def phrase_bonus(q, txt):
    q_terms = terms(q)
    if len(q_terms) < 2:
        return 0.0
    txt_l = (txt or '').lower()
    hits = 0
    pairs = 0
    for i in range(len(q_terms) - 1):
        pairs += 1
        phrase = q_terms[i] + ' ' + q_terms[i + 1]
        if phrase in txt_l:
            hits += 1
    return (hits / pairs) if pairs else 0.0


def freshness_score(item, n):
    t = parse_ts(item.get('updated_at') or item.get('created_at'))
    age_days = max(0.0, (n - t) / 86400)
    ttl = item.get('ttl_days') or TTL_DEFAULT.get(item.get('type', ''), 90)
    if age_days <= ttl:
        return max(0.2, 1.0 - (age_days / max(ttl, 1)))
    return 0.05


def source_trust(item):
    src = str(item.get('source') or '').lower()
    if 'user-confirmed' in src or 'manual' in src:
        return 1.0
    if 'auto' in src:
        return 0.7
    return 0.8


def base_score(q, item, n):
    if item.get('status', 'active') != 'active':
        return -1
    sem = keyword_score(q, item.get('text', ''))
    graph_text = ' '.join([
        str(item.get('entity') or ''),
        str(item.get('project') or ''),
        ' '.join(item.get('depends_on') or []),
    ]).strip()
    graph_bonus = keyword_score(q, graph_text) if graph_text else 0.0
    fresh = freshness_score(item, n)
    conf = float(item.get('confidence', 0.6))
    tw = TYPE_WEIGHT.get(item.get('type', ''), 0.5)
    trust = source_trust(item)
    return 0.44 * sem + 0.14 * graph_bonus + 0.18 * fresh + 0.10 * conf + 0.05 * tw + 0.09 * trust


def rerank_score(q, item, s0):
    txt = item.get('text', '')
    pbonus = phrase_bonus(q, txt)
    # project/entity exact boosts
    ql = (q or '').lower()
    e = str(item.get('entity') or '').lower()
    p = str(item.get('project') or '').lower()
    ep_boost = 0.0
    if e and e in ql:
        ep_boost += 0.06
    if p and p in ql:
        ep_boost += 0.06
    return s0 + 0.18 * pbonus + ep_boost


def graph_expand(selected, all_items, max_extra=2):
    if not selected:
        return selected
    seen_ids = {x.get('id') for x in selected}
    key_projects = {x.get('project') for x in selected if x.get('project')}
    key_entities = {x.get('entity') for x in selected if x.get('entity')}

    extra = []
    for it in all_items:
        if it.get('id') in seen_ids:
            continue
        if it.get('status', 'active') != 'active':
            continue
        if (it.get('project') in key_projects) or (it.get('entity') in key_entities):
            x = dict(it)
            x['score'] = round(float(x.get('score', 0.0)) + 0.03, 4)
            extra.append(x)
        if len(extra) >= max_extra:
            break
    return selected + extra


def main():
    ap = argparse.ArgumentParser(description='Memory recall v2 (hybrid + rerank + graph expansion)')
    ap.add_argument('--query', required=True)
    ap.add_argument('--top-k', type=int, default=3)
    ap.add_argument('--min-score', type=float, default=0.45)
    ap.add_argument('--expand-graph', action='store_true')
    args = ap.parse_args()

    n = now_ts()
    items = load_items()

    scored = []
    for it in items:
        s0 = base_score(args.query, it, n)
        if s0 <= 0:
            continue
        s1 = rerank_score(args.query, it, s0)
        scored.append((s1, it))

    scored.sort(key=lambda x: x[0], reverse=True)
    candidate_pool = scored[: max(args.top_k * 3, args.top_k)]

    out = []
    for s, it in candidate_pool:
        if len(out) >= args.top_k:
            break
        if s < args.min_score:
            continue
        x = dict(it)
        x['score'] = round(s, 4)
        out.append(x)

    if args.expand_graph:
        out = graph_expand(out, [dict(i) for _, i in scored], max_extra=2)

    print(json.dumps({
        'query': args.query,
        'count': len(out),
        'min_score': args.min_score,
        'rerank_pool': len(candidate_pool),
        'items': out
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
