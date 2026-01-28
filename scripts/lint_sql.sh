#!/bin/bash
# PostToolUse hook: lint SQL files after creation/edit
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only lint .sql files in the dbt directory
if [[ "$FILE_PATH" == *.sql ]] && [[ "$FILE_PATH" == *dbt/models* ]]; then
  if command -v sqlfluff &> /dev/null; then
    RESULT=$(sqlfluff lint "$FILE_PATH" --dialect bigquery 2>&1)
    if [ $? -ne 0 ]; then
      echo "$RESULT" >&2
      exit 2  # Blocks and feeds lint errors back to Claude
    fi
  fi
fi
exit 0
