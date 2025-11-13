#!/usr/bin/env python3
import os, sys, json, subprocess, shlex, time
from pathlib import Path

WORK_DIR = Path(os.environ.get("WORK_DIR", Path.cwd()))
ANSIBLE_DIR = WORK_DIR / "infrastructure" / "ansible"
os.environ["ANSIBLE_CONFIG"] = str(ANSIBLE_DIR / "ansible.cfg")

CANARY_DIR = WORK_DIR / "scripts" / "ci" / "canary"
sys.path.insert(0, str(CANARY_DIR))

# Импорт безопасного лоадера
from loader_numbered import load_numbered_modules

modules = load_numbered_modules(CANARY_DIR)
path_mod = modules.get("path_locator")
cap_mod  = modules.get("capacity_calc")

if path_mod is None or cap_mod is None:
    print("[fatal] required modules path_locator or capacity_calc not loaded")
    sys.exit(2)

build_service_root = path_mod.build_service_root
locate_ig_module   = path_mod.locate_ig_module
parse_percent      = cap_mod.parse_percent
compute_surge_count= cap_mod.compute_surge_count

DEFAULT_CANARY_ENABLED = True
DEFAULT_SURGE_COUNT    = None          # None -> авто по проценту
DEFAULT_CANARY_PERCENT = "5%"
DEFAULT_CONSUL_ADDR    = "http://127.0.0.1:8500"

def run(cmd, capture=False, check=True):
    proc = subprocess.run(cmd, shell=True, text=True,
                          stdout=subprocess.PIPE if capture else None,
                          stderr=subprocess.PIPE if capture else None)
    if check and proc.returncode != 0:
        if capture:
            print(f"[run] FAIL: {cmd}\n{proc.stderr.strip()}")
        else:
            print(f"[run] FAIL: {cmd}")
        sys.exit(proc.returncode)
    return proc.stdout.strip() if capture else ""

def kv_get(service, key):
    addr = os.environ.get("CONSUL_HTTP_ADDR", DEFAULT_CONSUL_ADDR)
    full = f"deploy/{service}/{key}"
    cmd = f"curl -sf {shlex.quote(addr)}/v1/kv/{full} | jq -r '.[0].Value | @base64d' 2>/dev/null"
    out = run(cmd, capture=True, check=False)
    return out.strip()

def kv_set(service, key, value):
    addr = os.environ.get("CONSUL_HTTP_ADDR", DEFAULT_CONSUL_ADDR)
    full = f"deploy/{service}/{key}"
    cmd = f"curl -sf -X PUT -d {shlex.quote(str(value))} {shlex.quote(addr)}/v1/kv/{full} >/dev/null"
    run(cmd, check=False)

def health_check(service, url=None, retries=10, sleep=5):
    url = url or f"http://localhost/{service}/health"
    for i in range(1, retries + 1):
        out = run(f"curl -fsS {shlex.quote(url)}", capture=True, check=False)
        if out and ("ok" in out.lower()):
            print(f"[health] {service} OK")
            return True
        print(f"[health] attempt {i} failed")
        time.sleep(sleep)
    return False

def fallback_deploy(env, app, service, subservice=None):
    cmd = f"scripts/ci/40-deploy.py {env} {app} {service}"
    if subservice:
        cmd += f" {subservice}"
    print(f"[fallback] {service} -> {cmd}")
    run(cmd, check=True)

def rollback_before_promote(service, ig_id, original_size):
    kv_set(service, "stable_weight", "100")
    kv_set(service, "canary_weight", "0")
    kv_set(service, "candidate_version", "")
    run(f"yc compute instance-group update --id {ig_id} --new-fixed-size {original_size}", check=True)
    print(f"[rollback] IG size restored {original_size}")

