#!/usr/bin/env bash
# Health через /<service>/health (ожидаем 'ok').
set -euo pipefail
SERVICE_NAME="${SERVICE_NAME:?SERVICE_NAME required}"
URL="${CANARY_HEALTH_URL:-http://localhost/${SERVICE_NAME}/health}"
RETRIES="${RETRIES:-10}"
SLEEP_SEC="${SLEEP_SEC:-5}"

for i in $(seq 1 "$RETRIES"); do
  if curl -fsS "$URL" | grep -qi 'ok'; then
    echo "[health] OK"
    exit 0
  fi
  echo "[health] attempt $i failed"
  sleep "$SLEEP_SEC"
done
echo "[health] FAIL"
exit 1
