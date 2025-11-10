#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов с исключениями"

# Determine the target branch to compare against.
# Use the MR target branch if available, otherwise fall back to the default branch.
SOURCE_BRANCH="$CI_COMMIT_BRANCH"
TARGET_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-$CI_DEFAULT_BRANCH}"

echo "↔️  Comparing source branch: '$CI_COMMIT_BRANCH' against target branch: '$TARGET_BRANCH'"

# Ensure we have the latest data for the remote branches.
git fetch origin

# Find the common ancestor between the current commit and the target branch.
MERGE_BASE=$(git merge-base "origin/$TARGET_BRANCH" "$CI_COMMIT_SHA")

echo "🔍 Found merge base commit: $MERGE_BASE"

# Get the list of modified files, then filter out the exceptions.
FILES_TO_CHECK=$(git diff --name-only "$MERGE_BASE" "$CI_COMMIT_SHA" -- \
  | grep -E '^secrets/|scripts/send_vars_to_gitlab.sh' \
  | grep -vE '(\.gitkeep$|README\.md$|^secrets/not_secrets/)' \
  || true)

if [ -z "$FILES_TO_CHECK" ]; then
    echo "✅ No secrets modified that require encryption. Skipping check."
    exit 0
fi

has_errors=0
for file in $FILES_TO_CHECK; do
  [[ ! -f "$file" ]] && continue

  status=$(sops filestatus "$file" 2>/dev/null || echo '{"encrypted":false}')
  [[ "$(echo "$status" | jq -r '.encrypted')" != "true" ]] && {
    echo "❌ ERROR: $file is NOT encrypted!"
    has_errors=1
  }
done

if (( has_errors == 0 )); then
    echo "✅ All modified secrets are correctly encrypted."
else
    echo "🛑 CRITICAL: Unencrypted secrets found! Pipeline failed."
  exit 1
fi
