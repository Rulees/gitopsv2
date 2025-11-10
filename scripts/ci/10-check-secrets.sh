#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов"

# Determine the target branch to compare against.
# Use the MR target branch if available, otherwise fall back to the default branch.
TARGET_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-$CI_DEFAULT_BRANCH}"

echo "🎯 Comparing against target branch: $TARGET_BRANCH"

# Ensure we have the latest data for the remote branches.
git fetch origin

# Find the common ancestor between the current commit and the target branch.
# This is the most reliable way to find the "fork point" of a feature branch.
MERGE_BASE=$(git merge-base "origin/$TARGET_BRANCH" "$CI_COMMIT_SHA")

echo "🔍 Found merge base commit: $MERGE_BASE"

# Get the list of modified files between the merge base and the current commit.
FILES=$(git diff --name-only "$MERGE_BASE" "$CI_COMMIT_SHA" -- | grep -E '^secrets/|scripts/send_vars_to_gitlab.sh' || true)

echo "📄 Checking the following modified secret files:"
echo "$FILES"

if [ -z "$FILES" ]; then
    echo "✅ No secrets modified. Skipping check."
    exit 0
fi

has_errors=0

for file in $FILES; do
  [[ ! -f "$file" || "$file" == *.gitkeep || "$(basename "$file")" == "README.md" ]] && continue

  status=$(sops filestatus "$file" 2>/dev/null || echo '{"encrypted":false}')
  [[ "$(echo "$status" | jq -r '.encrypted')" != "true" ]] && {
    echo "❌ ERROR: $file is NOT encrypted!"
    has_errors=1
  }
done

if (( has_errors == 0 )); then
    echo "✅ All modified secrets are correctly encrypted."
else
    echo "🛑 CRITICAL: Unencrypted secrets found! The pipeline will fail."
  exit 1
fi
