#!/usr/bin/env bash
# Уменьшаем размер IG до TARGET_SIZE (обычно SURGE_COUNT).
set -euo pipefail
: "${IG_ID:?IG_ID required}"
TARGET_SIZE="${TARGET_SIZE:?TARGET_SIZE required}"
echo "[drain] IG -> ${TARGET_SIZE}"
yc compute instance-group update --id "$IG_ID" --new-fixed-size "$TARGET_SIZE"
