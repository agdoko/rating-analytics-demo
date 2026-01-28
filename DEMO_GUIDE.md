# Demo Guide — Rating Analytics

Full scripted walkthrough for all 4 demos. Each section includes scene-setting, exact prompts to type, expected outputs, talking points, and transitions.

**Total duration:** ~30 minutes of live demo (assumes ~15 min intro/slides, ~15 min Q&A woven in)
**Target audience:** Engineering teams evaluating Claude Code

---

## Pre-Demo Checklist

- [ ] Claude Code CLI installed and authenticated
- [ ] Python 3.11+ available
- [ ] sqlfluff installed (`pip install sqlfluff`)
- [ ] Terminal font size increased for screen sharing
- [ ] `pip install -r requirements.txt` (first time only)
- [ ] `./scripts/reset_demo.sh` run to ensure clean state
- [ ] Plugin installed: `claude plugin add ./plugin` (first time only)
- [ ] (For Demo 4) GitHub repo set up with PR ready
- [ ] Close any windows showing internal repos/Slack/etc.

---

### Audience Calibration

> This guide assumes a **201-level audience** — engineers who have completed foundational Claude Code training and are already using it day-to-day. Power users in attendance may have built plugins, security integrations, or custom workflows.
>
> **Skip basics** (what is Claude Code, how to install, what is a prompt). Jump straight to: "You know how to use Claude Code. Today we're covering how to make your whole team better at it — skills, hooks, subagents, plugins, and CI/CD."
>
> Invite participation: "Some of you have already built impressive things — we'd love to hear about your implementations as we go."

---

## Demo 1: Codebase Exploration (~3 min)

### Scene Setting

> "Quick orientation — imagine day one on a new team, no docs. Let's see Claude understand the full codebase cold."

### Setup

```bash
cd rating-analytics
claude
```

### Prompt 1: Architecture Overview

```
Explain the architecture of this project. What are the main components and how do they relate?
```

**What to expect:** Claude identifies the dbt analytics layer, the Python FastAPI rating service, and explains how they relate.

**Talking points:**
- "Notice Claude reads multiple files — CLAUDE.md, dbt_project.yml, Python modules — to build a holistic picture. No setup, works on any repo."
- "Watch the tool use indicators — you can see Claude exploring the codebase in real time."

### Transition to Demo 2

> "Claude understands the codebase cold — multi-file, multi-layer. Now let's see it generate production-quality code that follows your team's conventions. This is where it gets interesting."

---

## Demo 2: dbt Model Generation + Hooks Deep Dive (~10 min)

### Scene Setting

> "The actuarial team needs a loss ratio report. There's raw SQL they've been running manually — we need to migrate it to a proper dbt model. Instead of writing the model from scratch and hoping you remember all the team conventions, you use a Skill that encodes those conventions."

### Setup

Continue in the same Claude session, or start fresh with `claude`.

### Prompt 1: Show the Raw SQL

```
Show me what's in dbt/raw_queries/loss_ratio_report.sql
```

**What to expect:** Claude displays the raw SQL — hardcoded table references, no CTEs, BigQuery-specific functions.

**Talking points:**
- "This is typical 'analyst SQL' — it works, but it's not dbt-ready. Hardcoded table names, no ref() or source(), no tests."

### Prompt 2: Invoke the Skill

```
/create-dbt-model dbt/raw_queries/loss_ratio_report.sql
```

**What to expect:**
1. The skill fires — you'll see Claude reading CLAUDE.md conventions and existing staging models
2. Claude generates `dbt/models/marts/mart_finance_loss_ratio.sql` with proper CTE structure
3. Claude creates/updates `dbt/models/marts/schema.yml` with column descriptions and tests
4. **The hook fires** — after Claude writes the .sql file, sqlfluff automatically lints it
5. If sqlfluff finds issues, Claude sees the feedback and auto-fixes

