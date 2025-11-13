#!/usr/bin/env bash
# Rollback до promote: восстановить веса, удалить candidate_version, вернуть IG размер.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
: "${IG_ID:?IG_ID required}"
: "${ORIGINAL_SIZE:?ORIGINAL_SIZE required}"

./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/stable_weight "100"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/canary_weight "0"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/candidate_version ""
yc compute instance-group update --id "$IG_ID" --new-fixed-size "$ORIGINAL_SIZE"
echo "[rollback] IG restored size=${ORIGINAL_SIZE}"
