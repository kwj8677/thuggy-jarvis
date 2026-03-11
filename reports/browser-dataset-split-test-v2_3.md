# Browser Dataset Split Test v2.1

- generated_at: 2026-03-11 10:17:18 KST
- dataset: browser-datasets-v2.json
- policy: browser-relayless-pipeline-v1.json

## operational
- runs: 15
- success: 13
- fail: 2
- success_rate: 86.67%
- retry_count: 1
- retry_recovery_rate: 0.00%
- avg_ms: 1011
- api_calls_total: 16
- api_calls_breakdown: {'primary': 16, 'subagent': 0, 'fallback': 0}
- buckets: {'OK': 13, 'HTTP_429': 1, 'HTTP_4XX': 1}

## resilience
- runs: 15
- success: 2
- fail: 13
- success_rate: 13.33%
- retry_count: 11
- retry_recovery_rate: 0.00%
- avg_ms: 2891
- api_calls_total: 26
- api_calls_breakdown: {'primary': 26, 'subagent': 0, 'fallback': 0}
- buckets: {'DNS_ENOTFOUND': 2, 'NETWORK_OR_FETCH': 5, 'HTTP_429': 1, 'HTTP_5XX': 4, 'OK': 2, 'TIMEOUT': 1}
