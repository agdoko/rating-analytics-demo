---
name: review-pr
description: Review PR changes for correctness, security, and project conventions
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash
---

Review the current PR (feature branch vs main). Focus on:

1. **Correctness bugs**: off-by-one errors, wrong variables, division errors
2. **Null safety**: missing None/null checks before method calls
3. **Business logic**: rating factors, premium calculations, risk scoring
4. **dbt conventions**: proper ref() usage, CTE structure, test coverage
5. **Security**: no hardcoded secrets, proper input validation

Output a structured review:
- 🔴 Critical (must fix before merge)
- 🟡 Warning (should fix)
- 🟢 Suggestion (nice to have)

Include file:line references and suggested fixes for each issue.
