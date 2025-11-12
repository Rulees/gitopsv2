#!/usr/bin/env bash

MIN=${1:-10000}
shift || true

ASYNC_FLAG=1
PARALLEL=100

while (( $# )); do
  case "$1" in
    --async) ASYNC_FLAG=1 ;;
    --parallel) shift; PARALLEL="${1:-1}" ;;
    --skip-dns) SKIP_DNS=1 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
  shift || true
done

SINCE=$(date -u -d "-$MIN minutes" +"%Y-%m-%dT%H:%M:%SZ")

RES_TYPES=(
  "compute instance-group"
  "managed-postgresql cluster"
  "compute instance"
  "container registry"
  "vpc network"
  "vpc subnet"
  "vpc route-table"
  "vpc security-group"
  "load-balancer network-load-balancer"
  "serverless function"
  "serverless trigger"
  "serverless api-gateway"
  "serverless container"
  "dns zone"
  "certificate-manager certificate"
  "compute disk"
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
    | "compute instance" \
    | "container registry" \
    | "load-balancer network-load-balancer" \
    | "serverless function" \
    | "serverless trigger" \
    | "serverless api-gateway" \
    | "serverless container" \
    | "dns zone" \
    | "certificate-manager certificate" \
    | "compute disk")
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
    "compute instance")                CMD="yc compute instance delete --id $ID" ;;
    "container registry")              CMD="yc container registry delete --id $ID" ;;
    "vpc network")                     CMD="yc vpc network delete --id $ID" ;;
    "vpc subnet")                      CMD="yc vpc subnet delete --id $ID" ;;
    "vpc route-table")                 CMD="yc vpc route-table delete --id $ID" ;;
    "vpc security-group")              CMD="yc vpc security-group delete --id $ID" ;;
    "load-balancer network-load-balancer") CMD="yc load-balancer network-load-balancer delete --id $ID" ;;
    "serverless function")             CMD="yc serverless function delete --id $ID" ;;
    "serverless trigger")              CMD="yc serverless trigger delete --id $ID" ;;
    "serverless api-gateway")          CMD="yc serverless api-gateway delete --id $ID" ;;
    "serverless container")            CMD="yc serverless container delete --id $ID" ;;
    "iot-core registry")               CMD="yc iot-core registry delete --id $ID" ;;
    "compute disk")                    CMD="yc compute disk delete --id $ID" ;;
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

wait
echo "# SUMMARY"
for i in "${!RESULTS[@]}"; do
  printf "Task[%d]: %s -> %s\n" "$i" "${OPERATIONS[$i]:-n/a}" "${RESULTS[$i]}"
done

echo "# DONE"

###############################################################################
# NEW SECTION: DNS zones & A records enumeration + interactive deletion
###############################################################################
if [[ -z $SKIP_DNS ]]; then
  ZONES_JSON=$(yc dns zone list --format json 2>/dev/null)
  if [[ $(jq 'length' <<<"$ZONES_JSON") -eq 0 ]]; then
    echo "No DNS zones found."
  else
        DNS_REC_INDEX=0
    declare -a DNS_REC_ZONE_ID DNS_REC_SPEC DNS_REC_DESC

    echo
    echo "## DNS RECORDS TYPE A"
    # Iterate zones
    while read -r ZJ; do
      ZID=$(jq -r '.id' <<<"$ZJ")
      ZONE_FQDN=$(jq -r '.zone // ""' <<<"$ZJ")
      RECS_JSON=$(yc dns zone list-records "$ZID" --record-type A --format json 2>/dev/null || echo '{}')
      while IFS=$'\t' read -r NAME TTL IP; do
        [[ -z $NAME || -z $IP ]] && continue
          ((DNS_REC_INDEX++))
        if [[ -n $TTL && $TTL != "null" ]]; then
          SPEC="$NAME $TTL A $IP"
        else
          SPEC="$NAME A $IP"
        fi
        echo "[${DNS_REC_INDEX}] name=${NAME} ttl=${TTL:-"-"} A ${IP} zone_id=${ZID}"
          DNS_REC_ZONE_ID[$DNS_REC_INDEX]="$ZID"
          DNS_REC_SPEC[$DNS_REC_INDEX]="$SPEC"
      done < <(
        jq -r '
          def arr(x):
            if x==null then []
            elif (x|type)=="array" then x
            else [x] end;
          ( if type=="array" then .[]
            elif .record_sets? then .record_sets[]
            elif .records? then .records[]
            elif .rrsets? then .rrsets[]
            else empty end )
          | select(.type=="A")
          | (arr(.rrdatas) + arr(.data))[] as $ip
          | "\(.name)\t\(.ttl // "")\t\($ip)"
        ' <<<"$RECS_JSON"
      )
    done < <(jq -c '.[]' <<<"$ZONES_JSON")
    if (( DNS_REC_INDEX > 0 )); then
      echo
      read -rp "Enter numbers of A records to delete (space/comma separated, empty to skip): " TO_DEL
      if [[ -n $TO_DEL ]]; then
        # Normalize separators
        TO_DEL=$(sed -E 's/[ ,]+/ /g' <<<"$TO_DEL")
        for N in $TO_DEL; do
          if [[ $N =~ ^[0-9]+$ ]] && (( N>=1 && N<=DNS_REC_INDEX )); then
            ZID="${DNS_REC_ZONE_ID[$N]}"
            SPEC="${DNS_REC_SPEC[$N]}"
            yc dns zone delete-records --id "$ZID" --record "$SPEC" 2>/dev/null \
              && echo "deleted [$N] $SPEC" \
              || echo "fail [$N] $SPEC"
          fi
        done
      fi
    fi
  fi
  echo "## END DNS SECTION"
  echo
fi
###############################################################################
# END NEW DNS SECTION
###############################################################################