def parse_filter(expr: str):
    specs_raw = [p.strip() for p in expr.split("&&") if p.strip()]
    specs = []
    for raw in specs_raw:
        tokens = raw.split()
        spec = {}
        for t in tokens:
            if "=" not in t:
                continue
            k,v = t.split("=",1)
            k=k.upper().strip(); v=v.strip()
            if k=="ENV": spec["env"]=v
            elif k=="APP": spec["app"]=v
            elif k=="SERVICE": spec["service"]=v
            elif k=="SUBSERVICE": spec["subservice"]=v
        if {"env","app","service"} <= set(spec.keys()):
            specs.append(spec)
    return specs

def canary_cycle(env, app, service, sub, surge_cfg, percent_cfg, release_hash):
    current = kv_get(service, "current_version")
    if not current:
        print(f"[canary] FIRST RELEASE {service} -> current_version={release_hash} then fallback.")
        kv_set(service, "current_version", release_hash)
        kv_set(service, "stable_weight", "100")
        kv_set(service, "canary_weight", "0")
        fallback_deploy(env, app, service, sub)
        return

    kv_set(service, "candidate_version", release_hash)
    print(f"[canary] current={current} candidate={release_hash}")

    root = build_service_root(WORK_DIR, env, app, service, sub)
    ig_id, module_path = locate_ig_module(root)
    if not ig_id:
        print("[canary] IG not found -> fallback")
        fallback_deploy(env, app, service, sub)
        return
    print(f"[canary] IG_ID={ig_id} module={module_path}")

    orig_json = run(f"yc compute instance-group get --id {ig_id} --format json", capture=True, check=True)
    orig_len = len(json.loads(orig_json).get("instances", []))

    if surge_cfg is not None:
        surge_count = max(1, surge_cfg)  # защита от 0
    else:
        P = parse_percent(percent_cfg)
        # защита от P >= 1.0:
        if P <= 0.0 or P >= 1.0:
            print(f"[canary] invalid percent {percent_cfg} -> fallback deploy")
            fallback_deploy(env, app, service, sub)
            return
        surge_count = compute_surge_count(orig_len, P, min_surge=1)

    target_len = orig_len + surge_count
    run(f"yc compute instance-group update --id {ig_id} --new-fixed-size {target_len}", check=True)
    print(f"[canary] surge {orig_len} -> {target_len} (+{surge_count})")

    # Wait candidate registration
    addr = os.environ.get("CONSUL_HTTP_ADDR", DEFAULT_CONSUL_ADDR)
    for i in range(1, 41):
        svc_json = run(f"curl -sf {shlex.quote(addr)}/v1/catalog/service/{service}", capture=True, check=False)
        count=0
        if svc_json:
            try:
                arr=json.loads(svc_json)
                count=sum(1 for o in arr if any(f"version={release_hash}"==t for t in (o.get('ServiceTags') or [])))
            except Exception:
                pass
        if count>=1:
            print(f"[canary] candidate registered count={count}")
            break
        time.sleep(5)
    else:
        print("[canary] candidate TIMEOUT -> rollback")
        rollback_before_promote(service, ig_id, orig_len)
        return

    kv_set(service, "stable_weight", "95")
    kv_set(service, "canary_weight", "5")
    print("[canary] weights 95/5")
    if not health_check(service):
        print("[canary] health FAIL -> rollback")
        rollback_before_promote(service, ig_id, orig_len)
        return

    kv_set(service, "stable_weight", "0")
    kv_set(service, "canary_weight", "100")
    print("[canary] weights 0/100")

    kv_set(service, "previous_version", current)
    kv_set(service, "current_version", release_hash)
    print(f"[canary] promote previous={current} current={release_hash}")

    run(f"yc compute instance-group update --id {ig_id} --new-fixed-size {surge_count}", check=True)
    print(f"[canary] drain -> size={surge_count}")

    kv_set(service, "candidate_version", "")
    kv_set(service, "stable_weight", "100")
    kv_set(service, "canary_weight", "0")
    print("[canary] cleanup done")

def main():
    filter_expr = os.getenv("FILTER","")
    if not filter_expr:
        print("⚠️ FILTER empty.")
        return
