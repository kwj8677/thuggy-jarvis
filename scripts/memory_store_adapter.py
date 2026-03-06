#!/usr/bin/env python3
import json
from pathlib import Path


class JsonlMemoryStoreAdapter:
    def __init__(self, path: str):
        self.path = Path(path)

    def load(self):
        arr = []
        if not self.path.exists():
            return arr
        for ln in self.path.read_text(encoding='utf-8', errors='replace').splitlines():
            ln = ln.strip()
            if not ln:
                continue
            try:
                arr.append(json.loads(ln))
            except Exception:
                pass
        return arr

    def append(self, item: dict):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.path.open('a', encoding='utf-8') as f:
            f.write(json.dumps(item, ensure_ascii=False) + '\n')

    def save_all(self, items):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.path.open('w', encoding='utf-8') as f:
            for it in items:
                f.write(json.dumps(it, ensure_ascii=False) + '\n')
