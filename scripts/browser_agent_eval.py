#!/usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path

CASES = Path('/home/humil/.openclaw/workspace/evals/browser_agent_cases.json')


def get_json_field(path, field):
    data = json.loads(Path(path).read_text(encoding='utf-8'))
    return data.get(field)


def run_cmd(cmd):
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return p.returncode, (p.stdout or '') + (p.stderr or '')


def eval_case(c):
    t = c.get('type')
    if t == 'file_exists':
        ok = Path(c['path']).exists()
        return {'id': c['id'], 'ok': ok}

    if t == 'json_field_equals':
        try:
            v = get_json_field(c['path'], c['field'])
            ok = (v == c.get('expected'))
            return {'id': c['id'], 'ok': ok, 'value': v}
        except Exception as e:
            return {'id': c['id'], 'ok': False, 'error': str(e)}

    if t == 'command_contains':
        rc, out = run_cmd(c['command'])
        needles = [x.lower() for x in c.get('contains_any', [])]
        ok = (rc == 0) and any(n in out.lower() for n in needles)
        return {'id': c['id'], 'ok': ok, 'rc': rc}

    if t == 'file_contains':
        try:
            txt = Path(c['path']).read_text(encoding='utf-8', errors='replace')
            ok = c.get('contains', '') in txt
            return {'id': c['id'], 'ok': ok}
        except Exception as e:
            return {'id': c['id'], 'ok': False, 'error': str(e)}

    if t == 'command_json_true':
        try:
            rc, out = run_cmd(c['command'])
            if rc != 0:
                return {'id': c['id'], 'ok': False, 'rc': rc}
            j = json.loads(out)
            ok = bool(j.get(c.get('field'))) == bool(c.get('expected'))
            return {'id': c['id'], 'ok': ok, 'value': j.get(c.get('field'))}
        except Exception as e:
            return {'id': c['id'], 'ok': False, 'error': str(e)}

    return {'id': c.get('id', 'unknown'), 'ok': False, 'error': 'unknown_type'}


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
        'rows': rows
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
