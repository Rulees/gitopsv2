#!/bin/bash
set -euo pipefail

echo "🔐 Проверка зашифрованных файлов: Начало проверки"

WORK_DIR="${WORK_DIR:-/path/to/your/workdir}"
cd "$WORK_DIR"

echo "ℹ️  Текущая рабочая директория: $(pwd)"
echo "ℹ️  Список файлов в директории:"
ls -la

# Если в MR — симулируем merge
if [[ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" ]]; then
  echo "ℹ️  Скачиваем исходную ветку: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
  git fetch origin "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
  echo "ℹ️  Выполняем merge без коммита"
  git merge --no-commit --no-ff "origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" || true
fi

# Находим изменённые файлы
echo "ℹ️  Вычисляем изменённые файлы"
FILES=$(git diff --name-only "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-$CI_COMMIT_BEFORE_SHA}" "$CI_COMMIT_SHA" | grep -E '^secrets/|scripts/send_vars_to_gitlab.sh' || true)

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
