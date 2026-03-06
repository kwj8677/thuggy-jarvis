#!/usr/bin/env python3
import argparse
import json
import smtplib
from email.mime.text import MIMEText
from email.header import Header
from pathlib import Path

SECRETS_PATH = Path('/home/humil/.openclaw/workspace/secrets/local-secrets.json')


def load_secrets() -> dict:
    if not SECRETS_PATH.exists():
        return {}
    try:
        return json.loads(SECRETS_PATH.read_text(encoding='utf-8'))
    except Exception:
        return {}


def build_body(payload: dict) -> str:
    lines = []
    lines.append('[OpenClaw Gateway Guard Alert]')
    lines.append('')
    lines.append(f"severity: {payload.get('severity')}")
    lines.append(f"alert: {payload.get('alert')}")
    lines.append(f"recent_event_count: {payload.get('recent_event_count')}")
    lines.append(f"recent_critical_count: {payload.get('recent_critical_count')}")
    lines.append(f"recent_warn_count: {payload.get('recent_warn_count')}")
    lines.append(f"log: {payload.get('log')}")
    rec = payload.get('recovery', {}) or {}
    lines.append('')
    lines.append('[Recovery]')
    lines.append(f"attempted: {rec.get('attempted')}")
    lines.append(f"restart_ok: {rec.get('restart_ok')}")
    lines.append(f"verify_ok: {rec.get('verify_ok')}")
    if rec.get('details'):
        lines.append(f"details: {rec.get('details')}")
    samples = payload.get('latest_samples') or []
    if samples:
        lines.append('')
        lines.append('[Samples]')
        for s in samples[:8]:
            lines.append(f"- {s}")
    lines.append('')
    lines.append('[Raw JSON]')
    lines.append(json.dumps(payload, ensure_ascii=False, indent=2))
    return '\n'.join(lines)


def main():
    ap = argparse.ArgumentParser(description='Send gateway guard alert email via Gmail SMTP')
    ap.add_argument('--test', action='store_true', help='send test message even without alert')
    args = ap.parse_args()

    secrets = load_secrets()
    user = (secrets.get('gmail_imap_user') or '').strip()
    app_pw = (secrets.get('gmail_imap_app_password') or '').strip().replace(' ', '')
    to_addr = (secrets.get('alert_email_to') or user).strip()

    if not user or not app_pw or not to_addr:
        print('MISSING_EMAIL_CONFIG')
        raise SystemExit(1)

    raw = ''
    try:
        import os
        raw = os.environ.get('GATEWAY_GUARD_ALERT_JSON', '')
    except Exception:
        raw = ''

    payload = {}
    if raw:
        try:
            payload = json.loads(raw)
        except Exception:
            payload = {'parse_error': True, 'raw': raw[:2000]}

    if not args.test and payload and not payload.get('alert', False):
        print('NO_ALERT_SKIP')
        return

    if args.test and not payload:
        payload = {
            'alert': True,
            'severity': 'warn',
            'recent_event_count': 1,
            'recent_critical_count': 0,
            'recent_warn_count': 1,
            'log': '/tmp/openclaw/openclaw-YYYY-MM-DD.log',
            'latest_samples': ['test: gateway guard email wiring check'],
            'recovery': {'attempted': False, 'restart_ok': None, 'verify_ok': None, 'details': 'test message'}
        }

    subject = f"[OpenClaw][{payload.get('severity', 'unknown')}] gateway-guard alert"
    body = build_body(payload)

    msg = MIMEText(body, 'plain', 'utf-8')
    msg['Subject'] = Header(subject, 'utf-8')
    msg['From'] = user
    msg['To'] = to_addr

    with smtplib.SMTP('smtp.gmail.com', 587, timeout=25) as s:
        s.ehlo()
        s.starttls()
        s.login(user, app_pw)
        s.sendmail(user, [to_addr], msg.as_string())

    print(f'SENT:{to_addr}')


if __name__ == '__main__':
    main()
