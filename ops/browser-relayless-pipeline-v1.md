# Browser Relay-less Pipeline v1

## Goal
Relay 없이도 안정적으로 검색/서핑/수집/요약을 수행하는 브라우징 에이전트 파이프라인.

## Scope
- Non-relay browsing only
- Stable-first execution with bounded retries and stop conditions
- Result evidence required

## Flow
1. Query normalization
2. Source discovery (web search)
3. Source fetch (top-N)
4. Evidence check (content length, status)
5. Summarize + citation
6. Save report

## Guardrails
- single change per cycle
- maxRetry=1
- cooldownSec=30
- no tight polling
- fail-fast on malformed/empty content

## Dataset split (required)
- Operational dataset: normal/production-like URLs only
- Resilience dataset: failure-inducing URLs for bucket verification
- Source file: `ops/browser-datasets-v1.json`

## Error-bucket policy
- `DNS_ENOTFOUND`: retry 0 (fail-fast)
- `BLOCKED_SPECIAL_IP`: retry 0 (fail-fast)
- `CONFIG`: retry 0 (fail-fast)
- `NETWORK_OR_FETCH`: retry 1
- `TIMEOUT`: retry 1
- `HTTP_5XX`: retry 1

## Success criteria
- fetch success rate >= 90%
- no duplicate fetch loops
- report contains source links + short conclusion

## Reporting format
1. 더블체크
2. 결론
3. 냉정한 반론
4. 다음 액션