**Talking points:**
- "The `/create-dbt-model` skill is defined in `.claude/skills/`. It's a markdown file that encodes your team's process."
- "Notice the skill reads CLAUDE.md for conventions — CTE naming, materialization, test requirements."
- "**Watch the hook** — after the file is written, sqlfluff runs automatically. This is a PostToolUse hook. If there are lint issues, Claude sees them and fixes them in real time."
- "This is the feedback loop: write code → automated check → fix issues. No manual intervention."

### Feature Deep Dive: Show the Skill Definition

If the audience is technical, briefly show the skill file:

```
Show me the file .claude/skills/create-dbt-model/SKILL.md
```

**Talking points:**
- "Skills are just markdown files with a YAML front matter. They're version-controlled."
- "The `hooks` section in the front matter attaches the sqlfluff lint hook."
- "Any engineer on the team can invoke `/create-dbt-model` and get consistent output."

### Prompt 3: Second Migration

```
Now also migrate dbt/raw_queries/exposure_concentration.sql
```

**What to expect:** Same quality output — proper CTEs, ref() usage, schema.yml with tests. Demonstrates consistency.

**Talking points:**
- "Same skill, same conventions, consistent output. This is the power of encoding your team's standards as a skill."
- "Two dbt models migrated in minutes, both following your team's exact conventions."

### Feature Summary

> "Three platform features working together here:
> 1. **CLAUDE.md** defines conventions once — the source of truth
> 2. **Skills** encode multi-step workflows anyone can invoke
> 3. **Hooks** provide automated quality gates after every write
>
> The conventions are defined once and enforced automatically."

### Hooks Deep Dive — Determinism in Agentic Workflows

This is the key talking point for advanced audiences. Spend time here.

> "Hooks are the most underrated Claude Code feature. Here's why: Claude Code is agentic — it makes autonomous decisions about what to do. That's powerful but unpredictable. Hooks add **deterministic checkpoints** into that loop.
>
> Think of it this way: **the agent is creative, the hooks are the guardrails.**
>
> Three hook types to know:
> 1. **PreToolUse** — runs before Claude takes an action (e.g., block writes to certain paths)
> 2. **PostToolUse** — runs after Claude takes an action (e.g., lint, security scan)
> 3. **PreCommit** — runs before any commit (e.g., run pytest, secret detection)
>
> In this demo, we have **two hooks at different scopes**:
> - **Skill-level hook:** `lint_sql.sh` — defined in the skill's YAML frontmatter. Runs sqlfluff only when `/create-dbt-model` is invoked. Scoped to the workflow that needs it.
> - **Global hook (settings.json):** `security_check.sh` — runs on all production Python file writes. Scans for hardcoded credentials and SQL injection patterns.
>
> The skill hook fires now during dbt generation. The security hook fires later when we generate Python code in Demo 3. Claude sees any violations and fixes them in real time.
>
> Notice we also have a **security policy file** at `.claude/security/SECURITY_POLICY.md` — CLAUDE.md references it. This is the composable pattern: your security team maintains the policy, CLAUDE.md references it, and the hook enforces it automatically. You could extend this: a PreCommit hook that runs pytest, a secret detection hook, whatever your team needs.
>
> Each hook is a bash script. They're simple, deterministic, and version-controlled."

**Talking points:**
- "Some of you may have already built something like this — security integrations, custom hooks. We'd love to hear about your implementations."
- "You can chain as many hooks as you need. Each is independent and composable."
- "You could also add a PreCommit hook for pytest — ensures tests pass before any commit goes through."

### Transition to Demo 3

> "We've got a rating service with zero tests — shipped under deadline pressure, as happens. Let's see how Claude generates comprehensive tests using specialized subagents working in parallel."

---

## Demo 3: Test Generation with Subagents (~7 min)

### Scene Setting

> "The rating service calculates insurance premiums. It's in production. It has zero tests. Classic 'we'll add tests later' situation. Let's fix that — but instead of one monolithic test generation pass, we'll use three specialized subagents running concurrently: one for unit tests, one for integration tests, one for dbt tests."

