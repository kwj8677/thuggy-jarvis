# Memory Benchmark Protocol

This repository uses a reproducible benchmark protocol for the OpenClaw memory stack.

## Why
Claims like "better memory" are only useful when they are measurable and reproducible.

## Scope
- Retrieval quality for operational memory items
- False-positive resistance for unrelated queries
- Guarded tuning (benchmark-gated updates)

## Test Assets
- Cases: `scripts/benchmark_cases.json`
- Runner: `scripts/memory_benchmark.py`
- Recall engine: `scripts/memory_recall.py`
- Autotune guard: `scripts/memory_autotune_guard.py`

## How to Run
```bash
./scripts/memory_benchmark.py
./scripts/memory_autotune_guard.py
```

## Pass Criteria (current)
- Benchmark hit rate threshold for autotune guard: **>= 95.0%**
- Includes both:
  - positive retrieval cases (`mode=any`)
  - hard negative cases (`mode=none`, expects `count=0`)

## Reporting Policy
Weekly report includes:
- hit-rate
- re-explain count
- wrong-reference count
- next tuning action

## Current Notes
- Hybrid scoring + rerank + graph expansion enabled
- Source trust weighting enabled
- Drift check and supersede/contradiction tracking enabled

## Limitations
- Current benchmark set is domain-specific
- Not a universal benchmark; expand with external/public cases over time
- Strict filters can trade recall for precision if overtuned
