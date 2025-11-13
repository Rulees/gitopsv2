#!/usr/bin/env bash
# Установка весов.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
: "${STABLE:?STABLE required}"
: "${CANARY:?CANARY required}"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/stable_weight "$STABLE"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/canary_weight "$CANARY"
echo "[weights] ${SERVICE_NAME} stable=${STABLE} canary=${CANARY}"
