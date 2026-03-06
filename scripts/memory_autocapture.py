#!/usr/bin/env python3
import argparse
import re
import subprocess

CAPTURE = '/home/humil/.openclaw/workspace/scripts/memory_capture.py'

TYPE_RULES = [
    ('decision', [r'\b앞으로\b', r'\b원칙\b', r'\b규칙\b', r'\b정책\b', r'\b반드시\b']),
    ('preference', [r'\b선호\b', r'\b좋아\b', r'\b싫어\b', r'\bprefer\b']),
    ('task_state', [r'\b진행\b', r'\b다음\b', r'\bTODO\b', r'\b다음단계\b']),
]


def detect_type(text: str) -> str:
    t = text.lower()
    for tp, pats in TYPE_RULES:
        if any(re.search(p, t, flags=re.I) for p in pats):
            return tp
    return 'fact'


def should_capture(text: str) -> bool:
    t = text.lower()
    triggers = ['기억해', 'remember', '앞으로', '원칙', '규칙', '정책', '항상', '다음']
    return any(x in t for x in triggers)


def main():
    ap = argparse.ArgumentParser(description='Auto-capture memory from text')
    ap.add_argument('--text', required=True)
    ap.add_argument('--source', default='auto-hook')
    ap.add_argument('--force', action='store_true')
    args = ap.parse_args()

    if not args.force and not should_capture(args.text):
        print('{"captured": false, "reason": "trigger_not_met"}')
        return

    mtype = detect_type(args.text)
    cmd = [CAPTURE, '--type', mtype, '--text', args.text, '--source', args.source, '--project', 'openclaw-memory']
    if args.force:
        cmd.append('--force')
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode == 0:
        print(p.stdout.strip())
    else:
        print('{"captured": false, "reason": "capture_failed"}')
        if p.stderr:
            print(p.stderr.strip())


if __name__ == '__main__':
    main()
