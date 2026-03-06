#!/usr/bin/env python3
import json
import subprocess
import time


def ps(cmd: str):
    p = subprocess.run([
        'powershell.exe', '-NoProfile', '-Command', cmd
    ], capture_output=True, text=True)
    return p.returncode, (p.stdout or '').strip(), (p.stderr or '').strip()


def visible_chrome_count():
    rc, out, err = ps("(Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }).Count")
    if rc != 0:
        return 0
    try:
        return int(out.splitlines()[-1]) if out else 0
    except Exception:
        return 0


def main():
    before = visible_chrome_count()

    ps("Start-Process chrome.exe 'about:blank'")

    ok = False
    after = before
    for _ in range(15):
        time.sleep(1)
        after = visible_chrome_count()
        if after >= max(1, before):
            ok = True
            break

    # cleanup one blank tab/window best-effort
    ps("$p=Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq 'about:blank' -or $_.MainWindowTitle -eq '새 탭' -or $_.MainWindowTitle -eq 'New Tab' } | Select-Object -First 1; if($p){$p.CloseMainWindow() | Out-Null}")

    print(json.dumps({
        'ok': ok,
        'before_visible': before,
        'after_visible': after
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
