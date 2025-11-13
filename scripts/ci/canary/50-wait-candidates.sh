#!/usr/bin/env bash
# Ждём регистрацию VM с version=candidate_version.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"
CANDIDATE="$(./scripts/ci/canary/05-kv.sh get deploy/${SERVICE_NAME}/candidate_version || true)"
[[ -z "$CANDIDATE" ]] && { echo "[wait] candidate_version empty"; exit 1; }

for i in $(seq 1 40); do
  COUNT=$(curl -sf "${ADDR}/v1/catalog/service/${SERVICE_NAME}" | jq --arg v "version=${CANDIDATE}" '[.[] | select(.ServiceTags[]? == $v)] | length')
  if [[ "$COUNT" -ge 1 ]]; then
    echo "[wait] registered count=${COUNT}"
    exit 0
  fi
  sleep 5
done
echo "[wait] timeout"
exit 1
