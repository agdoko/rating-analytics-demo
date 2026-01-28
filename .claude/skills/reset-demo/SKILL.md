---
name: reset-demo
description: Reset the demo to a clean state between runs
disable-model-invocation: true
allowed-tools: Bash
---

Reset the demo to a clean state for a fresh run.

## Steps
1. Run `./scripts/reset_demo.sh` from the project root
2. Verify the reset by checking:
   - `dbt/models/marts/` contains only `.gitkeep`
   - `rating_service/tests/` contains only `__init__.py`
   - On `main` branch
3. Report what was cleared
