#!/usr/bin/env python3
import asyncio, os, sys
from pathlib import Path

# 📦 Настройка переменных
WORK_DIR = Path(os.environ.get("WORK_DIR", Path(__file__).resolve().parent.parent.parent))
ANSIBLE_DIR = WORK_DIR / "infrastructure" / "ansible"
os.environ["ANSIBLE_CONFIG"] = str(ANSIBLE_DIR / "ansible.cfg")

# Импорт discovery
sys.path.insert(0, str(WORK_DIR / "scripts" / "ci"))
from discover_services import find_project_root, find_matching_services, build_group_name


async def run_playbook(m):
    group = build_group_name(m["env"], m["app"], m["service"])
    playbook = m["path"] / "playbook.yml"

    if not playbook.exists():
        print(f"⚠️ Skipping {group}: playbook not found at {playbook}")
        return

    print(f"\n🚀 [DEPLOY] {group} → {playbook}")

    
    is_serverless = "serverless" in m["service"]

    cmd = [
        "ansible-playbook", str(playbook),
        "-e", f"env={m['env']}", "-e", f"app={m['app']}", "-e", f"service={m['service']}",
        "--diff"
    ]

    if not is_serverless:
        cmd += [
            "-i", str(ANSIBLE_DIR / "inventory" / "yc_compute.py"),
            "-l", group
        ]

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(ANSIBLE_DIR),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT
    )

    stdout, _ = await proc.communicate()

    if proc.returncode != 0:
        print(f"❌❌❌ Ansible failed for {group}")
        print(stdout.decode())
    else:
        print(f"✅✅✅✅✅ Ansible succeeded for {group}")
        print(stdout.decode())

async def main():
    os.chdir(find_project_root())

    env = os.getenv("ENV")
    app = os.getenv("APP")
    service = os.getenv("SERVICE")

    matches = find_matching_services(env, app, service)
    if not matches:
        print("⚠️ No matching services for deploy.")
        return

    print("📦 Matched groups:")
    for m in matches:
        print(f" - {build_group_name(m['env'], m['app'], m['service'])}")

    # Run all deployments concurrently
    await asyncio.gather(*(run_playbook(m) for m in matches))

if __name__ == "__main__":
    asyncio.run(main())
