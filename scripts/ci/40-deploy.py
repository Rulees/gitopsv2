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

def extract_metadata(playbook_path):
    """Извлекает метаданные (use_subservice_infra, skip) из playbook.yml."""
    metadata = {
        "use_subservice_infra": True,  # По умолчанию True
        "skip": False                  # По умолчанию False
    }

    if not playbook_path.exists():
        return metadata
    
    try:
        with open(playbook_path, 'r') as file:
            for line in file:
                line = line.strip()
                if line.startswith("# use_subservice_infra:"):
                    metadata["use_subservice_infra"] = line.split(":", 1)[1].strip().lower() == 'true'
                elif line.startswith("# skip:"):
                    metadata["skip"] = line.split(":", 1)[1].strip().lower() == 'true'
    except Exception as e:
        print(f"❌ Error reading metadata from {playbook_path}: {e}")
    return metadata

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
                if line.startswith("#   - path_to_playbook:"):
                    if current:
                        dependencies.append(current)
                    parts = line.split(":", 1)[1].strip().split()
                    current = {
                        "path_to_playbook": parts,
                        "env": parts[0] if len(parts) > 0 else None,
                        "app": parts[1] if len(parts) > 1 else None,
                        "service": parts[2] if len(parts) > 2 else None,
                        "subservice": parts[3] if len(parts) > 3 else None,
                        "path_to_infra": None
                    }
                elif line.startswith("#     path_to_infra:"):
                    current["path_to_infra"] = line.split(":", 1)[1].strip()
                elif line.startswith("#     when_to_launch:"):
                    current["when_to_launch"] = line.split(":", 1)[1].strip()
                elif not line.startswith("#"):
                    if current:
                        dependencies.append(current)
                    break
        if current:
            dependencies.append(current)
    except Exception as e:
        print(f"❌ Error reading dependencies from {playbook_path}: {e}")
    return dependencies


def print_deploy_info(full_service_name, playbook, limit_group, infra_source_raw=None, indent=""):
    """
    Печатает информацию о развертывании, показывая SERVICE в поле 'group', 
    а фактический LIMIT хостов в отдельном поле 'limit'.
    """
    
    if infra_source_raw:
        limit_display = f"{limit_group}"
    else:
        limit_display = limit_group
    
    print(f"{indent}🚀 [DEPLOY] group:    {full_service_name}") 
    print(f"{indent}            playbook: {rel_path(playbook)}")
    print(f"{indent}            infra:    {limit_display}\n") 

def print_dependency(dep, indent=""):
    group_name = build_group_name(
        dep.get("env"),
        dep.get("app"),
        dep.get("service"),
        dep.get("subservice")
    )
    playbook_path_raw = ' '.join(dep.get("path_to_playbook", []))
    infra_source = dep.get("path_to_infra", "N/A")
    when_to_launch = dep.get("when_to_launch", "intime")
    print(f"{indent}   [deps: ] group:    {group_name}")
    print(f"{indent}            playbook: {playbook_path_raw}")
    print(f"{indent}            infra:    {infra_source}")
    print(f"{indent}            launch:   {when_to_launch}\n")


async def run_ansible_playbook(m, limit_group, playbook, deploy_status=None, start_at_task=None):
    is_serverless = "serverless" in m["service"]
    cmd = [
        "ansible-playbook", str(playbook),
        "-e", f"env={m['env']}", "-e", f"app={m['app']}", "-e", f"service={m['service']}",
        "--diff",
    ]
    
    if start_at_task:
        cmd.extend(["--start-at-task", start_at_task])

    if not is_serverless:
        limit = limit_group
        if deploy_status:
            limit = f"{limit_group}:&deploy_status_{deploy_status}"
        cmd += ["-i", str(ANSIBLE_DIR / "inventory" / "yc_compute.py"), "-l", limit]

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(ANSIBLE_DIR),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT
    )

    if proc.stdout:
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            print(line.decode().rstrip(), flush=True)

    await proc.wait()
    
    return proc.returncode, ""

