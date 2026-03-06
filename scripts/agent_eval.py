#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

BASE = Path('/home/humil/.openclaw/workspace')


def run(cmd):
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return p.returncode, (p.stdout or '').strip(), (p.stderr or '').strip()


def main():
    checks = []

    rc, out, err = run(f"{BASE}/scripts/memory_benchmark.py")
    bench_ok = False
    hit_rate = None
    if rc == 0:
        try:
            j = json.loads(out)
            hit_rate = float(j.get('hit_rate', 0.0))
            bench_ok = hit_rate >= 95.0
        except Exception:
            pass
    checks.append({"name": "memory_benchmark", "ok": bench_ok, "hit_rate": hit_rate, "rc": rc})

    rc, out, err = run("openclaw gateway status")
    gw_ok = (rc == 0 and "Listening:" in out)
    checks.append({"name": "gateway_status", "ok": gw_ok, "rc": rc})

    rc, out, err = run("openclaw cron list")
    cron_ok = (rc == 0)
    checks.append({"name": "cron_access", "ok": cron_ok, "rc": rc})

    overall = all(c.get('ok') for c in checks)
    print(json.dumps({"ok": overall, "checks": checks}, ensure_ascii=False, indent=2))
    raise SystemExit(0 if overall else 1)


if __name__ == '__main__':
    main()
