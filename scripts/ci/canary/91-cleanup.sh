#!/usr/bin/env bash
# Возврат весов (100/0), очистка candidate_version.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/candidate_version ""
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/stable_weight "100"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/canary_weight "0"
echo "[cleanup] reset candidate & weights"
