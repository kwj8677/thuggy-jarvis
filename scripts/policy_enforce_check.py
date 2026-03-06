#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

POLICY = Path('/home/humil/.openclaw/workspace/agent-reliability/POLICY.json')


def load_policy():
    if not POLICY.exists():
        return {}
    try:
        return json.loads(POLICY.read_text(encoding='utf-8'))
    except Exception:
        return {}


def classify(action: str):
    a = (action or '').strip().lower()
    p = load_policy().get('rules', {})
    req = {x.lower() for x in p.get('require_approval', [])}
    allow = {x.lower() for x in p.get('auto_allow', [])}
    if a in req:
        return 'require_approval'
    if a in allow:
        return 'auto_allow'
    return 'unknown'


def main():
    ap = argparse.ArgumentParser(description='Policy enforcement checker (baseline)')
    ap.add_argument('--action', required=True)
    args = ap.parse_args()

    decision = classify(args.action)
    out = {
        'ok': True,
        'action': args.action,
        'decision': decision,
        'policy': str(POLICY),
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))
    raise SystemExit(0 if decision != 'unknown' else 2)


if __name__ == '__main__':
    main()
