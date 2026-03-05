#!/usr/bin/env python3
import json, glob, os, datetime

LOG_DIR = '/mnt/c/openclaw/logs'
OUT_JSON = '/home/humil/.openclaw/workspace/training-runs/uia-master-dataset.json'
OUT_MD = '/home/humil/.openclaw/workspace/training-runs/uia-master-report.md'

PATTERNS = {
    'session_gate': '*session-gate.json',
    'win_gui_l1_uia': '*win-gui-l1-pipeline-uia.json',
    'chrome_uia': '*chrome-uia-pipeline.json',
    'chrome_verify': '*chrome-l1-verify-uia-report.json',
    'relay_attach': '*relay-attach-uia-report.json',
    'relay_uia': '*relay-uia-pipeline.json',
    'explorer_l2': '*explorer-l2-pipeline-uia.json',
    'settings_l3': '*settings-l3-pipeline-uia.json',
}


def load_json(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return None


def summarize(kind, files):
    ok = fail = 0
    reasons = {}
    latest = None
    latest_ts = None
    for p in files:
        j = load_json(p)
        if not isinstance(j, dict):
            continue
        val = j.get('ok')
        if val is True:
            ok += 1
        elif val is False:
            fail += 1
            r = j.get('reason') or 'unknown'
            reasons[r] = reasons.get(r, 0) + 1
        ts = j.get('timestamp')
        if ts and (latest_ts is None or ts > latest_ts):
            latest_ts = ts
            latest = p
        elif latest is None:
            latest = p
    total = ok + fail
    return {
        'kind': kind,
        'total': total,
        'ok': ok,
        'fail': fail,
        'successRate': round(ok / total, 3) if total else None,
        'topFailureReasons': dict(sorted(reasons.items(), key=lambda x: x[1], reverse=True)[:8]),
        'latestReport': latest,
    }


def main():
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)

    pipeline = {}
    for kind, pat in PATTERNS.items():
        files = sorted(glob.glob(os.path.join(LOG_DIR, pat)))
        pipeline[kind] = summarize(kind, files)

    stable = {}
    for k, v in pipeline.items():
        stable[k] = bool(v['successRate'] is not None and v['successRate'] >= 0.9 and v['total'] >= 10)

    out = {
        'generatedAt': datetime.datetime.now().isoformat(),
        'singleSourceOfTruth': True,
        'paths': {
            'logs': LOG_DIR,
            'dataset': OUT_JSON,
            'report': OUT_MD,
        },
        'pipelines': pipeline,
        'stable': stable,
        'rules': {
            'promotion': 'successRate>=0.9 and total>=10',
            'gateFirst': True,
            'uiaFirst': True,
            'evidenceRequired': True,
        }
    }

    with open(OUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    lines = []
    lines.append('# UIA Master Report')
    lines.append('')
    lines.append(f"Generated: {out['generatedAt']}")
    lines.append('')
    lines.append('## Pipeline Summary')
    for k, v in pipeline.items():
        lines.append(f"- {k}: ok {v['ok']}/{v['total']} (rate={v['successRate']}) stable={stable[k]}")
        if v['topFailureReasons']:
            lines.append(f"  - top failures: {v['topFailureReasons']}")
    lines.append('')
    lines.append('## Rule')
    lines.append('- promotion: successRate>=0.9 and total>=10')

    with open(OUT_MD, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

    print(OUT_JSON)
    print(OUT_MD)


if __name__ == '__main__':
    main()
