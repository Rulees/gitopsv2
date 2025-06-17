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

def rel_path(path):
    path = str(path)
    for base in [str(WORK_DIR), str(WORK_DIR / "infrastructure")]:
        if path.startswith(base):
            return path[len(base):].lstrip("/")
    return path

# === Чтение use_subservice_infra из playbook.yml ===
def extract_use_subservice_infra(playbook_path):
    use_subservice_infra = True
    try:
        with open(playbook_path, 'r') as file:
            for line in file:
                line = line.strip()
                if line.startswith("# use_subservice_infra:"):
                    use_subservice_infra = line.split(":", 1)[1].strip().lower() == 'true'
    except Exception as e:
        print(f"❌ Error reading use_subservice_infra from {playbook_path}: {e}")
    return use_subservice_infra

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
                elif line.startswith("#     subservice:"):
                    current["subservice"] = line.split(":", 1)[1].strip()
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

def print_deploy_info(group, playbook, m, use_subservice_infra, is_subservice, indent=""):
    infra_path = m['path'].parent if is_subservice and not use_subservice_infra else m['path']
    infra_short = rel_path(infra_path)
    playbook_short = rel_path(playbook)
    print(f"{indent}🚀 [DEPLOY] group:    {group}")
    print(f"{indent}            playbook: {playbook_short}")
    print(f"{indent}            infra:    {infra_short}\n")

def print_dependency(dep, indent=""):
    infra_short = rel_path(dep["path"].parent if dep.get("subservice") and not dep.get("use_subservice_infra", True) else dep["path"])
    playbook_short = rel_path(dep['path'] / 'playbook.yml')
    print(f"{indent}   [deps: ] playbook: {playbook_short}")
    print(f"{indent}            infra:    {infra_short}")
    print(f"{indent}            type:     {'Async' if dep.get('wait', 'true') == 'false' else 'Sync'}\n")

# === Асинхронный запуск ansible-playbook ===
async def run_ansible_playbook(m, group, playbook, deploy_status=None):
    is_serverless = "serverless" in m["service"]
    cmd = [
        "ansible-playbook", str(playbook),
        "-e", f"env={m['env']}", "-e", f"app={m['app']}", "-e", f"service={m['service']}",
        "--diff"
    ]
    if not is_serverless:
        limit = group
        if deploy_status:
            limit = f"{group}:&deploy_status_{deploy_status}"
        cmd += ["-i", str(ANSIBLE_DIR / "inventory" / "yc_compute.py"), "-l", limit]

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(ANSIBLE_DIR),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT
    )
    stdout, _ = await proc.communicate()
    return proc.returncode, stdout.decode()

async def run_playbook(m, processed_playbooks, level=0, deploy_status=None):
    indent = "  " * level

    playbook = m["path"] / "playbook.yml"
    is_subservice = m.get("subservice") is not None
    use_subservice_infra = m.get("use_subservice_infra", True)

    # Группа: если use_subservice_infra: false — group как у service, иначе с subservice
    if is_subservice and not use_subservice_infra:
        group = build_group_name(m["env"], m["app"], m["service"])
    else:
        group = build_group_name(m["env"], m["app"], m["service"], m.get("subservice"))

    playbook_key = str(playbook.resolve())
    if playbook_key in processed_playbooks:
        return 0
    processed_playbooks.add(playbook_key)

    if not playbook.exists():
        print(f"{indent}⚠️ Skipping {group}: playbook not found")
        return 1

    print_deploy_info(group, playbook, m, use_subservice_infra, is_subservice, indent)

    # Извлекаем зависимости
    dependencies = extract_dependencies(playbook)
    background_tasks = []
    printed_playbooks = set()

    for dep in dependencies:
        dep = dep.copy()
        dep["env"] = m["env"]
        base = WORK_DIR / "infrastructure" / dep["env"]
        subservice = dep.get("subservice")

        # ВОТ ЗДЕСЬ НЕ ТРОГАЙ ЛОГИКУ infra!
        if dep["app"] == "infra":
            dep_path = base / dep["service"]
        else:
            dep_path = base / "vpc" / dep["app"] / dep["service"]

        if subservice:
            dep_playbook_path = dep_path / subservice / "playbook.yml"
            dep_use_subservice_infra = True
            if dep_playbook_path.exists():
                dep_use_subservice_infra = extract_use_subservice_infra(dep_playbook_path)
            dep["path"] = dep_path / subservice
            dep["use_subservice_infra"] = dep_use_subservice_infra
        else:
            dep["path"] = dep_path
            dep["use_subservice_infra"] = True

        dep_playbook_file = dep["path"] / "playbook.yml"
        dep_playbook_key = str(dep_playbook_file.resolve())

        if dep_playbook_key not in printed_playbooks:
            print_dependency(dep, indent)
            printed_playbooks.add(dep_playbook_key)
        if dep_playbook_key in processed_playbooks:
            continue
    
        if dep.get("wait", "true") == "false":
            task = asyncio.create_task(run_playbook(dep, processed_playbooks, level + 1, deploy_status=deploy_status))
            background_tasks.append(task)
        else:
            await run_playbook(dep, processed_playbooks, level + 1, deploy_status=deploy_status)

    returncode, output = await run_ansible_playbook(m, group, playbook, deploy_status=deploy_status)

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
    subservice = os.getenv("SUBSERVICE")
    deploy_status = os.getenv("DEPLOY_STATUS")

    matches = find_matching_services(env, app, service, subservice=subservice)
    if not matches:
        print("⚠️ No matching services for deploy.")
        return

    print("\n==========================================================================================================================\n")
    print("📦 Matched groups:")
    for m in matches:
        print(f" - {build_group_name(m['env'], m['app'], m['service'], m.get('subservice'))}")
    print("\n==========================================================================================================================\n")

    processed_playbooks = set()
    results = await asyncio.gather(*(run_playbook(m, processed_playbooks, deploy_status=deploy_status) for m in matches))

    if any(code != 0 for code in results):
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
