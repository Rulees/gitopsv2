#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов: Начало проверки"

WORK_DIR="${WORK_DIR:-/builds/arkselen/project_gitlab_arkselen}"
cd "$WORK_DIR"

echo "ℹ️  Текущая рабочая директория: $(pwd)"
echo "ℹ️  Список файлов в директории:"
ls -la

TARGET_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-main}"

# Check if the target branch exists remotely
if git ls-remote --heads origin "$TARGET_BRANCH" &>/dev/null; then
  echo "ℹ️  Скачиваем исходную ветку: $TARGET_BRANCH"
  git fetch origin "$TARGET_BRANCH"
  
  # Attempt a merge, allowing unrelated histories in case of conflicts
  echo "ℹ️  Выполняем merge без коммита"
  git merge --no-commit --no-ff --allow-unrelated-histories "origin/$TARGET_BRANCH" || true
else
  echo "⚠️  Целевая ветка $TARGET_BRANCH не найдена в удаленном репозитории. Пропускаем merge."
fi

# Find changed files
echo "ℹ️  Вычисляем изменённые файлы"
FILES=$(git diff --name-only "${TARGET_BRANCH:-$CI_COMMIT_BEFORE_SHA}" HEAD | grep -E '^secrets/|scripts/send_vars_to_gitlab.sh' || true)

echo "ℹ️  Найденные файлы: $FILES"
has_errors=0

for file in $FILES; do
  echo "ℹ️  Проверяем файл: $file"
  [[ ! -f "$file" || "$file" == *.gitkeep || "$(basename "$file")" == "README.md" ]] && {
    echo "ℹ️  Пропускаем файл: $file"
    continue
  }

  echo "ℹ️  Получаем статус SOPS для файла: $file"
  status=$(sops filestatus "$file" 2>/dev/null || echo '{"encrypted":false}')
  echo "ℹ️  Статус файла: $status"
  
  [[ "$(echo "$status" | jq -r '.encrypted')" != "true" ]] && {
    echo "❌ $file НЕ зашифрован"
    has_errors=1
  }
done

if (( has_errors == 0 )); then
  echo "✅ Все секреты зашифрованы корректно."
else
  echo "🛑 Найдены НЕзашифрованные секреты!"
  exit 1
fi
