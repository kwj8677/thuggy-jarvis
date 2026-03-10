#!/usr/bin/env python3
import argparse
import json
import time
from collections import Counter
from pathlib import Path

import requests


def classify(status, err):
    if err:
        e = str(err).lower()
        if "enotfound" in e or "name or service not known" in e or "failed to resolve" in e or "nodename nor servname" in e:
            return "DNS_ENOTFOUND"
        if "private/internal/special-use ip" in e or "blocked" in e:
            return "BLOCKED_SPECIAL_IP"
        if "timed out" in e or "timeout" in e:
            return "TIMEOUT"
        return "NETWORK_OR_FETCH"
    if status == 429:
        return "HTTP_429"
    if status is not None and status >= 500:
        return "HTTP_5XX"
    if status is not None and status >= 400:
        return "HTTP_4XX"
    return "OK"


def fetch_once(url, timeout_sec=10):
    t0 = time.time()
    status = None
    err = None
    retry_after = None
    try:
        r = requests.get(url, timeout=timeout_sec, allow_redirects=True, headers={"User-Agent": "Mozilla/5.0"})
        status = r.status_code
        retry_after = r.headers.get("Retry-After")
    except Exception as e:
        err = e
    bucket = classify(status, err)
    ok = bucket == "OK"
    elapsed_ms = int((time.time() - t0) * 1000)
    return ok, status, (str(err) if err else None), bucket, elapsed_ms, retry_after


def run_url(url, policy):
    ok, st, er, b, ms, retry_after = fetch_once(url)
    retries = 0
    recovered = False

    if not ok:
        p = policy.get(b, {})
        retry = int(p.get("retry", 0))
        if retry > 0:
            retries = 1
            sleep_sec = int(p.get("backoffSec", 1))
            if b == "HTTP_429" and p.get("respectRetryAfterHeader", False):
                try:
                    if retry_after:
                        sleep_sec = max(sleep_sec, int(retry_after))
                except Exception:
                    pass
            time.sleep(sleep_sec)
            ok2, st2, er2, b2, ms2, _ = fetch_once(url)
            ok, st, er, b = ok2, st2, er2, b2
            ms += ms2
            recovered = ok2

    return {
        "url": url,
        "ok": ok,
        "status": st,
        "error": er,
        "bucket": b,
        "elapsed_ms": ms,
        "retries": retries,
        "recovered_on_retry": recovered,
    }


def summarize(rows):
    n = len(rows)
    success = sum(1 for r in rows if r["ok"])
    fail = n - success
    retries = sum(r["retries"] for r in rows)
    recoveries = sum(1 for r in rows if r["recovered_on_retry"])
    c = Counter(r["bucket"] for r in rows)
    return {
        "runs": n,
        "success": success,
        "fail": fail,
        "success_rate": round(success / n, 4) if n else 0,
        "avg_ms": int(sum(r["elapsed_ms"] for r in rows) / n) if n else 0,
        "retry_count": retries,
        "retry_recovery_rate": round(recoveries / retries, 4) if retries else 0,
        "bucket_counts": dict(c),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", default="/home/humil/.openclaw/workspace/ops/browser-datasets-v2.json")
    ap.add_argument("--policy", default="/home/humil/.openclaw/workspace/ops/browser-relayless-pipeline-v1.json")
    ap.add_argument("--outPrefix", default="/home/humil/.openclaw/workspace/reports/browser-dataset-split-test-v2_1")
    args = ap.parse_args()

    ds = json.loads(Path(args.dataset).read_text())
    pl = json.loads(Path(args.policy).read_text())
    policy = pl.get("errorPolicy", {})

    op_rows = [run_url(u, policy) for u in ds["datasets"]["operational"]]
    re_rows = [run_url(u, policy) for u in ds["datasets"]["resilience"]]

    out = {
        "generated_at": time.strftime("%Y-%m-%d %H:%M:%S KST", time.localtime()),
        "dataset": Path(args.dataset).name,
        "policy": Path(args.policy).name,
        "operational": {"summary": summarize(op_rows), "cases": op_rows},
        "resilience": {"summary": summarize(re_rows), "cases": re_rows},
    }

    out_json = Path(args.outPrefix + ".json")
    out_md = Path(args.outPrefix + ".md")
    out_json.write_text(json.dumps(out, ensure_ascii=False, indent=2))

    md = []
    md.append("# Browser Dataset Split Test v2.1")
    md.append("")
    md.append(f"- generated_at: {out['generated_at']}")
    md.append(f"- dataset: {out['dataset']}")
    md.append(f"- policy: {out['policy']}")
    for name in ["operational", "resilience"]:
        s = out[name]["summary"]
        md.append("")
        md.append(f"## {name}")
        md.append(f"- runs: {s['runs']}")
        md.append(f"- success: {s['success']}")
        md.append(f"- fail: {s['fail']}")
        md.append(f"- success_rate: {s['success_rate']*100:.2f}%")
        md.append(f"- retry_count: {s['retry_count']}")
        md.append(f"- retry_recovery_rate: {s['retry_recovery_rate']*100:.2f}%")
        md.append(f"- avg_ms: {s['avg_ms']}")
        md.append(f"- buckets: {s['bucket_counts']}")

    out_md.write_text("\n".join(md) + "\n")

    print(out_json)
    print(out_md)
    print("operational", out["operational"]["summary"])
    print("resilience", out["resilience"]["summary"])


if __name__ == "__main__":
    main()
