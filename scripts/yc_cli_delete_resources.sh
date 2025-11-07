#!/usr/bin/env bash

MIN=${1:-1000}
shift || true

ASYNC_FLAG=1
PARALLEL=100

while (( $# )); do
  case "$1" in
    --async) ASYNC_FLAG=1 ;;
    --parallel) shift; PARALLEL="${1:-1}" ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
  shift || true
done

SINCE=$(date -u -d "-$MIN minutes" +"%Y-%m-%dT%H:%M:%SZ")

RES_TYPES=(
  "compute instance-group"
  "managed-postgresql cluster"
  "container registry"
  "vpc network"
  "vpc subnet"
  "vpc route-table"
  "vpc address"
  "vpc security-group"
  "load-balancer network-load-balancer"
  "serverless function"
  "serverless api-gateway"
  "serverless container"
  "dns zone"
  "certificate-manager certificate"
  "compute instance"
  "compute disk"
  "transfer endpoint"
  "transfer config"
)

JQ_FILTER=$'.[]? | select(.created_at >= $T) | {type:$TYPE,id:.id}'
JQ_FILTER+=' + (if (.status? // "" | length)>0 then {status:.status} else {} end)'
JQ_FILTER+=' + (if (.name? // "" | length)>0 then {name:.name} else {} end)'
JQ_FILTER+=' + (if (.description? // "" | length)>0 then {description:.description} else {} end)'
JQ_FILTER+=' + (if (.labels? and (.labels|length)>0) then {labels:.labels} else {} end)'

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

echo "# CLEANUP (created >= $SINCE, async=${ASYNC_FLAG}, parallel=${PARALLEL})"

# Список типов, где --async реально поддерживается
supports_async() {
  case "$1" in
     "compute instance-group" \
    | "managed-postgresql cluster" \
    | "container registry" \
    | "load-balancer network-load-balancer" \
    | "serverless function" \
    | "serverless api-gateway" \
    | "serverless container" \
    | "dns zone" \
    | "certificate-manager certificate" \
    | "compute instance" \
    | "compute disk" \
    | "transfer endpoint" \
    | "transfer config")
      return 0 ;;
    *) return 1 ;;
  esac
}

# Сбор всех объектов в NDJSON
for T in "${RES_TYPES[@]}"; do
  S=${T%% *}; E=${T#"$S "}
  yc "$S" "$E" list --format json 2>/dev/null \
    | jq -c --arg T "$SINCE" --arg TYPE "$T" "$JQ_FILTER" >>"$TMP" || true
done

if [[ ! -s $TMP ]]; then
  echo "Нет подходящих ресурсов."
  exit 0
fi

mapfile -t ITEMS <"$TMP"

total=${#ITEMS[@]}
idx=0
active=0
declare -a PIDS RESULTS OPERATIONS

for O in "${ITEMS[@]}"; do
  ((idx++))
  echo "$O"
  TYPE=$(jq -r '.type' <<<"$O")
  ID=$(jq -r '.id' <<<"$O")
  NAME=$(jq -r '.name // ""' <<<"$O")

  CMD=""
  case "$TYPE" in
    "compute instance-group")          CMD="yc compute instance-group delete --id $ID" ;;  
    "managed-postgresql cluster")      CMD="yc managed-postgresql cluster delete --id $ID" ;;
    "container registry")              CMD="yc container registry delete --id $ID" ;;
    "vpc network")                     CMD="yc vpc network delete --id $ID" ;;
    "vpc subnet")                      CMD="yc vpc subnet delete --id $ID" ;;
    "vpc route-table")                 CMD="yc vpc route-table delete --id $ID" ;;
    "vpc address")                     CMD="yc vpc address delete --id $ID" ;;
    "vpc security-group")              CMD="yc vpc security-group delete --id $ID" ;;
    "load-balancer network-load-balancer") CMD="yc load-balancer network-load-balancer delete --id $ID" ;;
    "serverless function")             CMD="yc serverless function delete --id $ID" ;;
    "serverless api-gateway")          CMD="yc serverless api-gateway delete --id $ID" ;;
    "serverless container")            CMD="yc serverless container delete --id $ID" ;;
    "iot-core registry")               CMD="yc iot-core registry delete --id $ID" ;;
    "compute instance")                CMD="yc compute instance delete --id $ID" ;;
    "compute disk")                    CMD="yc compute disk delete --id $ID" ;;
    "transfer endpoint")               CMD="yc transfer endpoint delete --id $ID" ;;
    "transfer config")                 CMD="yc transfer config delete --id $ID" ;;
  esac

  if [[ -z $CMD ]]; then
    echo "skip (no delete command)"
    continue
  fi

  if (( ASYNC_FLAG )) && supports_async "$TYPE"; then
    CMD+=" --async"
  fi

  read -rp "[$idx/$total] delete? [y/N] " ans
  if [[ ${ans,,} =~ ^y(es)?$ ]]; then
    # echo "exec: $CMD"
    # Запуск в фоне
    {
      if out=$(eval "$CMD" 2>&1); then
        PIDS[$idx]=$!
        OPERATIONS[$idx]=$(grep -Eo '"id":"[a-z0-9]+' <<<"$out" | head -1 | cut -d'"' -f4 || true)
        RESULTS[$idx]="OK"
      else
        RESULTS[$idx]="FAIL"
        echo "[$idx] FAILED: $CMD"
        echo "$out" >&2
      fi
    } &
    active=$((active + 1))
    if (( active >= PARALLEL )); then
      wait -n || true
      active=$((active - 1))
    fi
  else
    echo "[$idx/$total] skipped"
    RESULTS[$idx]="SKIP"
  fi
done

# Ждём завершение всех фоновых процессов
wait

echo "# SUMMARY"
for i in "${!RESULTS[@]}"; do
  printf "Task[%d]: %s -> %s\n" "$i" "${OPERATIONS[$i]:-n/a}" "${RESULTS[$i]}"
done

echo "# DONE"
