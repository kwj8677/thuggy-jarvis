#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

BASE = Path('/home/humil/.openclaw/workspace')
DATA = BASE / 'evals' / 'memory_eval_dataset.jsonl'
RECALL = BASE / 'scripts' / 'memory_recall.py'


def run_recall(query: str):
    p = subprocess.run([
        str(RECALL), '--query', query, '--top-k', '4', '--min-score', '0.35'
    ], capture_output=True, text=True)
    if p.returncode != 0:
        return {'count': 0, 'items': []}
    try:
        return json.loads(p.stdout)
    except Exception:
        return {'count': 0, 'items': []}


def judge(example, pred):
    ideal = example.get('ideal')
    count = int(pred.get('count', 0))
    text = ' '.join((x.get('text') or '') for x in pred.get('items', []))
    meta = example.get('meta', {})

    if ideal == 'NO_MEMORY':
        return count == 0

    expects = meta.get('expects_any', [])
    if count <= 0:
        return False
    if expects:
        return any(e.lower() in text.lower() for e in expects)
    return True


def main():
    rows = []
    hit = 0
    total = 0

    for ln in DATA.read_text(encoding='utf-8').splitlines():
        if not ln.strip():
            continue
        ex = json.loads(ln)
        pred = run_recall(ex['input'])
        ok = judge(ex, pred)
        total += 1
        if ok:
            hit += 1
        rows.append({
            'id': ex.get('id'),
            'input': ex.get('input'),
            'ideal': ex.get('ideal'),
            'ok': ok,
            'count': pred.get('count', 0)
        })

    out = {
        'ok': True,
        'total': total,
        'hit': hit,
        'hit_rate': round((hit / total * 100.0) if total else 0.0, 1),
        'rows': rows
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
