# Browser Dataset Split Test v2.1

- generated_at: 2026-03-11 10:25:35 KST
- dataset: browser-datasets-v2_4.json
- policy: browser-relayless-pipeline-v1.json

## operational
- runs: 15
- success: 15
- fail: 0
- success_rate: 100.00%
- retry_count: 0
- retry_recovery_rate: 0.00%
- avg_ms: 1021
- api_calls_total: 15
- api_calls_breakdown: {'primary': 15, 'subagent': 0, 'fallback': 0}
- buckets: {'OK': 15}

## resilience
- runs: 17
- success: 2
- fail: 15
- success_rate: 11.76%
- retry_count: 12
- retry_recovery_rate: 0.00%
- avg_ms: 2633
- api_calls_total: 29
- api_calls_breakdown: {'primary': 29, 'subagent': 0, 'fallback': 0}
- buckets: {'DNS_ENOTFOUND': 2, 'NETWORK_OR_FETCH': 5, 'HTTP_429': 2, 'HTTP_5XX': 4, 'OK': 2, 'TIMEOUT': 1, 'HTTP_4XX': 1}
