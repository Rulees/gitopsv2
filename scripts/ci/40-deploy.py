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

def debug_print(msg):
    print(f"[DEBUG] {msg}")

# === Чтение use_subservice_infra из playbook.yml ===
def extract_use_subservice_infra(playbook_path):
    debug_print(f"extract_use_subservice_infra: {playbook_path}")
    use_subservice_infra = True
    try:
        with open(playbook_path, 'r') as file:
            lines = file.readlines()
        for line in lines:
            debug_print(f"  usi_line: {line.rstrip()}")
            line = line.strip()
            if line.startswith("# use_subservice_infra:"):
                use_subservice_infra = line.split(":", 1)[1].strip().lower() == 'true'
                debug_print(f"  use_subservice_infra found: {use_subservice_infra}")
    except Exception as e:
        print(f"❌ Error reading use_subservice_infra from {playbook_path}: {e}")
    return use_subservice_infra

# === Парсинг зависимостей из комментариев в playbook.yml ===
def extract_dependencies(playbook_path):
    debug_print(f"extract_dependencies: {playbook_path}")
    dependencies = []
    try:
        with open(playbook_path, 'r') as file:
            lines = file.readlines()
        debug_print("  All lines in playbook:")
        for i, line in enumerate(lines):
            debug_print(f"    {i+1:03}: {line.rstrip()}")
        current = {}
        in_block = False
        for idx, line in enumerate(lines):
            orig_line = line.rstrip("\n")
            line = line.strip()
            if line.startswith("# dependencies:"):
                debug_print(f"  Found dependencies block at line {idx+1}")
                in_block = True
                continue
            if in_block:
                if line.startswith("#   - app:"):
                    if current:
                        dependencies.append(current)
                        debug_print(f"    Added dependency: {current}")
                    current = {"app": line.split(":", 1)[1].strip()}
                    debug_print(f"    Start new dependency: {current}")
                elif line.startswith("#     service:"):
                    current["service"] = line.split(":", 1)[1].strip()
                    debug_print(f"      Set service: {current['service']}")
                elif line.startswith("#     subservice:"):
                    current["subservice"] = line.split(":", 1)[1].strip()
                    debug_print(f"      Set subservice: {current['subservice']}")
                elif line.startswith("#     wait:"):
                    current["wait"] = line.split(":", 1)[1].strip()
                    debug_print(f"      Set wait: {current['wait']}")
                elif line.startswith("#     path:"):
                    current["path"] = line.split(":", 1)[1].strip()
                    debug_print(f"      Set path: {current['path']}")
                elif not line.startswith("#"):
                    if current:
                        dependencies.append(current)
                        debug_print(f"    Added last dependency: {current}")
                    debug_print("  End of dependencies block")
                    break
        if current:
            dependencies.append(current)
            debug_print(f"    Added last dependency at EOF: {current}")
    except Exception as e:
        print(f"❌ Error reading dependencies from {playbook_path}: {e}")
    debug_print(f"extract_dependencies returns: {dependencies}")
    return dependencies

# === Асинхронный запуск ansible-playbook ===
async def run_ansible_playbook(m, group, playbook):
    debug_print(f"run_ansible_playbook: group={group} playbook={playbook}")
    is_serverless = "serverless" in m["service"]
    cmd = [
        "ansible-playbook", str(playbook),
        "-e", f"env={m['env']}", "-e", f"app={m['app']}", "-e", f"service={m['service']}",
        "--diff"
    ]
    if not is_serverless:
        cmd += ["-i", str(ANSIBLE_DIR / "inventory" / "yc_compute.py"), "-l", group]

    debug_print(f"  CMD: {' '.join(cmd)}")
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(ANSIBLE_DIR),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT
    )
    stdout, _ = await proc.communicate()
    debug_print(f"  Return code: {proc.returncode}")
    debug_print(f"  Output (first 500 chars): {stdout.decode()[:500]}")
    return proc.returncode, stdout.decode()

# === Запуск одного playbook с учётом зависимостей ===
async def run_playbook(m, processed_groups, level=0):
    indent = "  " * level
    playbook = m["path"] / "playbook.yml"
    is_subservice = m.get("subservice") is not None

    debug_print(f"{indent}run_playbook: m={m}")

    # Проверяем use_subservice_infra для текущего playbook
    use_subservice_infra = True
    if is_subservice and playbook.exists():
        use_subservice_infra = extract_use_subservice_infra(playbook)
        debug_print(f"{indent}use_subservice_infra for {playbook}: {use_subservice_infra}")

    # Определяем параметры запуска
    if is_subservice and not use_subservice_infra:
        group = build_group_name(m["env"], m["app"], m["service"])
        m = m.copy()
        m.pop("subservice")
        debug_print(f"{indent}Subservice, but not using infra: new group={group}, m={m}")
    else:
        group = build_group_name(m["env"], m["app"], m["service"], m.get("subservice"))
        debug_print(f"{indent}group for deploy: {group}")

    if not playbook.exists():
        print(f"{indent}⚠️ Skipping {group}: playbook not found ({playbook})")
        return 1

    print(f"{indent}🚀 [DEPLOY]      {group}   {playbook}")

    # Извлекаем зависимости
    dependencies = extract_dependencies(playbook)
    debug_print(f"{indent}dependencies extracted: {dependencies}")
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

        print(f"{indent}[DEBUG] DEP: group={dep_group} path={dep_path} playbook_exists={dep_path / 'playbook.yml'} wait={dep.get('wait', 'true')}")
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
    print("\n" + "=" * 120 + "\n")

    if background_tasks:
        await asyncio.gather(*background_tasks)

    return returncode

# === Главная точка входа ===
async def main():
    print("[DEBUG] main() entry")
    os.chdir(find_project_root())
    env = os.getenv("ENV")
    app = os.getenv("APP")
    service = os.getenv("SERVICE")
    subservice = os.getenv("SUBSERVICE")
    debug_print(f"ENV={env} APP={app} SERVICE={service} SUBSERVICE={subservice}")

    matches = find_matching_services(env, app, service, subservice=subservice)
    debug_print(f"find_matching_services returned: {matches}")
    if not matches:
        print("⚠️ No matching services for deploy.")
        return

    print("📦 Matched groups:")
    for m in matches:
        print(f" - {build_group_name(m['env'], m['app'], m['service'], m.get('subservice'))}")

    processed_groups = set()
    results = await asyncio.gather(*(run_playbook(m, processed_groups) for m in matches))

    debug_print(f"run_playbook results: {results}")
    if any(code != 0 for code in results):
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())