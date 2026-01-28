# Rating Analytics — Specialty Insurance Platform

A unified demo project showcasing Claude Code's platform features through a specialty insurance rating and analytics codebase. Designed for ~60 minute enablement sessions.

## Demo Overview

| # | Demo | ~Duration | Features Showcased |
|---|------|-----------|-------------------|
| 1 | Codebase Exploration | 3 min | Quick architecture overview, no-setup onboarding |
| 2 | dbt Model + Hooks Deep Dive | 10 min | Skills (`/create-dbt-model`), CLAUDE.md, Hooks (SQL lint + security) |
| 3 | Test Generation | 7 min | Subagents (3 parallel: unit, integration, dbt) |
| 4 | PR Review | 8 min | Plugins (team-code-review), GitHub Actions (live) |

## Project Structure

```
rating-analytics/
├── CLAUDE.md                          # Project conventions (dbt + Python)
├── DEMO_GUIDE.md                      # Full scripted walkthrough for all 4 demos
├── .claude/
│   ├── skills/create-dbt-model/       # /create-dbt-model skill
│   ├── agents/                        # Subagents: unit-tester, integration-tester, dbt-tester
│   ├── security/SECURITY_POLICY.md    # Security policy (referenced from CLAUDE.md)
│   └── settings.json                  # Hooks: PostToolUse sqlfluff lint + security check
├── .github/workflows/claude-review.yml # GH Action: @claude PR review
├── dbt/
│   ├── models/staging/                # stg_policies, stg_claims
│   ├── models/marts/                  # Empty — generated during demo 2
│   └── raw_queries/                   # Raw SQL to migrate (loss_ratio, exposure)
├── rating_service/
│   ├── app/                           # FastAPI service (pricing, risk, models)
│   └── tests/                         # Empty — generated during demo 3
├── plugin/                            # team-code-review plugin
│   ├── .claude-plugin/plugin.json
│   └── skills/review-pr/SKILL.md
└── scripts/
    ├── reset_demo.sh                  # Reset to clean state between runs
    ├── setup_branches.sh              # Create feature branch with bugs for demo 4
    ├── lint_sql.sh                    # Hook script for sqlfluff validation
    └── security_check.sh             # Hook script for Python security checks
```

## Prerequisites

- Claude Code CLI installed and authenticated
- Python 3.11+
- sqlfluff (`pip install sqlfluff`) for hook demo
- Git for PR review
- GitHub repo with Claude App + ANTHROPIC_API_KEY secret (for live PR review demo)
- **Enterprise customers:** API key generation for CI/CD is available via Service Keys (Early Access). Contact your account team for access.

## Quick Start

```bash
cd rating-analytics
claude
```

Then follow the prompts in [DEMO_GUIDE.md](DEMO_GUIDE.md).

## Setup for PR Review Demo

1. Create a GitHub repo on your personal account (e.g., `your-username/rating-analytics-demo`)
2. Install the Claude GitHub App on the repo
3. Add `ANTHROPIC_API_KEY` to repo secrets
4. Push the project to main
5. Run `./scripts/setup_branches.sh` to create the feature branch with planted bugs
6. Create a PR from `feature/add-aviation-lob` to `main`

## Reset Between Runs

```bash
./scripts/reset_demo.sh
```

This removes generated files (mart models, test files) and resets git state.

## Storytelling Arc

1. **Explore** — "You just joined the team, no docs. Claude understands the codebase instantly."
2. **Generate** — "The actuarial team needs a loss ratio report in dbt. A skill encodes conventions."
3. **Test** — "Zero tests, shipped under pressure. Parallel subagents generate comprehensive tests."
4. **Review** — "A teammate's PR has bugs in mechanical changes. Claude catches them in CI."
