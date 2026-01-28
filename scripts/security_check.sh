#!/bin/bash
# PostToolUse hook: check Python files for common security anti-patterns
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check .py files
if [[ "$FILE_PATH" == *.py ]] && [[ "$FILE_PATH" != */tests/* ]] && [[ "$FILE_PATH" != *test_*.py ]] && [[ "$FILE_PATH" != *conftest.py ]]; then
  ISSUES=""

  # Check for hardcoded credentials / API keys / secrets
  CRED_HITS=$(grep -nEi '(password|api_key|secret|token|credentials)\s*=\s*["\x27][^"\x27]+["\x27]' "$FILE_PATH" 2>/dev/null | grep -v '^\s*#')
  if [ -n "$CRED_HITS" ]; then
    ISSUES+="SECURITY: Possible hardcoded credentials found:\n$CRED_HITS\n\n"
  fi

  # Check for raw SQL string interpolation (SQL injection risk)
  SQL_HITS=$(grep -nEi 'f["\x27].*\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)\b' "$FILE_PATH" 2>/dev/null | grep -v '^\s*#')
  if [ -n "$SQL_HITS" ]; then
    ISSUES+="SECURITY: Possible SQL injection risk — use parameterized queries instead of f-strings:\n$SQL_HITS\n\n"
  fi

  if [ -n "$ISSUES" ]; then
    echo -e "Security policy violation in $FILE_PATH:\n$ISSUES" >&2
    echo "See .claude/security/SECURITY_POLICY.md for required patterns." >&2
    exit 2  # Blocks and feeds security issues back to Claude
  fi
fi
exit 0
