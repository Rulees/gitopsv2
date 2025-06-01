#!/usr/bin/env python3
import os
from pathlib import Path

def find_project_root(marker="makefile"):
    current = Path(__file__).resolve().parent
    while current != current.parent:
        if (current / marker).exists():
            return current
        current = current.parent
    raise FileNotFoundError("❌ Can't find project root")

def find_matching_services(env=None, app=None, service=None):
    root = find_project_root()
    base = root / "infrastructure"

    # 📂 Получаем список доступных окружений
    envs = [env] if env else [d.name for d in base.iterdir() if d.is_dir()]
    matched = []

    for e in envs:
        env_base = base / e
        app_base = env_base / "vpc"

        # === Классический путь: vpc/app/service ===
        if app_base.exists():
            apps = [app] if app else [d.name for d in app_base.iterdir() if d.is_dir()]
            for a in apps:
                svc_base = app_base / a
                if not svc_base.exists():
                    continue

                services = [service] if service else [d.name for d in svc_base.iterdir() if d.is_dir()]
                for s in services:
                    service_path = svc_base / s
                    if not service_path.exists():
                        continue
                    tf_hcl = service_path / "terragrunt.hcl"
                    playbook = service_path / "playbook.yml"

                    matched.append({
                        "env": e,
                        "app": a,
                        "service": s,
                        "path": service_path,
                        "has_tf": tf_hcl.exists(),
                        "has_ansible": playbook.exists()
                    })

        # === Доп. путь: прямые infra-сервисы ===
        dirs = [d for d in env_base.iterdir() if d.is_dir() and d.name != "vpc"]
        for d in dirs:
            s = d.name
            if service and s != service:
                continue
            if app and app != "infra":
                continue

            tf_hcl = d / "terragrunt.hcl"
            playbook = d / "playbook.yml"

            if tf_hcl.exists() and playbook.exists():
                matched.append({
                    "env": e,
                    "app": "infra",
                    "service": s,
                    "path": d,
                    "has_tf": tf_hcl.exists(),
                    "has_ansible": playbook.exists()
                })

    return matched

def build_group_name(env=None, app=None, service=None):
    if env and app and service:
        return f"env_{env}__app_{app}__service_{service}"
    elif env and app:
        return f"env_{env}__app_{app}"
    elif env and service:
        return f"env_{env}__service_{service}"
    elif app and service:
        return f"app_{app}__service_{service}"
    elif env:
        return f"env_{env}"
    elif app:
        return f"app_{app}"
    elif service:
        return f"service_{service}"
    else:
        return "all"
