#!/bin/bash
set -e

echo "🔐 Проверка одобрений MR перед деплоем в прод..."
echo "DEBUG: APPROVERS=${APPROVERS_ARRAY}"
echo "DEBUG: APPROVERS_INFRA=${APPROVERS_INFRA_ARRAY}"

# === Задание переменных ===
MAX_RETRIES=7  # Максимальное количество попыток-проверок
RETRY_DELAY=30  # Задержка между попытками в секундах
# VARIABLES_FROM_GITLAB_PROJECT
APPROVERS_ARRAY=(${APPROVERS_ARRAY//,/ })
APPROVERS_INFRA_ARRAY=(${APPROVERS_INFRA_ARRAY//,/ })
GITLAB_TOKEN="${GITLAB_API_PROJECT_TOKEN}"

# === Predefined GitLab pipeline variables ===
API_URL="${CI_API_V4_URL}"
PROJECT_ID="${CI_PROJECT_ID}"
COMMIT_SHA="${CI_COMMIT_SHA}"
TARGET_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}"

# === Получаем MR ===
MR_INFO=$(curl --silent --request GET \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "${API_URL}/projects/${PROJECT_ID}/merge_requests" \
  | jq -c ".[] | select(.sha == \"${COMMIT_SHA}\" and .state == \"opened\" and .target_branch == \"${TARGET_BRANCH}\")")

if [ -z "$MR_INFO" ]; then
  echo "❌ Merge Request не найден."
  exit 1
fi

MR_ID=$(echo "$MR_INFO" | jq '.iid')

# === Проверка изменённых файлов ===
CHANGED_FILES=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "${API_URL}/projects/${PROJECT_ID}/merge_requests/${MR_ID}/changes" \
  | jq -r '.changes[].new_path')

IS_RESTRICTED_CHANGE=false

for file in $CHANGED_FILES; do
  if [[ ! "$file" =~ ^(projects/|secrets/(dev|prod)/) ]]; then
    IS_RESTRICTED_CHANGE=true
    break
  fi
done

if $IS_RESTRICTED_CHANGE; then
  echo "🔒 Restricted changes detected — only APPROVERS_INFRA allowed: ${APPROVERS_INFRA_ARRAY[*]}"
  CURRENT_APPROVERS=("${APPROVERS_INFRA_ARRAY[@]}")
else
  echo "🟢 Only safe paths changed — any of APPROVERS can approve: ${APPROVERS_ARRAY[*]}"
  CURRENT_APPROVERS=("${APPROVERS_ARRAY[@]}")
fi

if [ ${#CURRENT_APPROVERS[@]} -eq 0 ]; then
  echo "❌ Список аппруверов пуст — ничего проверять!"
  exit 1
fi

# === Получаем approvals ===
APPROVALS=$(curl --silent --request GET \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "${API_URL}/projects/${PROJECT_ID}/merge_requests/${MR_ID}/approvals")

# === Ждём хотя бы одного аппрува ===
APPROVED=false
APPROVED_BY=()

for ((i=1; i<=MAX_RETRIES; i++)); do
  APPROVED_BY=()  # очищаем перед каждой итерацией
  for AUTHOR in "${CURRENT_APPROVERS[@]}"; do
    if echo "${APPROVALS}" | jq -e ".approved_by[] | select(.user.username == \"${AUTHOR}\")" > /dev/null; then
      APPROVED_BY+=("${AUTHOR}")
    fi
  done

  if [ ${#APPROVED_BY[@]} -gt 0 ]; then
    APPROVED=true
    break
  fi

  echo "⏳ Ожидаем хотя бы одного одобрения от: ${CURRENT_APPROVERS[*]} (попытка $i/${MAX_RETRIES})"
  sleep ${RETRY_DELAY}

  # Обновляем approvals
  APPROVALS=$(curl --silent --request GET \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "${API_URL}/projects/${PROJECT_ID}/merge_requests/${MR_ID}/approvals")
done

if [ "$APPROVED" = true ]; then
  echo "✅ MR одобрен хотя бы одним из: ${CURRENT_APPROVERS[*]}"
  echo "👥 Одобрили: ${APPROVED_BY[*]}"
else
  echo "❌ Не получено одобрения ни от одного из: ${CURRENT_APPROVERS[*]}"
  exit 1
fi
