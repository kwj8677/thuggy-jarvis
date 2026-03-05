#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import time
from pywinauto import Desktop
import pyautogui

KEYWORDS = [
    '허용', '항상 허용', '이번만 허용', '확인',
    'allow', 'always allow', 'allow this time', 'on this site', 'ok'
]


def click_rect(rect):
    x = (rect.left + rect.right) // 2
    y = (rect.top + rect.bottom) // 2
    pyautogui.click(x, y)
    return x, y


def try_once():
    desktop = Desktop(backend='uia')
    wins = [w for w in desktop.windows() if w.window_text()]

    # 1) targeted keyword buttons first
    for w in wins:
        try:
            title = (w.window_text() or '').lower()
            likely = any(k in title for k in ['chrome', '권한', 'permission', '네이버'])
            for c in w.descendants(control_type='Button'):
                try:
                    txt = (c.window_text() or '').strip().lower()
                    if txt and any(k in txt for k in KEYWORDS):
                        rect = c.rectangle()
                        if rect.width() > 8 and rect.height() > 8:
                            x, y = click_rect(rect)
                            print(f'keyword_click:{txt}@{x},{y}')
                            return 0
                except Exception:
                    pass
            if likely:
                # likely popup: click first enabled button
                btns = [b for b in w.descendants(control_type='Button')]
                for b in btns:
                    try:
                        if not b.is_enabled():
                            continue
                        rect = b.rectangle()
                        if rect.width() > 10 and rect.height() > 10:
                            x, y = click_rect(rect)
                            print(f'likely_first_button@{x},{y}')
                            return 0
                    except Exception:
                        pass
        except Exception:
            pass

    # 2) global fallback: first enabled visible button across top windows
    for w in wins[:12]:
        try:
            for b in w.descendants(control_type='Button'):
                try:
                    if not b.is_enabled():
                        continue
                    rect = b.rectangle()
                    if rect.width() > 12 and rect.height() > 12:
                        x, y = click_rect(rect)
                        print(f'global_first_button@{x},{y}')
                        return 0
                except Exception:
                    pass
        except Exception:
            pass

    return 1


if __name__ == '__main__':
    # aggressive short burst: catch transient popup
    for _ in range(6):
        rc = try_once()
        if rc == 0:
            sys.exit(0)
        time.sleep(0.35)
    print('no_button_found')
    sys.exit(1)
