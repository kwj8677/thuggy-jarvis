# Evals (OpenAI-evals style dataset bridge)

This folder contains a lightweight eval dataset/runner bridge so the current memory benchmark can be mapped to a standard eval workflow.

## Files
- `memory_eval_dataset.jsonl` — case dataset (input/ideal/meta)
- `run_memory_eval.py` — runner that executes current recall engine and grades pass/fail

## Run
```bash
chmod +x evals/run_memory_eval.py
./evals/run_memory_eval.py
```

## Notes
- `ideal=NO_MEMORY` means negative case (should return 0 memory items)
- `ideal=MEMORY_RELEVANT` means positive case (should retrieve relevant memory)
- This is a bridge layer; can be migrated to full `openai/evals` registry format later.
