#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

CASES = Path('/home/humil/.openclaw/workspace/scripts/benchmark_cases.json')
RECALL = '/home/humil/.openclaw/workspace/scripts/memory_recall.py'


def run_case(q):
    p = subprocess.run([RECALL, '--query', q, '--top-k', '4', '--min-score', '0.35'], capture_output=True, text=True)
    if p.returncode != 0:
        return None
    try:
        return json.loads(p.stdout)
    except Exception:
        return None


def hit_case(result, case):
    if not result:
        return False
    txt = ' '.join([(x.get('text') or '') for x in (result.get('items') or [])]).lower()
    mode = case.get('mode', 'any')
    any_terms = case.get('expects_any', [])
    none_terms = case.get('expects_none', [])

    if mode == 'none':
        # strict negative case: should return no recalled items
        return int(result.get('count', 0)) == 0
    if mode == 'all':
        return all(t.lower() in txt for t in any_terms)
    return any(t.lower() in txt for t in any_terms)


def main():
    if not CASES.exists():
        print(json.dumps({'ok': False, 'reason': 'cases_not_found'}))
        return
    cases = json.loads(CASES.read_text(encoding='utf-8'))

    rows = []
    hit = 0
    for c in cases:
        r = run_case(c['query'])
        h = hit_case(r, c)
        if h:
            hit += 1
        rows.append({'query': c['query'], 'hit': h, 'count': (r or {}).get('count', 0)})

    total = len(cases)
    hit_rate = (hit / total * 100.0) if total else 0.0
    print(json.dumps({'ok': True, 'total': total, 'hit': hit, 'hit_rate': round(hit_rate, 1), 'rows': rows}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
