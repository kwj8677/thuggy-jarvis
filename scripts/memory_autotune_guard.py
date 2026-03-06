#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path
from datetime import datetime, timezone

BASE = Path('/home/humil/.openclaw/workspace')
BENCH = BASE / 'scripts' / 'memory_benchmark.py'
STATE = BASE / 'memory' / 'memory-autotune-state.json'

PASS_RATE = 95.0


def run_bench():
    p = subprocess.run([str(BENCH)], capture_output=True, text=True)
    if p.returncode != 0:
        return None
    try:
        return json.loads(p.stdout)
    except Exception:
        return None


def load_state():
    if not STATE.exists():
        return {"last_good": None, "history": []}
    try:
        return json.loads(STATE.read_text(encoding='utf-8'))
    except Exception:
        return {"last_good": None, "history": []}


def save_state(s):
    STATE.write_text(json.dumps(s, ensure_ascii=False, indent=2), encoding='utf-8')


def main():
    bench = run_bench()
    if not bench:
        print(json.dumps({"ok": False, "reason": "benchmark_failed"}, ensure_ascii=False))
        return

    hit_rate = float(bench.get('hit_rate', 0.0))
    passed = hit_rate >= PASS_RATE

    state = load_state()
    rec = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "hit_rate": hit_rate,
        "total": bench.get('total', 0),
        "hit": bench.get('hit', 0),
        "passed": passed,
    }
    state.setdefault("history", []).append(rec)
    state["history"] = state["history"][-30:]

    action = "hold"
    if passed:
        state["last_good"] = rec
        action = "keep_current"
    else:
        action = "freeze_tuning_and_review"

    save_state(state)
    print(json.dumps({
        "ok": True,
        "action": action,
        "pass_rate_threshold": PASS_RATE,
        "benchmark": rec,
        "last_good": state.get("last_good"),
        "state": str(STATE),
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
