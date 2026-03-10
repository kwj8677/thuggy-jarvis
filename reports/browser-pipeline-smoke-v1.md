# Browser Relay-less Pipeline v1 — Smoke Report

- runs: 3
- success: 2
- fail: 1
- success_rate: 66.67%

## Cases
1. `https://docs.openclaw.ai` -> OK
2. `https://github.com/openclaw/openclaw` -> OK
3. `https://example.com` -> FAILED (`fetch failed`)

## Summary
스모크는 부분 성공(2/3). 현재 quality gate(90%) 미달.

## Immediate fix direction
- fetch 실패 시 1회 재시도 정책 적용
- 대체 URL fallback 목록 적용
- 실패 케이스 분류(`NETWORK`, `DNS`, `HTTP`) 추가
