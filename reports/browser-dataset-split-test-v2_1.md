# Browser Dataset Split Test v2.1

- generated_at: 2026-03-11 02:15:13 KST
- dataset: browser-datasets-v2.json
- policy: browser-relayless-pipeline-v1.json

## operational
- runs: 15
- success: 13
- fail: 2
- success_rate: 86.67%
- retry_count: 2
- retry_recovery_rate: 0.00%
- avg_ms: 945
- buckets: {'OK': 13, 'HTTP_429': 1, 'NETWORK_OR_FETCH': 1}

## resilience
- runs: 15
- success: 2
- fail: 13
- success_rate: 13.33%
- retry_count: 11
- retry_recovery_rate: 0.00%
- avg_ms: 3046
- buckets: {'DNS_ENOTFOUND': 2, 'NETWORK_OR_FETCH': 5, 'HTTP_429': 1, 'HTTP_5XX': 4, 'OK': 2, 'TIMEOUT': 1}
