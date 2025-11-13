#!/usr/bin/env bash
# Текущий размер IG.
set -euo pipefail
: "${IG_ID:?IG_ID required}"
yc compute instance-group get --id "$IG_ID" --format json | jq '.instances | length'
