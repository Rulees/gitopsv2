#!/usr/bin/env python3
import json, shlex, subprocess
from pathlib import Path

def _run(cmd, capture=False, check=True):
    proc = subprocess.run(cmd, shell=True, text=True,
                          stdout=subprocess.PIPE if capture else None,
                          stderr=subprocess.PIPE if capture else None)
    if check and proc.returncode != 0:
        raise RuntimeError(f"Command failed: {cmd}\n{proc.stderr if capture else ''}")
    return proc.stdout.strip() if capture else ""

def build_service_root(work_dir: Path, env: str, app: str, service: str, subservice: str | None = None) -> Path:
    base = work_dir / "infrastructure" / env
    if app == "infra":
        root = base / service
    else:
        root = base / "vpc" / app / service
    if subservice:
        root = root / subservice
    return root

def locate_ig_module(service_root: Path):
    """
    Смотрит строго в подпапки autoscale/ и instance_group/.
    Возвращает (ig_id, module_path) или (None, None).
    """
    for sub in ("autoscale", "instance_group"):
        candidate = service_root / sub
        tg = candidate / "terragrunt.hcl"
        if tg.exists():
            try:
                out = _run(f"terragrunt output -json --working-dir {shlex.quote(str(candidate))}", capture=True, check=True)
                j = json.loads(out)
                ig_id = j.get("instance_group_id", {}).get("value")
                if ig_id and ig_id != "null":
                    return ig_id, candidate
            except Exception as e:
                print(f"[path-locator] error reading {candidate}: {e}")
    return None, None
