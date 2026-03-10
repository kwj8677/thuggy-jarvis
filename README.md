# thuggy-jarvis

Operational OpenClaw workspace focused on reliability and long-term memory quality.

## Memory System (Implemented)
- Structured memory capture/recall/curation/composition
- Confidence feedback loop
- Weekly rollup + metrics reporting
- Benchmark-gated autotune guard

See: [BENCHMARK.md](./BENCHMARK.md)

## Quick Commands
```bash
./scripts/memory_pipeline.sh
./scripts/memory_benchmark.py
./scripts/memory_autotune_guard.py
```

## Runtime Control Policy
- API efficiency policy: `ops/api-efficiency-policy.json`
- Engineering routine (human-readable): `ops/engineering-routine.md`
- Engineering routine (machine profile): `ops/engineering-routine.json`
- Heartbeat throttle rules: `HEARTBEAT.md`
- User preference source: `USER.md`

Use these as the control baseline before making model/config changes.
