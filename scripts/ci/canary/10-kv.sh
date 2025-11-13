#!/usr/bin/env bash
# KV helper: get/set. Usage:
#   ./05-kv.sh get deploy/service_database/current_version
#   ./05-kv.sh set deploy/service_database/stable_weight 95
set -euo pipefail
ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"
CMD="${1:-}"; KEY="${2:-}"; VAL="${3:-}"
if [[ "$CMD" == "get" ]]; then
  curl -sf "${ADDR}/v1/kv/${KEY}" | jq -r '.[0].Value | @base64d' 2>/dev/null || true
elif [[ "$CMD" == "set" ]]; then
  [[ -z "${VAL:-}" ]] && { echo "Value required" >&2; exit 1; }
  curl -sf -X PUT -d "$VAL" "${ADDR}/v1/kv/${KEY}" >/dev/null
else
  echo "Usage: $0 [get|set] key [value]" >&2; exit 1
fi
