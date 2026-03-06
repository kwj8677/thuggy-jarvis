# AgentBench-lite Bridge (Local)

This is a lightweight bridge inspired by AgentBench dimensions, adapted for local OpenClaw checks without full Dockerized AgentBench stack.

## Why
Full AgentBench FC setup is heavy (multiple services, high RAM). This bridge gives a fast local signal for:
- policy/tool-use correctness
- memory retrieval correctness
- negative-case robustness

## Files
- `evals/agentbench_lite_cases.json`
- `evals/run_agentbench_lite.py`

## Run
```bash
chmod +x evals/run_agentbench_lite.py
./evals/run_agentbench_lite.py
```

## Coverage
- OS/ops policy tool-use checks
- memory positive retrieval
- memory negative retrieval

## Next step
Integrate 1~2 real AgentBench FC tasks when container resources are available.