### Setup

Continue in the same session or start fresh with `claude`.

### Prompt 1: Generate Tests

```
Generate comprehensive tests for the rating service. Use the unit-tester, integration-tester, and dbt-tester subagents to parallelize the work.
```

**What to expect:**
1. Claude spawns 3 subagents — you'll see them running concurrently in the terminal
2. **unit-tester**: generates pytest tests for pricing.py and risk.py (parametrized boundary tests, edge cases, all enum variants)
3. **integration-tester**: generates FastAPI tests using httpx AsyncClient (success cases, validation errors, bulk endpoint)
4. **dbt-tester**: generates/updates schema.yml with comprehensive dbt tests (unique, not_null, accepted_range, relationships)
5. Each subagent works independently in its own context

**Talking points:**
- "Three subagents working in parallel — each specialized for its testing domain."
- "The unit-tester knows pytest patterns and parametrize. The integration-tester knows FastAPI test client patterns. The dbt-tester knows schema.yml conventions."
- "Each subagent has its own context window — it doesn't pollute your main conversation."
- "This is like having three junior engineers each focused on their specialty, working simultaneously."

### While Subagents Run

Point out what's happening in the terminal:

- "You can see the three subagents running concurrently — they each have their own progress indicators."
- "They're reading the source code independently, understanding the interfaces, and generating appropriate tests."

### Prompt 2: Run the Tests

```
Run the Python tests and show me results
```

**What to expect:** Claude runs pytest and shows results. Tests should pass.

**Talking points:**
- "Tests pass on first generation. The subagents understood the code well enough to generate valid, passing tests."
- "These aren't trivial tests — they cover boundary conditions, error cases, and business logic."

### Feature Deep Dive: Show Agent Definitions

If the audience is interested:

```
Show me .claude/agents/unit-tester.md
```

**Talking points:**
- "Agent definitions are simple markdown files in `.claude/agents/`."
- "Each defines: name, description, allowed tools, model (sonnet vs haiku), and instructions."
- "Check these into version control — your whole team benefits from the same agent definitions."
- "The dbt-tester uses haiku (faster, cheaper) since its task is simpler. The unit and integration testers use sonnet for more complex code generation."

### Transition to Demo 4

> "We've got a well-tested codebase now. But what about code review? A teammate submitted a PR with what looks like mechanical changes — adding aviation as a new line of business. But there are subtle bugs hiding in the noise. Let's see how Claude catches them, both locally and in CI."

---

## Demo 4: PR Review with Plugin + GitHub Action (~8 min)

### Scene Setting

> "A teammate submitted a PR adding 'aviation' as a new line of business. It touches the pricing engine — mostly mechanical changes like adding enum values and rate tables. But there are three subtle bugs hiding in the diff. These are the kind of bugs that pass syntax checks, pass type checks, but cost money in production."

### Setup

Ensure the PR is created on GitHub (from `feature/add-aviation-lob` to `main`). If not set up yet:

```bash
./scripts/setup_branches.sh
# Then create the PR on GitHub
```

### Prompt 1: Show the Plugin Structure

```
Show me the plugin directory structure
```

**What to expect:** Claude shows the plugin layout: `.claude-plugin/plugin.json`, `skills/review-pr/SKILL.md`.

**Talking points:**
- "This plugin bundles a review skill that your whole team installs. It standardizes how PRs are reviewed."
- "Plugins can include skills, hooks, and agents — they're the distribution mechanism for team conventions."
- "Install with `claude plugin add ./plugin` — or point to a git repo for remote installation."

### Prompt 2: Trigger GitHub Action

Switch to the browser and show the PR on GitHub. Either:

**Option A:** The PR auto-triggered the Claude review (if PR was just opened):
- Show Claude's review comment appearing on the PR

