#!/usr/bin/env python3
import argparse
import glob
import gzip
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

PATTERN_DEFS = [
    ("critical", r"FailoverError"),
    ("critical", r"embedded run timeout"),
    ("critical", r"gateway timeout"),
    ("warn", r"\b429\b"),
    ("warn", r"rate\s*limit"),
]


def latest_log(log_dir: Path) -> Path | None:
    logs = sorted(glob.glob(str(log_dir / "openclaw-*.log")))
    return Path(logs[-1]) if logs else None


def tail_lines(path: Path, max_lines: int = 1200) -> list[str]:
    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            data = f.readlines()
        return data[-max_lines:]
    except FileNotFoundError:
        return []


def compress_old_logs(log_dir: Path, keep_days: int = 7) -> dict:
    now = time.time()
    compressed, deleted = [], []

    for raw in sorted(log_dir.glob("openclaw-*.log")):
        age_days = (now - raw.stat().st_mtime) / 86400
        gz = raw.with_suffix(raw.suffix + ".gz")

        if age_days >= 1 and not gz.exists():
            with raw.open("rb") as src, gzip.open(gz, "wb") as dst:
                shutil.copyfileobj(src, dst)
            raw.unlink(missing_ok=True)
            compressed.append(str(gz))

    for gz in sorted(log_dir.glob("openclaw-*.log.gz")):
        age_days = (now - gz.stat().st_mtime) / 86400
        if age_days > keep_days:
            gz.unlink(missing_ok=True)
            deleted.append(str(gz))

    return {"compressed": compressed, "deleted": deleted}


def load_state(path: Path) -> dict:
    if not path.exists():
        return {"events": [], "seen": {}, "last_recovery_ts": 0}
    try:
        st = json.loads(path.read_text(encoding="utf-8"))
        st.setdefault("events", [])
        st.setdefault("seen", {})
        st.setdefault("last_recovery_ts", 0)
        return st
    except Exception:
        return {"events": [], "seen": {}, "last_recovery_ts": 0}


