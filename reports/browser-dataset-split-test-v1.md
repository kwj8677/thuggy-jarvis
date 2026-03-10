# Browser Dataset Split Test v1

- generated_at: 2026-03-11 01:44:23 KST

## operational
- runs: 10
- success: 9
- fail: 1
- success_rate: 90.00%
- avg_ms: 1021
- buckets: {'OK': 9, 'HTTP_429': 1}

## resilience
- runs: 10
- success: 2
- fail: 8
- success_rate: 20.00%
- avg_ms: 1482
- buckets: {'DNS_ENOTFOUND': 1, 'NETWORK_OR_FETCH': 2, 'HTTP_429': 1, 'HTTP_5XX': 4, 'OK': 2}