**Option B:** Comment `@claude` on the PR:
- Type `@claude review this PR` in the PR comment box
- Watch for the GitHub Action to trigger and Claude's review to appear

**What to expect:** Claude's review identifies all 3 planted bugs:
1. **Off-by-one** in `risk.py _assess_claims_history`: `claims_count < 2` should be `<= 2`
2. **Wrong variable** in `pricing.py _get_deductible_discount`: `deductible/deductible` instead of `deductible/coverage_amount`
3. **Missing null check** in `pricing.py _determine_exclusions`: `request.region.lower()` crashes when region is None

**Talking points:**
- "Claude found all three bugs — an off-by-one, a wrong variable reference, and a missing null check."
- "The `deductible/deductible` bug is always 1.0 — it passes all syntax and type checks but gives every customer a full discount. That costs real money."
- "The null check bug only crashes in production when a customer doesn't provide a region. Hard to catch in testing."
- "These are exactly the bugs that humans miss in large PRs — they're surrounded by correct mechanical changes."

### Prompt 3 (Fallback): Local Review

If the GitHub Action is slow, run locally:

```
/team-code-review:review-pr
```

**Talking points:**
- "Same skill, same output — whether running in CI or locally."
- "The skill is defined once in the plugin and works in both contexts."

### Feature Summary

> "Two platform features here:
> 1. **Plugins** bundle skills and conventions for team-wide distribution
> 2. **GitHub Actions** run Claude Code in CI — same skills, same CLAUDE.md, same quality
>
> The key insight: Claude catches logic errors, not just syntax. The deductible bug compiles fine, types check fine, but it's mathematically wrong. That's the gap between a linter and an AI code reviewer."

### Enterprise API Key Configuration (address directly if asked)

> "For GitHub Actions, you need an ANTHROPIC_API_KEY configured as a repo secret. On the Enterprise plan, there hasn't historically been a way to generate that key — which is why some teams maintain a separate API plan alongside Enterprise.
>
> There's a new feature called **Service Keys** currently in Early Access that solves this. It lets Enterprise customers generate API keys scoped specifically for CI/CD use cases, including Claude Code in GitHub Actions. Talk to your account team about getting access."

**Note to presenter:** If Service Keys availability has been confirmed end-to-end, deliver this confidently. If still being validated, soften to: "We've identified a path forward called Service Keys that's in Early Access — we're validating the details and will follow up with your team on next steps."

---

## Closing (~2 min)

### Recap the Platform Features

> "Quick recap — four demos, one codebase:"

| Feature | Where We Saw It |
|---------|----------------|
| **CLAUDE.md** | Conventions read during model generation, code review |
| **Skills** | `/create-dbt-model` for repeatable, convention-following code generation |
| **Hooks** | Skill-level (sqlfluff in dbt skill) + global (security check in settings.json) |
| **Security Policy** | Composable CLAUDE.md referencing `.claude/security/SECURITY_POLICY.md` |
| **Subagents** | 3 parallel test generators, each specialized |
| **Plugins** | team-code-review bundled for team distribution |
| **GitHub Actions** | Live PR review in CI, same skills as local |

### Key Takeaways

> "Three things to take away:
> 1. **Conventions encoded once, enforced everywhere** — CLAUDE.md + Skills + Hooks
> 2. **Determinism in agentic workflows** — Hooks are the guardrails, the agent is creative
> 3. **Same skills, local and CI** — Plugins + GitHub Actions close the loop"

### Future Sessions — Power User Spotlight

> "What we showed today is a starting point. Some of you in this room have already built impressive things — security integrations, custom plugins, advanced workflows.
>
> We'd love to feature your stories in a follow-up session. If you've built something you're proud of with Claude Code, let your team lead know — or reach out to us directly.
>
> The best enablement comes from your own team showing what works in your codebase, with your conventions, solving your problems."

### Q&A

> "This all works on your existing repos today. No special project structure required — just add a CLAUDE.md and start from there. Happy to take questions or dive deeper into any of these features."