def save_state(path: Path, state: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def fp(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8", errors="ignore")).hexdigest()[:16]


def detect_hits(lines: list[str]) -> list[dict]:
    compiled = [(sev, re.compile(pat, re.I)) for sev, pat in PATTERN_DEFS]
    out = []
    for ln in lines:
        text = ln.strip()
        for sev, cre in compiled:
            if cre.search(text):
                out.append({"severity": sev, "line": text, "fingerprint": fp(text)})
                break
    return out


def write_forensics(log_path: Path | None, lines: list[str], payload: dict, out_dir: Path) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    ts = time.strftime('%Y%m%d-%H%M%S', time.localtime())
    bundle = {
        "timestamp": ts,
        "log": str(log_path) if log_path else None,
        "payload": payload,
        "tail": lines[-200:],
    }
    json_path = out_dir / f"gateway-forensics-{ts}.json"
    txt_path = out_dir / f"gateway-forensics-{ts}.tail.log"
    json_path.write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding='utf-8')
    txt_path.write_text(''.join(lines[-200:]), encoding='utf-8', errors='replace')
    return {"json": str(json_path), "tail": str(txt_path)}


def run_cmd(cmd: str, env_extra: dict | None = None, timeout: int = 25) -> tuple[bool, int, str]:
    try:
        env = os.environ.copy()
        if env_extra:
            env.update(env_extra)
        r = subprocess.run(cmd, shell=True, env=env, capture_output=True, text=True, timeout=timeout)
        msg = ((r.stdout or "") + "\n" + (r.stderr or "")).strip()[:1200]
        return r.returncode == 0, r.returncode, msg
    except Exception as e:
        return False, 999, str(e)


def maybe_recover(args, st, now, out_payload, alert: bool):
    result = {
        "attempted": False,
        "cooldown_active": False,
        "restart_ok": None,
        "verify_ok": None,
        "details": "",
    }

    if not args.recover_on_alert or not alert:
        return result

    last = int(st.get("last_recovery_ts", 0))
    if now - last < args.recover_cooldown_min * 60:
        result["cooldown_active"] = True
        result["details"] = f"cooldown active ({args.recover_cooldown_min}m)"
        return result

    if not args.recover_cmd.strip() or not args.verify_cmd.strip():
        result["details"] = "recover/verify cmd missing"
        return result

    result["attempted"] = True
    ok1, rc1, msg1 = run_cmd(args.recover_cmd.strip(), timeout=40)
    result["restart_ok"] = ok1

    # brief wait then verify
    time.sleep(args.recover_wait_sec)
    ok2, rc2, msg2 = run_cmd(args.verify_cmd.strip(), timeout=35)
    result["verify_ok"] = ok2

    result["details"] = f"recover_rc={rc1}, verify_rc={rc2}; recover={msg1[:300]} | verify={msg2[:300]}"

    if ok1 and ok2:
        st["last_recovery_ts"] = now

    return result


def main():
    ap = argparse.ArgumentParser(description="OpenClaw gateway guard (rolling + dedupe + severity + recovery)")
    ap.add_argument("--log-dir", default="/tmp/openclaw")
    ap.add_argument("--state", default="/home/humil/.openclaw/workspace/memory/gateway-guard-state.json")
    ap.add_argument("--window-min", type=int, default=45)
    ap.add_argument("--threshold", type=int, default=2)
    ap.add_argument("--tail-lines", type=int, default=1200)
    ap.add_argument("--keep-days", type=int, default=7)
    ap.add_argument("--dedupe-min", type=int, default=30)
    ap.add_argument("--forensic-dir", default="/tmp/openclaw/forensics")

    ap.add_argument("--notify-cmd", default="")

    ap.add_argument("--recover-on-alert", action="store_true")
    ap.add_argument("--recover-cooldown-min", type=int, default=20)
    ap.add_argument("--recover-wait-sec", type=int, default=4)
    ap.add_argument("--recover-cmd", default="bash -lc 'openclaw gateway stop >/dev/null 2>&1 || true; sleep 1; openclaw gateway >/tmp/openclaw/gateway-guard-launch.log 2>&1 &' ")
    ap.add_argument("--verify-cmd", default="bash -lc 'openclaw status --deep >/tmp/openclaw/gateway-guard-verify.log 2>&1' ")

    args = ap.parse_args()

    now = int(time.time())
    log_dir = Path(args.log_dir)
    state_path = Path(args.state)

    roll_info = compress_old_logs(log_dir, keep_days=args.keep_days)
    log_path = latest_log(log_dir)
    lines = tail_lines(log_path, args.tail_lines) if log_path else []

    st = load_state(state_path)
    seen: dict = st.get("seen", {})
    dedupe_cutoff = now - args.dedupe_min * 60
    seen = {k: v for k, v in seen.items() if int(v) >= dedupe_cutoff}

    raw_hits = detect_hits(lines)
    new_hits = []
    for h in raw_hits:
        k = h["fingerprint"]
        if k in seen:
            continue
        seen[k] = now
        new_hits.append(h)

    events = st.get("events", [])
    if new_hits:
        sev_score = {"critical": 2, "warn": 1}
        top = sorted(new_hits, key=lambda x: sev_score.get(x["severity"], 0), reverse=True)[0]["severity"]
        events.append({
            "ts": now,
            "severity": top,
            "count": len(new_hits),
            "log": str(log_path) if log_path else None,
            "samples": [h["line"] for h in new_hits[:5]],
            "fps": [h["fingerprint"] for h in new_hits[:8]],
        })

    window_cutoff = now - args.window_min * 60
    events = [e for e in events if int(e.get("ts", 0)) >= window_cutoff]

    critical_events = [e for e in events if e.get("severity") == "critical"]
    warn_events = [e for e in events if e.get("severity") == "warn"]

    alert = len(events) >= args.threshold or len(critical_events) >= 1
    severity = "critical" if critical_events else ("warn" if warn_events else "ok")

    out = {
        "ok": not alert,
        "alert": alert,
        "severity": severity,
        "recent_event_count": len(events),
        "recent_critical_count": len(critical_events),
        "recent_warn_count": len(warn_events),
        "window_min": args.window_min,
        "threshold": args.threshold,
        "dedupe_min": args.dedupe_min,
        "log": str(log_path) if log_path else None,
        "new_hit_count": len(new_hits),
        "latest_samples": [h["line"] for h in new_hits[:8]],
        "rolling": roll_info,
    }

    if alert:
        out["forensics"] = write_forensics(
            log_path=log_path,
            lines=lines,
            payload=out,
            out_dir=Path(args.forensic_dir),
        )

    recovery = maybe_recover(args, st, now, out, alert=alert)
    out["recovery"] = recovery

    st["events"] = events
    st["seen"] = seen
    st["last"] = out

    notify = {"attempted": False, "ok": None, "result": ""}
    if alert and args.notify_cmd.strip():
        notify["attempted"] = True
        ok, rc, msg = run_cmd(
            args.notify_cmd.strip(),
            env_extra={"GATEWAY_GUARD_ALERT_JSON": json.dumps(out, ensure_ascii=False)},
            timeout=25,
        )
        notify["ok"] = ok
        notify["result"] = f"rc={rc} {msg[:400]}"
        out["notify"] = notify

    save_state(state_path, st)

    print(json.dumps(out, ensure_ascii=False, indent=2))
    raise SystemExit(2 if alert else 0)


if __name__ == "__main__":
    main()
