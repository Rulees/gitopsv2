#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов"

# Determine the target branch to compare against.
# Use the MR target branch if available, otherwise fall back to the default branch from CI variables.
TARGET_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-$CI_DEFAULT_BRANCH}"

# Ensure we have the latest information for the target branch.
git fetch origin "$TARGET_BRANCH"

# If in a merge request context, simulate the merge to get the most accurate diff.
if [[ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" ]]; then
  git merge --no-commit --no-ff "origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" || true
fi

# Find all changed files by comparing the current commit against the merge base of the target branch.
# This correctly identifies all changes in the feature branch.
MERGE_BASE=$(git merge-base "origin/$TARGET_BRANCH" "$CI_COMMIT_SHA")
FILES=$(git diff --name-only "$MERGE_BASE" "$CI_COMMIT_SHA" | grep -E '^secrets/|scripts/send_vars_to_gitlab.sh' || true)

echo "🎯 Comparing against branch: $TARGET_BRANCH"
echo "🔍 Found merge base: $MERGE_BASE"
echo "📄 Checking the following files for encryption:"
echo "$FILES"

if [ -z "$FILES" ]; then
    echo "✅ No secrets modified in this push. Skipping check."
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
