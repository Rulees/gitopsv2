#!/usr/bin/env python3
import asyncio, os, sys
from pathlib import Path

# 📦 Настройка переменных
WORK_DIR = Path(os.environ.get("WORK_DIR", Path.cwd()))
ANSIBLE_DIR = WORK_DIR / "infrastructure" / "ansible"
os.environ["ANSIBLE_CONFIG"] = str(ANSIBLE_DIR / "ansible.cfg")

# Импорт discovery
sys.path.insert(0, str(WORK_DIR / "scripts" / "ci"))
from discover_services import find_project_root, find_matching_services, build_group_name

# === Парсинг зависимостей из комментариев в playbook.yml ===
def extract_dependencies(playbook_path):
    dependencies = []
    try:
        with open(playbook_path, 'r') as file:
            lines = file.readlines()
        current = {}
        in_block = False
        for line in lines:
            line = line.strip()
            if line.startswith("# dependencies:"):
                in_block = True
                continue
            if in_block:
                if line.startswith("#   - app:"):
                    if current:
                        dependencies.append(current)
                    current = {"app": line.split(":", 1)[1].strip()}
                elif line.startswith("#     service:"):
                    current["service"] = line.split(":", 1)[1].strip()
                elif line.startswith("#     wait:"):
                    current["wait"] = line.split(":", 1)[1].strip()
                elif line.startswith("#     path:"):
                    current["path"] = line.split(":", 1)[1].strip()
                elif not line.startswith("#"):
                    if current:
                        dependencies.append(current)
                    break
        if current:
            dependencies.append(current)
    except Exception as e:
        print(f"❌ Error reading dependencies from {playbook_path}: {e}")
    return dependencies

# === Асинхронный запуск ansible-playbook ===
async def run_ansible_playbook(m, group, playbook):
    is_serverless = "serverless" in m["service"]
    cmd = [
        "ansible-playbook", str(playbook),
        "-e", f"env={m['env']}", "-e", f"app={m['app']}", "-e", f"service={m['service']}",
        "--diff"
    ]
    if not is_serverless:
        cmd += ["-i", str(ANSIBLE_DIR / "inventory" / "yc_compute.py"), "-l", group]

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(ANSIBLE_DIR),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT
    )
    stdout, _ = await proc.communicate()
    return proc.returncode, stdout.decode()

# === Запуск одного playbook с учётом зависимостей ===
async def run_playbook(m, processed_groups, level=0):
    indent = "  " * level
    group = build_group_name(m["env"], m["app"], m["service"])
    playbook = m["path"] / "playbook.yml"

    if not playbook.exists():
        print(f"{indent}⚠️ Skipping {group}: playbook not found")
        return 1

    print(f"{indent}🚀 [DEPLOY]      {group}   {playbook}")

    dependencies = extract_dependencies(playbook)
    background_tasks = []

    for dep in dependencies:
        dep["env"] = m["env"]
        if "path" in dep:
            dep["path"] = (WORK_DIR / dep["path"]).resolve()
        else:
            base = WORK_DIR / "infrastructure" / dep["env"]
            dep["path"] = base / dep["service"] if dep["app"] == "infra" else base / "vpc" / dep["app"] / dep["service"]

        dep_group = build_group_name(dep["env"], dep["app"], dep["service"])

        if dep_group not in processed_groups:
            processed_groups.add(dep_group)
            print(f"{indent}   [dependency]  {dep_group} ({'Async' if dep.get('wait', 'true') == 'false' else 'Sync'})")
            if dep.get("wait", "true") == "false":
                task = asyncio.create_task(run_playbook(dep, processed_groups, level + 1))
                background_tasks.append(task)
            else:
                await run_playbook(dep, processed_groups, level + 1)


    returncode, output = await run_ansible_playbook(m, group, playbook)

    status = "SUCCESS" if returncode == 0 else "FAILED"
    status_display = {
        "SUCCESS": "\033[92m✔️✔️✔️✔️✔️✔️✔️✔️✔️✔️ SUCCESS\033[0m",
        "FAILED": "\033[91m❌❌❌❌❌❌❌❌❌❌ FAILED\033[0m"
    }[status]

    print(f"\n========== [{group}]")
    print(f"🔹 Status: {status_display}")
    print(output.strip())
    print("\n==========================================================================================================================\n")

    if background_tasks:
        await asyncio.gather(*background_tasks)

    return returncode

# === Главная точка входа ===
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

    processed_groups = set()
    results = await asyncio.gather(*(run_playbook(m, processed_groups) for m in matches))

    if any(code != 0 for code in results):
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
