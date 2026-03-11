# Queue Canary Simulation v1

## Baseline
- duplicate_delivery_rate: 0.0347
- queue_wait_ms_p95: 106000
- out_of_order_rate: 0.0

## Ingress shaped (min gap=1s)
- duplicate_delivery_rate: 0.0457
- queue_wait_ms_p95: 39000
- out_of_order_rate: 0.0

## Ingress shaped + tuned dedupe (no time bucket)
- duplicate_delivery_rate: 0.0
- queue_wait_ms_p95: 26000
- out_of_order_rate: 0.0

## Quick read
- p95 delta (shaped-baseline): -67000 ms
- duplicate delta (shaped-baseline): 0.011
- p95 delta (tuned-baseline): -80000 ms
- duplicate delta (tuned-baseline): -0.0347
