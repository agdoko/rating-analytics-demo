# Demo Guide — Rating Analytics

Scripted walkthrough for all 4 demos. ~30 minutes of live demo.

**Target audience:** Engineering teams evaluating Claude Code (201-level — skip basics, focus on platform features).

---

## Pre-Demo Checklist

- [ ] Claude Code CLI installed and authenticated
- [ ] Python 3.11+ with `pip install -r requirements.txt`
- [ ] sqlfluff installed (`pip install sqlfluff`)
- [ ] Plugin installed: `claude plugin add ./plugin`
- [ ] Terminal font size increased for screen sharing
- [ ] Run `/reset-demo` to ensure clean state
- [ ] (Demo 4) PR open on GitHub from `feature/add-aviation-lob` → `main`
- [ ] (Demo 4) `ANTHROPIC_API_KEY` secret set on GitHub repo
- [ ] Close any windows showing internal repos/Slack

---

## Demo 1: Codebase Exploration (~3 min)

> "Day one on a new team, no docs. Claude understands the full codebase cold."

```bash
claude
```

```
Explain the architecture of this project. What are the main components and how do they relate?
```

**Key point:** Claude reads CLAUDE.md, dbt_project.yml, Python modules — builds a holistic picture with zero setup.

**Fallback:** If slow, interrupt and summarize yourself. This demo is just a warm-up.

> **Transition:** "Now let's see it generate production-quality code that follows your team's conventions."

---

## Demo 2: dbt Model + Hooks Deep Dive (~10 min)

> "The actuarial team needs a loss ratio report. A Skill encodes your team's conventions."

### Show the raw SQL

```
Show me what's in dbt/raw_queries/loss_ratio_report.sql
```

Point out: hardcoded tables, no CTEs, no ref() — typical analyst SQL.

### Invoke the Skill

```
/create-dbt-model dbt/raw_queries/loss_ratio_report.sql
```

**Watch for:**
1. Claude reads CLAUDE.md conventions and existing staging models
2. Generates `dbt/models/marts/mart_finance_loss_ratio.sql` with proper CTEs
3. Creates `schema.yml` with tests
4. **The sqlfluff hook fires** — PostToolUse lints the SQL automatically
5. If lint issues found, Claude auto-fixes

**Key point:** "Write code → automated check → fix. No manual intervention."

**Fallback:** If hook doesn't fire, show the skill file (`.claude/skills/create-dbt-model/SKILL.md`) and explain the hook definition.

### (Optional) Second migration

```
Now also migrate dbt/raw_queries/exposure_concentration.sql
```

Shows consistency — same skill, same conventions.

### Hooks Deep Dive

> "Hooks are the most underrated feature. The agent is creative, the hooks are the guardrails."
>
> Three types: **PreToolUse** (before action), **PostToolUse** (after action), **PreCommit** (before commit).
>
> Two hooks in this demo at different scopes:
> - **Skill-level:** sqlfluff lint — defined in the skill's YAML, fires only during `/create-dbt-model`
> - **Global (settings.json):** security scan — fires on all Python file writes
>
> Each is a bash script. Simple, deterministic, version-controlled.

### Feature Summary

> Three features working together:
> 1. **CLAUDE.md** — conventions defined once
> 2. **Skills** — multi-step workflows anyone can invoke
> 3. **Hooks** — automated quality gates after every write

> **Transition:** "Rating service has zero tests. Let's fix that with parallel subagents."

---

## Demo 3: Test Generation with Subagents (~7 min)

> "Zero tests, shipped under pressure. Three specialized subagents generate comprehensive tests concurrently."

### Generate tests

```
Generate comprehensive tests for the rating service. Use the unit-tester, integration-tester, and dbt-tester subagents to parallelize the work.
```

**Watch for:** 3 subagents running concurrently — unit (pytest), integration (FastAPI/httpx), dbt (schema.yml).

**While they run:** "Each subagent has its own context window — like three junior engineers each focused on their specialty."

### Run the tests

```
Run the Python tests and show me results
```

Tests should pass on first generation.

**Key point:** "Not trivial tests — boundary conditions, error cases, business logic."

**Fallback:** If subagents are slow, show an agent definition (`.claude/agents/unit-tester.md`) while waiting. If tests fail, fix one live — shows the iterative loop.

> **Transition:** "A teammate's PR has subtle bugs hiding in mechanical changes. Let's see Claude catch them."

---

## Demo 4: PR Review — Plugin + GitHub Action (~8 min)

> "A PR adds aviation as a new line of business. Mostly mechanical changes — but three subtle bugs are hiding in the diff."

### Show the plugin structure

```
Show me the plugin directory structure
```

**Key point:** Plugins bundle skills for team-wide distribution. Install with `claude plugin add ./plugin` or point to a git repo.

### Run the review locally

```
/team-code-review:review-pr
```

**Expected findings (3 planted bugs):**
1. **Off-by-one** in `risk.py`: `claims_count < 2` should be `<= 2`
2. **Wrong variable** in `pricing.py`: `deductible/deductible` instead of `deductible/coverage_amount` (always 1.0 — gives everyone full discount)
3. **Missing null check** in `pricing.py`: `request.region.lower()` crashes when region is None

**Key point:** "The deductible bug passes syntax checks, type checks, but costs real money in production."

### Show the GitHub Action result

Switch to browser — show PR on GitHub. Claude's review should already be posted (triggered by the `synchronize` event or `@claude` comment).

If no review yet, comment `@claude review this PR` on the PR and wait, or show the workflow YAML:

```
Show me .github/workflows/claude-review.yml
```

**Key point:** "Same review quality in CI. The workflow uses the same conventions from CLAUDE.md."

**Fallback:** If Action hasn't run, show the workflow file and narrate. The local review is the primary demo — CI is the "and it also runs in your pipeline" bonus.

---

## Closing (~2 min)

| Feature | Where We Saw It |
|---------|----------------|
| **CLAUDE.md** | Conventions read during model generation, code review |
| **Skills** | `/create-dbt-model`, `/reset-demo` |
| **Hooks** | Skill-level (sqlfluff) + global (security check) |
| **Subagents** | 3 parallel test generators |
| **Plugins** | team-code-review for team distribution |
| **GitHub Actions** | PR review in CI |

> Three takeaways:
> 1. **Conventions encoded once, enforced everywhere** — CLAUDE.md + Skills + Hooks
> 2. **Determinism in agentic workflows** — Hooks are the guardrails
> 3. **Same skills, local and CI** — Plugins + GitHub Actions close the loop
