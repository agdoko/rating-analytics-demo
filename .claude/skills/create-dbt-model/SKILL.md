---
name: create-dbt-model
description: Migrate raw SQL to a production dbt model following project conventions
argument-hint: [path-to-raw-sql]
disable-model-invocation: true
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/scripts/lint_sql.sh"
          once: true
---

Migrate the raw SQL query at $ARGUMENTS into a production dbt model.

## Steps
1. Read the raw SQL query file
2. Read CLAUDE.md for project conventions
3. Read existing staging models in dbt/models/staging/ for patterns
4. Create the mart model SQL file in dbt/models/marts/ following CTE conventions
5. Update or create the schema.yml with column descriptions and tests
6. Add appropriate dbt tests (unique, not_null, accepted_range, relationships)

## Naming
- Determine the domain from the query content (finance, underwriting, etc.)
- Name the model: mart_{domain}_{entity}

## Quality
- Replace all hardcoded table references with {{ ref() }} or {{ source() }}
- Ensure CTE naming follows: source, renamed, joined, filtered, final
- Add meaningful column descriptions, not just column names repeated