async def run_playbook(m, processed_playbooks, level=0, deploy_status=None, start_at_task=None):
    indent = "  " * level
    
    playbook = m["path"] / "playbook.yml"
    is_subservice = m.get("subservice") is not None
    
    metadata = m.get("metadata", extract_metadata(playbook))
    
    use_subservice_infra = metadata["use_subservice_infra"] if is_subservice else True
    
    full_service_name = build_group_name(m["env"], m["app"], m["service"], m.get("subservice"))
    
    limit_group = ""
    infra_source_raw = m.get("path_to_infra")
    
    if infra_source_raw:
        infra_parts = infra_source_raw.split()
        
        if len(infra_parts) >= 3:
            infra_env = infra_parts[0]
            infra_app = infra_parts[1]
            infra_service = infra_parts[2]
            infra_subservice = infra_parts[3] if len(infra_parts) > 3 else None

            limit_group = build_group_name(infra_env, infra_app, infra_service, infra_subservice)
        else:
            print(f"❌ Ошибка: Некорректный path_to_infra: {infra_source_raw}. Использую дефолтную группу.")
            limit_group = full_service_name
    else:
        if is_subservice and not use_subservice_infra:
            limit_group = build_group_name(m["env"], m["app"], m["service"])
        else:
            limit_group = full_service_name
    
    
    playbook_key = str(playbook.resolve())
    if playbook_key in processed_playbooks:
        return 0
    processed_playbooks.add(playbook_key)

    if not playbook.exists():
        print(f"{indent}⚠️ Пропускаю {full_service_name}: playbook не найден")
        return 0

    print_deploy_info(full_service_name, playbook, limit_group, infra_source_raw, indent)

    # Извлекаем зависимости
    dependencies = extract_dependencies(playbook)
    background_tasks = []
    printed_playbooks = set()

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
            dep_path_full = dep_path / subservice
        else:
            dep_path_full = dep_path

        dep_playbook_path = dep_path_full / "playbook.yml"
        dep_metadata = extract_metadata(dep_playbook_path)
            
        dep["path"] = dep_path_full
        dep["metadata"] = dep_metadata 

        dep_playbook_file = dep["path"] / "playbook.yml"
        dep_playbook_key = str(dep_playbook_file.resolve())

        if dep_playbook_key not in printed_playbooks:
            print_dependency(dep, indent)
            printed_playbooks.add(dep_playbook_key)
        if dep_playbook_key in processed_playbooks:
            continue

        if dep.get("when_to_launch", "intime") == "intime":
            task = asyncio.create_task(run_playbook(dep, processed_playbooks, level + 1, deploy_status=deploy_status, start_at_task=start_at_task))
            background_tasks.append(task)
        else:
            await run_playbook(dep, processed_playbooks, level + 1, deploy_status=deploy_status, start_at_task=start_at_task)

    returncode, output = await run_ansible_playbook(m, limit_group, playbook, deploy_status=deploy_status, start_at_task=start_at_task)

    status = "SUCCESS" if returncode == 0 else "FAILED"
    status_display = {
        "SUCCESS": "\033[92m✔️✔️✔️✔️✔️✔️✔️✔️✔️✔️ SUCCESS\033[0m",
        "FAILED": "\033[91m❌❌❌❌❌❌❌❌❌❌ FAILED\033[0m"
    }

    # ‼️ ИЗМЕНЕНИЕ: Заголовок уже напечатан в run_ansible_playbook
    # print(f"\n========== [{group}]")
    print(f"🔹 {status_display.get(status, status)}")
    
    # ‼️ ИЗМЕНЕНИЕ: Вывод (output) уже напечатан, так что эта строка не нужна
    # print(output.strip())
    
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
    start_at_task = os.getenv("START_AT_TASK")

    all_matches = find_matching_services(env, app, service, subservice=subservice)
    if not all_matches:
        print("⚠️ No matching services for deploy.")
        return

    initial_matches = []
    is_specific_request = service is not None or subservice is not None
    
    print("\n==========================================================================================================================\n")
    for m in all_matches:
        playbook_path = m["path"] / "playbook.yml"
        metadata = extract_metadata(playbook_path)
        m["metadata"] = metadata
        
        # Фильтрация:
        if not is_specific_request and metadata["skip"]:
            print(f" - {build_group_name(m['env'], m['app'], m['service'], m.get('subservice'))} (skip: True)")
            continue
            
        initial_matches.append(m)


    if not initial_matches:
        print("⚠️ No matching services found for initial deploy after filtering.")
        return

    for m in initial_matches:
        print(f" - {build_group_name(m['env'], m['app'], m['service'], m.get('subservice'))}")
    print("\n==========================================================================================================================\n")

    processed_playbooks = set()
    
    results = await asyncio.gather(*(run_playbook(m, processed_playbooks, deploy_status=deploy_status, start_at_task=start_at_task) for m in initial_matches))

    if any(code != 0 for code in results):
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
