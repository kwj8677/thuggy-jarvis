#!/usr/bin/env python3
import argparse
import json
import subprocess
from pathlib import Path

WORK = Path('/home/humil/.openclaw/workspace')
PROFILE = WORK / 'memory' / 'profile.json'
OUT = Path('/tmp/openclaw/memory-context-latest.json')


def run_recall(query: str, top_k: int, min_score: float):
    cmd = [str(WORK / 'scripts' / 'memory_recall.py'), '--query', query, '--top-k', str(top_k), '--min-score', str(min_score)]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        return {'error': p.stderr.strip() or p.stdout.strip()}
    try:
        return json.loads(p.stdout)
    except Exception:
        return {'raw': p.stdout}


def update_metrics(invoked: int, hit: int):
    cmd = [
        str(WORK / 'scripts' / 'memory_metrics_update.py'),
        '--recall-invoke', str(invoked),
        '--recall-hit', str(hit),
    ]
    subprocess.run(cmd, capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser(description='Generate memory context snapshot for current work')
    ap.add_argument('--query', default='openclaw gateway 장애 복구 알림 email psw windows 규칙 원칙 정책 안정성 메모리 운영')
    ap.add_argument('--top-k', type=int, default=4)
    ap.add_argument('--min-score', type=float, default=0.35)
    ap.add_argument('--out', default=str(OUT))
    args = ap.parse_args()

    profile = {}
    if PROFILE.exists():
        try:
            profile = json.loads(PROFILE.read_text(encoding='utf-8'))
        except Exception:
            profile = {}

    recall = run_recall(args.query, args.top_k, args.min_score)

    hit_count = len((recall.get('items') or [])) if isinstance(recall, dict) else 0
    update_metrics(invoked=1, hit=1 if hit_count > 0 else 0)

    payload = {
        'query': args.query,
        'profile': profile,
        'recall': recall,
    }

    outp = Path(args.out)
    outp.parent.mkdir(parents=True, exist_ok=True)
    outp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'ok': True, 'out': str(outp), 'recall_count': hit_count}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
