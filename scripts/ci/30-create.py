#!/usr/bin/env python3
import subprocess, os, sys
from pathlib import Path

# 🔧 Add the project root and scripts/ci/ to sys.path
ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "scripts" / "ci"))

# Импорт из твоего собственного discover_services.py
from discover_services import find_project_root, find_matching_services, build_group_name

def main():
    os.chdir(find_project_root())

    env = os.getenv("ENV")
    app = os.getenv("APP")
    service = os.getenv("SERVICE")
    subservice = os.getenv("SUBSERVICE")


    if (subservice and not (service and app and env)) or (service and not(app and env)) or (app and not (env)):
        print("❌ Allow only:  ENV, ENV+APP, ENV+APP+SERVICE, or ENV+APP+SERVICE+SUBSERVICE (no gaps or skips in order).")
        sys.exit(1)

    # Build working directory based on given vars
    working_dir = Path(ROOT / "infrastructure" / env)
    if app:
        working_dir /= f"vpc/{app}"
        if service:
            working_dir /= service
            if subservice:
                working_dir /= subservice

    # Find target services
    matches = find_matching_services(env, app, service, subservice)

    if not matches:
        print("⚠️ No matching services found for apply.")
        sys.exit(0)

    print("📦 Matched groups:")
    for m in matches:
        print(f" - {build_group_name(m['env'], m['app'], m['service'], m.get('subservice'))}")

    # Build command
    cmd = [
        "terragrunt", "apply", "--all", "--non-interactive", "-lock=false", "-auto-approve", "--queue-include-external", "--working-dir", str(working_dir)
    ]

    print(f"\n🚀 Running: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as err:
        print("💥 Terragrunt apply failed.")
        print(err)
        sys.exit(err.returncode)

if __name__ == "__main__":
    main()
