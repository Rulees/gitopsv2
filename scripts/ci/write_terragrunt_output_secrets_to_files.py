import os
import subprocess
import json

WORK_DIR = os.environ.get("WORK_DIR", ".")
ENV = os.environ.get("ENV", "dev")

def sub_vars(s):
    return s.replace("${WORK_DIR}", WORK_DIR).replace("${ENV}", ENV)

CASES = {
    f"infrastructure/{ENV}/vpc/atlas/postgresql": [
        {
            "file": f"{WORK_DIR}/secrets/{ENV}/atlas/service_database/.env",
            "jq": 'to_entries | .[] | "\(.key)=\(.value.value)"'
        }
        # ,
        # {
        #     "file": f"{WORK_DIR}/secrets/{ENV}/atlas/service_sex/.env",
        #     "jq": 'to_entries | .[] | "\\(.key)=\\(.value.value)"'
        # }
    ],
    f"infrastructure/{ENV}/vpc/home/postgresql": [
        {
            "file": f"{WORK_DIR}/secrets/{ENV}/home/service_database/.env",
            "jq": 'to_entries | .[] | "\\(.key)=\\(.value.value)"'
        }
    ]
}

def read_env_file(filepath):
    """Reads an .env file to dict and list of lines (preserving comments/order)."""
    env = {}
    lines = []
    if not os.path.exists(filepath):
        return env, lines
    with open(filepath, "r") as f:
        for line in f:
            stripped = line.rstrip("\n")
            if not stripped or stripped.lstrip().startswith("#") or "=" not in stripped:
                lines.append(stripped)
                continue
            key, val = stripped.split("=", 1)
            env[key] = val
            lines.append(stripped)
    return env, lines

def merge_env(original_lines, current_env, new_env):
    """Update/add only keys present in new_env, preserve others and comments."""
    merged = []
    seen = set()
    for line in original_lines:
        if not line or line.lstrip().startswith("#") or "=" not in line:
            merged.append(line)
            continue
        key, _ = line.split("=", 1)
        key_up = key.upper()
        if key_up in new_env:
            merged.append(f"{key_up}={new_env[key_up]}")
            seen.add(key_up)
        else:
            merged.append(line)
            seen.add(key_up)
    for key, val in new_env.items():
        if key not in seen:
            merged.append(f"{key}={val}")
    return merged

for tg_dir, actions in CASES.items():
    tg_dir = sub_vars(tg_dir)
    try:
        tg_output = subprocess.check_output(
            ["terragrunt", "output", "-json", "--working-dir", tg_dir], text=True
        )
    except subprocess.CalledProcessError as e:
        print(f"Terragrunt failed for {tg_dir}: {e}")
        continue
    for action in actions:
        env_file = sub_vars(action["file"])
        jq_rule = action["jq"]
        try:
            env_content = subprocess.check_output(
                ['jq', '-r', jq_rule],
                input=tg_output,
                text=True
            )
        except subprocess.CalledProcessError as e:
            print(f"jq failed for {tg_dir} ({env_file}): {e}")
            continue

        os.makedirs(os.path.dirname(env_file), exist_ok=True)
        current_env, original_lines = read_env_file(env_file)
        # Parse new values from jq output
        new_env = dict(
            (line.split("=", 1)[0].upper(), line.split("=", 1)[1])
            for line in env_content.splitlines() if "=" in line
        )
        merged = merge_env(original_lines, current_env, new_env)
        with open(env_file, "w") as f:
            for l in merged:
                f.write(l + "\n")
        print(f"{tg_dir} → {env_file} (updated keys: {', '.join(new_env.keys())})")
