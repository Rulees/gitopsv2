#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов"

# Detect mode (MR vs push)
IS_MR=false
if [[ -n "${CI_MERGE_REQUEST_IID:-}" ]]; then
  IS_MR=true
fi

FILES=""

if $IS_MR; then
  # Prefer GitLab-provided diff base if available
  if [[ -n "${CI_MERGE_REQUEST_DIFF_BASE_SHA:-}" ]]; then
    BASE="${CI_MERGE_REQUEST_DIFF_BASE_SHA}"
    echo "ℹ️ MR mode. Using CI_MERGE_REQUEST_DIFF_BASE_SHA=${BASE}"
    FILES=$(git diff --name-only "$BASE" "$CI_COMMIT_SHA" | grep -E '^(secrets/|scripts/send_vars_to_gitlab\.sh)$' || true)
  else
    # Fallback: fetch full target branch history and use three-dot
    TARGET="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}"
    echo "ℹ️ MR mode. Fetching full target branch origin/$TARGET"
    git fetch origin "$TARGET" --depth=0
    FILES=$(git diff --name-only "origin/$TARGET...$CI_COMMIT_SHA" | grep -E '^(secrets/|scripts/send_vars_to_gitlab\.sh)$' || true)
  fi
else
  # Push pipeline
  BEFORE="${CI_COMMIT_BEFORE_SHA:-}"
  if [[ "$BEFORE" == "0000000000000000000000000000000000000000" || -z "$BEFORE" ]]; then
    echo "ℹ️ First commit or unknown previous commit. Using single commit file list."
    FILES=$(git show --name-only --pretty=format: "$CI_COMMIT_SHA" | grep -E '^(secrets/|scripts/send_vars_to_gitlab\.sh)$' || true)
  else
    echo "ℹ️ Push mode. Diffing $BEFORE..$CI_COMMIT_SHA"
    FILES=$(git diff --name-only "$BEFORE" "$CI_COMMIT_SHA" | grep -E '^(secrets/|scripts/send_vars_to_gitlab\.sh)$' || true)
  fi
fi

if [[ -z "$FILES" ]]; then
  echo "ℹ️ Нет изменённых секретных файлов."
  echo "✅ Все секреты зашифрованы корректно."
  exit 0
fi

has_errors=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue
  [[ "$file" == *.gitkeep ]] && continue
  [[ "$(basename "$file")" == "README.md" ]] && continue

  status=$(sops filestatus "$file" 2>/dev/null || echo '{"encrypted":false}')
  enc=$(echo "$status" | jq -r '.encrypted')
  if [[ "$enc" != "true" ]]; then
    echo "❌ $file НЕ зашифрован"
    has_errors=1
  fi
done <<< "$FILES"

if (( has_errors == 0 )); then
  echo "✅ Все секреты зашифрованы корректно."
else
  echo "🛑 Найдены НЕзашифрованные секреты!"
  exit 1
fi
