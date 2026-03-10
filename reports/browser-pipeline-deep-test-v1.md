# Browser Relay-less Pipeline v1 — Deep Test Report

- runs: 10
- success: 7
- fail: 3
- success_rate: 70%
- quality_gate(>=90%): FAIL

## Failure buckets
- NETWORK_OR_FETCH: 1 (`https://example.com` fetch failed)
- BLOCKED_SPECIAL_IP: 1 (`https://httpstat.us/503` blocked by fetch guard)
- DNS_ENOTFOUND: 1 (`https://nonexistent-openclaw-test-abc123.example`)

## What worked
- Normal docs/repo pages: stable
- Redirect case: stable (`httpbin /redirect`)
- Delay case: stable (`httpbin /delay/2`)

## Meta analysis
- 현재 파이프라인은 일반 케이스엔 안정적이지만, 실패 케이스 분류/재시도 전략이 부족함.
- 품질 게이트 90%를 맞추려면 실패 버킷 기반 처리 정책이 필요.

## Next actions
1. 실패 버킷별 정책 추가 (`NETWORK`, `DNS`, `BLOCKED`, `HTTP`)
2. `NETWORK`만 1회 재시도 허용
3. 도메인 화이트리스트/테스트셋 조정
4. 동일 조건으로 10회 재검증
