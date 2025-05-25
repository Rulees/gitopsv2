#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов"

# Если в MR — симулируем merge
if [[ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" ]]; then
  git fetch origin "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
  git merge --no-commit --no-ff "origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" || true
fi

# Находим изменённые файлы
FILES=$(git diff --name-only "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-$CI_COMMIT_BEFORE_SHA}" "$CI_COMMIT_SHA" | grep -E '^secrets/|scripts/send_vars_to_gitlab.sh' || true)

has_errors=0

for file in $FILES; do
  [[ ! -f "$file" || "$file" == *.gitkeep || "$(basename "$file")" == "README.md" ]] && continue

  status=$(sops filestatus "$file" 2>/dev/null || echo '{"encrypted":false}')
  [[ "$(echo "$status" | jq -r '.encrypted')" != "true" ]] && {
    echo "❌ $file НЕ зашифрован"
    has_errors=1
  }
done

(( has_errors == 0 )) && echo "✅ Все секреты зашифрованы корректно." || {
  echo "🛑 Найдены НЕзашифрованные секреты!"
  exit 1
}
echo "✅ Все секреты зашифрованы корректно."
