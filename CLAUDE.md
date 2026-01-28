# Rating Analytics — Specialty Insurance Platform

## Project Context & Demo Goals

This is a unified demo project for a 60-minute Claude Code enablement session. It's themed around a
**generic specialty insurer** — fully anonymized, reusable by any Anthropic SE. The demo repo lives
on a **personal GitHub account** (safe to screen-share with customers).

### Demo Structure (4 sections)

All demos work around this same codebase:

| # | Demo | ~Duration | Features Showcased |
|---|------|-----------|-------------------|
| 1 | Codebase Exploration | 3 min | Quick architecture overview, no-setup onboarding |
| 2 | dbt Model + Hooks Deep Dive | 10 min | Skills (`/create-dbt-model`), CLAUDE.md, Hooks (SQL lint + security) |
| 3 | Test Generation | 7 min | Subagents (3 parallel: unit, integration, dbt) |
| 4 | PR Review | 8 min | Plugins (team-code-review), GitHub Actions (live) |

### Storytelling Arc

1. **Explore** — "You just joined the team, no docs. Claude understands the codebase instantly."
2. **Generate** — "The actuarial team needs a loss ratio report in dbt. A skill encodes conventions."
3. **Test** — "Zero tests, shipped under pressure. Parallel subagents generate comprehensive tests."
4. **Review** — "A teammate's PR has bugs in mechanical changes. Claude catches them in CI."

### Key Design Decisions

- Unified theme: all demos share the same codebase
- Skills over raw prompts: `/create-dbt-model` for repeatable dbt generation
- Hooks: PostToolUse runs sqlfluff on generated SQL (automated feedback loop)
- Subagents: unit-tester, integration-tester, dbt-tester run concurrently
- Plugin: review skill bundled for team-wide installation
- Live GitHub Action: PR auto-reviewed by Claude

### Working Notes

- Reset between demo runs: `./scripts/reset_demo.sh`
- Set up PR review branch: `./scripts/setup_branches.sh`
- Feature branch plants 3 bugs: off-by-one, wrong variable, missing null check
- `rating_service/tests/` starts empty — generated live in demo 3
- `dbt/models/marts/` starts empty — generated live in demo 2

### Prerequisites

- Claude Code CLI installed and authenticated
- Python 3.11+
- sqlfluff (`pip install sqlfluff`) for hook demo
- Git for PR review
- GitHub repo with Claude App + ANTHROPIC_API_KEY secret

---

## Project Conventions

### dbt Conventions
- Staging models: `stg_{source_table}`, materialized as views
- Mart models: `mart_{domain}_{entity}`, materialized as tables
- CTE structure: source → renamed → joined → filtered → final
- Use `{{ ref() }}` and `{{ source() }}`, never hardcoded table references
- All PKs: `unique` + `not_null` tests; all FKs: `relationships` test
- Numeric fields: add `dbt_utils.accepted_range` where appropriate
- Every model must have a `schema.yml` entry with column descriptions
- SQL style: lowercase keywords, trailing commas, one column per line

### Security Policy (referenced from .claude/security/SECURITY_POLICY.md)

- All generated code must be scanned for secrets before commit
- No hardcoded credentials, API keys, or connection strings
- SQL injection prevention: always use parameterized queries
- All new endpoints require authentication middleware
- Dependencies must be checked against known vulnerability databases
- See `.claude/security/SECURITY_POLICY.md` for full policy details

### Python Service Conventions
- Use Pydantic v2 models for all request/response schemas
- PolicyType enum: property, liability, marine, cyber
- All monetary values as float, rounded to 2 decimal places
- Minimum premium floor: 500
- Risk grades: low, medium, high, critical
- Use pytest with `@pytest.mark.parametrize` for boundary testing
- FastAPI endpoints return JSON with consistent error format
