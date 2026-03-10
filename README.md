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
- Instant execution prompt (human-readable): `ops/instant-exec-prompt.md`
- Instant execution prompt (machine profile): `ops/instant-exec-prompt.json`
- macOS-grade control expansion plan (human-readable): `ops/macos-grade-control-expansion-v1.md`
- macOS-grade control expansion plan (machine profile): `ops/macos-grade-control-expansion-v1.json`
- Heartbeat throttle rules: `HEARTBEAT.md`
- User preference source: `USER.md`

Use these as the control baseline before making model/config changes.
