#!/bin/bash
# Reset the demo to a clean state between runs.
# Removes generated files and resets git state.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Resetting demo state..."

# Remove generated dbt mart models (generated during demo 2)
echo "  Clearing dbt/models/marts/..."
find "$PROJECT_DIR/dbt/models/marts" -type f ! -name '.gitkeep' -delete 2>/dev/null || true

# Remove generated test files (generated during demo 3)
echo "  Clearing rating_service/tests/..."
find "$PROJECT_DIR/rating_service/tests" -type f ! -name '__init__.py' -delete 2>/dev/null || true

# Clean Python cache artifacts
echo "  Cleaning cache artifacts..."
find "$PROJECT_DIR" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
find "$PROJECT_DIR" -type d -name '.pytest_cache' -exec rm -rf {} + 2>/dev/null || true

# Reset git state
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "  Resetting git state..."
    cd "$PROJECT_DIR"
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
    git branch -D feature/add-aviation-lob 2>/dev/null || true
    git checkout -- . 2>/dev/null || true
    git clean -fd 2>/dev/null || true
fi

echo "Demo reset complete."
