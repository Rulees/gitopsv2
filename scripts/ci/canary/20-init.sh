#!/usr/bin/env bash
# Устанавливаем candidate_version, проверяем current_version.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
RELEASE_HASH="${RELEASE_HASH:-${CI_COMMIT_SHA:-unknown}}"

CURRENT="$(./scripts/ci/canary/05-kv.sh get deploy/${SERVICE_NAME}/current_version || true)"

if [[ -z "$CURRENT" ]]; then
  echo "[init] First release -> current_version=${RELEASE_HASH}"
  ./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/current_version "${RELEASE_HASH}"
  ./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/stable_weight "100"
  ./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/canary_weight "0"
  exit 10
fi

./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/candidate_version "${RELEASE_HASH}"
echo "[init] current=${CURRENT} candidate=${RELEASE_HASH}"
