#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

BASE = Path('/home/humil/.openclaw/workspace')
CASES = BASE / 'evals' / 'agentbench_lite_cases.json'
POLICY = BASE / 'scripts' / 'policy_enforce_check.py'
RECALL = BASE / 'scripts' / 'memory_recall.py'


def run_json(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode not in (0, 2):
        return None
    try:
        return json.loads(p.stdout)
    except Exception:
        return None


def eval_case(c):
    cid = c['id']
    if 'action' in c:
        j = run_json([str(POLICY), '--action', c['action']])
        ok = bool(j and j.get('decision') == c.get('expected_decision'))
        return {'id': cid, 'ok': ok, 'detail': j}

    q = c.get('query')
    j = run_json([str(RECALL), '--query', q, '--top-k', '4', '--min-score', '0.35'])
    if not j:
        return {'id': cid, 'ok': False, 'detail': {'error': 'recall_failed'}}

    count = int(j.get('count', 0))
    text = ' '.join((x.get('text') or '') for x in j.get('items', []))

    ok = True
    if 'expect_exact_count' in c:
        ok = ok and (count == int(c['expect_exact_count']))
    if 'expect_min_count' in c:
        ok = ok and (count >= int(c['expect_min_count']))
    if c.get('expect_any'):
        ok = ok and any(k.lower() in text.lower() for k in c['expect_any'])

    return {'id': cid, 'ok': ok, 'detail': {'count': count, 'query': q}}


def main():
    cases = json.loads(CASES.read_text(encoding='utf-8'))
    rows = [eval_case(c) for c in cases]
    total = len(rows)
    hit = sum(1 for r in rows if r.get('ok'))
    out = {
        'ok': hit == total,
        'total': total,
        'hit': hit,
        'hit_rate': round((hit / total * 100.0) if total else 0.0, 1),
        'rows': rows,
        'note': 'AgentBench-lite bridge for local OpenClaw reliability/memory checks',
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
