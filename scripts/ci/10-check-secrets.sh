#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов"

# Определяем базу для diff:
if [[ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" ]]; then
  git fetch --depth=1 origin "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
  DIFF_BASE="origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
else
  DIFF_BASE="${CI_COMMIT_BEFORE_SHA:-}"
fi

# Собираем изменённые релевантные файлы (все изменения MR относительно целевой ветки)
FILES=$(git diff --name-only "$DIFF_BASE...$CI_COMMIT_SHA" | grep -E '^(secrets/|scripts/send_vars_to_gitlab\.sh)$' || true)

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
  encrypted=$(echo "$status" | jq -r '.encrypted')
  if [[ "$encrypted" != "true" ]]; then
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
