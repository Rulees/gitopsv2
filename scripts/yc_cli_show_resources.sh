#!/usr/bin/env bash

#@ Минуты назад (по умолчанию 500), можно передать числом: ./show.sh 30
MINUTES="${1:-500}"
TIME_FILTER="$(date -u -d "-${MINUTES} minutes" +"%Y-%m-%dT%H:%M:%SZ")"

# Набор ресурсов: "<service> <entity>"
resources=(
  "compute instance-group"
  "managed-postgresql cluster"
  "compute snapshot"
  "storage bucket"
  "compute instance"
  "compute disk"
  "vpc network"
  "vpc subnet"
  "vpc route-table"
  "vpc address"
  "vpc security-group"
  "load-balancer network-load-balancer"
  "managed-kubernetes cluster"
  "serverless trigger"
  "serverless function"
  "serverless api-gateway"
  "serverless container"
)

echo "# SHOW (created >= ${TIME_FILTER}, window = ${MINUTES}m)"

jq_filter='
  .[]? 
  | select(.created_at >= $TIME) 
  | (
      {type:$TYPE,id:.id}
      + (if (.status? // "" | length) > 0 then {status:.status} else {} end)
      + (if (.name? // "" | length) > 0 then {name:.name} else {} end)
      + (if (.description? // "" | length) > 0 then {description:.description} else {} end)
      + (if (has("labels") and .labels != null and (.labels|length)>0) then {labels:.labels} else {} end)
    )
'

for r in "${resources[@]}"; do
  svc="${r%% *}"
  ent="${r#"$svc "}"
  yc "$svc" "$ent" list --format json 2>/dev/null \
    | jq --arg TIME "$TIME_FILTER" --arg TYPE "$r" "$jq_filter"
done


# in one string
# MINUTES="${1:-500}"; TIME_FILTER="$(date -u -d "-${MINUTES} minutes" +"%Y-%m-%dT%H:%M:%SZ")"; resources=("compute instance" "compute disk" "compute snapshot" "storage bucket" "managed-postgresql cluster" "managed-mysql cluster" "managed-mongodb cluster" "managed-clickhouse cluster" "managed-redis cluster" "managed-elasticsearch cluster" "vpc network" "vpc subnet" "vpc route-table" "vpc address" "vpc security-group" "load-balancer network-load-balancer" "managed-kubernetes cluster" "serverless function" "serverless api-gateway" "serverless container"); echo "# SHOW (created >= ${TIME_FILTER}, window = ${MINUTES}m)"; jq_filter='.[]? | select(.created_at >= $TIME) | ({type:$TYPE,id:.id} + (if (.status? // "" | length) > 0 then {status:.status} else {} end) + (if (.name? // "" | length) > 0 then {name:.name} else {} end) + (if (.description? // "" | length) > 0 then {description:.description} else {} end) + (if (has("labels") and .labels != null and (.labels|length)>0) then {labels:.labels} else {} end))'; for r in "${resources[@]}"; do svc="${r%% *}"; ent="${r#"$svc "}"; yc "$svc" "$ent" list --format json 2>/dev/null | jq --arg TIME "$TIME_FILTER" --arg TYPE "$r" "$jq_filter"; done
