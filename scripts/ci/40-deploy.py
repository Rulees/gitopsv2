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

# === Чтение use_subservice_infra из playbook.yml ===
def extract_use_subservice_infra(playbook_path):
    """Извлекаем параметр use_subservice_infra из комментариев в playbook.yml"""
    use_subservice_infra = True  # По умолчанию subservice деплоится на своём уровне
    try:
        with open(playbook_path, 'r') as file:
            lines = file.readlines()
        for line in lines:
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

# === Запуск одного playbook с учётом зависимостей ===
async def run_playbook(m, processed_groups, level=0, deploy_status=None):
    indent = "  " * level

    playbook = m["path"] / "playbook.yml"
    is_subservice = m.get("subservice") is not None

    # 1. Проверяем use_subservice_infra для текущего playbook
    use_subservice_infra = True
    if is_subservice and playbook.exists():
        use_subservice_infra = extract_use_subservice_infra(playbook)

    # 2. Определяем параметры запуска
    if is_subservice and not use_subservice_infra:
        # Берём playbook из subservice, но деплоим как service
        group = build_group_name(m["env"], m["app"], m["service"])
        m = m.copy()
        m.pop("subservice")
    else:
        group = build_group_name(m["env"], m["app"], m["service"], m.get("subservice"))

    if not playbook.exists():
        print(f"{indent}⚠️ Skipping {group}: playbook not found")
        return 1

    print(f"{indent}🚀 [DEPLOY]      {group}   {playbook}")

    # Извлекаем зависимости
    dependencies = extract_dependencies(playbook)
    background_tasks = []

    for dep in dependencies:
        dep = dep.copy()
        dep["env"] = m["env"]
        base = WORK_DIR / "infrastructure" / dep["env"]
        subservice = dep.get("subservice")

        if dep["app"] == "infra":
            dep_path = base / dep["service"]
        else:
            dep_path = base / "vpc" / dep["app"] / dep["service"]

        if subservice:
            dep_playbook_path = dep_path / subservice / "playbook.yml"
            dep_use_subservice_infra = True
            if dep_playbook_path.exists():
                dep_use_subservice_infra = extract_use_subservice_infra(dep_playbook_path)
            if not dep_use_subservice_infra:
                dep_group = build_group_name(dep["env"], dep["app"], dep["service"])
                dep = dep.copy()
                dep.pop("subservice")
            else:
                dep_group = build_group_name(dep["env"], dep["app"], dep["service"], subservice)
                dep_path = dep_path / subservice
        else:
            dep_group = build_group_name(dep["env"], dep["app"], dep["service"])

        dep["path"] = dep_path

        if dep_group not in processed_groups:
            processed_groups.add(dep_group)
            print(f"{indent}   [dependency]  {dep_group} ({'Async' if dep.get('wait', 'true') == 'false' else 'Sync'})")
            if dep.get("wait", "true") == "false":
                task = asyncio.create_task(run_playbook(dep, processed_groups, level + 1, deploy_status=deploy_status))
                background_tasks.append(task)
            else:
                await run_playbook(dep, processed_groups, level + 1, deploy_status=deploy_status)

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

    print("📦 Matched groups:")
    for m in matches:
        print(f" - {build_group_name(m['env'], m['app'], m['service'], m.get('subservice'))}")

    processed_groups = set()
    results = await asyncio.gather(*(run_playbook(m, processed_groups, deploy_status=deploy_status) for m in matches))

    if any(code != 0 for code in results):
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
