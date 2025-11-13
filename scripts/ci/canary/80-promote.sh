#!/usr/bin/env bash
# Promote: previous <- current, current <- candidate.
set -euo pipefail
: "${SERVICE_NAME:?SERVICE_NAME required}"
CUR="$(./scripts/ci/canary/05-kv.sh get deploy/${SERVICE_NAME}/current_version || true)"
CANDIDATE="$(./scripts/ci/canary/05-kv.sh get deploy/${SERVICE_NAME}/candidate_version || true)"
[[ -z "$CANDIDATE" ]] && { echo "[promote] candidate empty"; exit 1; }
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/previous_version "$CUR"
./scripts/ci/canary/05-kv.sh set deploy/${SERVICE_NAME}/current_version "$CANDIDATE"
echo "[promote] previous=${CUR} current=${CANDIDATE}"
