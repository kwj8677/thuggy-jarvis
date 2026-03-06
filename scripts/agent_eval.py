#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

BASE = Path('/home/humil/.openclaw/workspace')


def run(cmd):
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return p.returncode, (p.stdout or '').strip(), (p.stderr or '').strip()


def run_json(cmd):
    rc, out, err = run(cmd)
    if rc != 0:
        return rc, None, err or out
    try:
        return rc, json.loads(out), ''
    except Exception:
        return rc, None, 'json_parse_error'


def main():
    checks = []

    # 1) Benchmark breadth (precision/negative included)
    rc, j, e = run_json(f"{BASE}/scripts/memory_benchmark.py")
    bench_ok = False
    hit_rate = None
    neg_ok = None
    if j:
        hit_rate = float(j.get('hit_rate', 0.0))
        rows = j.get('rows', [])
        neg_rows = [r for r in rows if '무관' in r.get('query', '') or '랜덤' in r.get('query', '') or 'poem' in r.get('query', '') or '영화' in r.get('query', '') or '배경화면' in r.get('query', '')]
        neg_ok = all(int(r.get('count', 0)) == 0 for r in neg_rows) if neg_rows else True
        bench_ok = hit_rate >= 95.0 and neg_ok
    checks.append({"name": "memory_benchmark", "ok": bench_ok, "hit_rate": hit_rate, "negative_guard_ok": neg_ok, "rc": rc})

    # 2) Gateway status
    rc, out, err = run("openclaw gateway status")
    gw_ok = (rc == 0 and "Listening:" in out)
    checks.append({"name": "gateway_status", "ok": gw_ok, "rc": rc})

    # 3) Cron access
    rc, out, err = run("openclaw cron list")
    cron_ok = (rc == 0)
    checks.append({"name": "cron_access", "ok": cron_ok, "rc": rc})

    # 4) Drift check
    rc, j, e = run_json(f"{BASE}/scripts/memory_drift_check.py")
    drift_ok = bool(j and int(j.get('stale_low_conf_count', 9999)) <= 2)
    checks.append({"name": "memory_drift", "ok": drift_ok, "stale_low_conf_count": (j or {}).get('stale_low_conf_count'), "rc": rc})

    # 5) Policy enforce checks (force coverage)
    rc1, j1, _ = run_json(f"{BASE}/scripts/policy_enforce_check.py --action external_send")
    rc2, j2, _ = run_json(f"{BASE}/scripts/policy_enforce_check.py --action status_check")
    policy_ok = bool(j1 and j2 and j1.get('decision') == 'require_approval' and j2.get('decision') == 'auto_allow')
    checks.append({"name": "policy_enforcement", "ok": policy_ok, "rc": max(rc1, rc2)})

    # 6) Circuit breaker sanity
    rc, j, e = run_json(f"{BASE}/scripts/tool_circuit_breaker.py")
    cb_ok = bool(j and 'result' in j)
    checks.append({"name": "tool_circuit_breaker", "ok": cb_ok, "rc": rc})

    overall = all(c.get('ok') for c in checks)
    summary = {
        'ok': overall,
        'score': round(sum(1 for c in checks if c.get('ok')) / len(checks) * 100.0, 1),
        'checks': checks,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    raise SystemExit(0 if overall else 1)


if __name__ == '__main__':
    main()
