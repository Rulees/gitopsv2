#!/usr/bin/env bash
# Статус после цикла.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
kv(){ ./scripts/ci/canary/05-kv.sh get "$1"; }
echo "=== STATUS ${SERVICE_NAME} ==="
echo "current_version:    $(kv deploy/${SERVICE_NAME}/current_version)"
echo "previous_version:   $(kv deploy/${SERVICE_NAME}/previous_version)"
echo "candidate_version:  $(kv deploy/${SERVICE_NAME}/candidate_version)"
echo "stable_weight:      $(kv deploy/${SERVICE_NAME}/stable_weight)"
echo "canary_weight:      $(kv deploy/${SERVICE_NAME}/canary_weight)"
