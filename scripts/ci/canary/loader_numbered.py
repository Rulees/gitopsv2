#!/usr/bin/env python3
import importlib.util, re
from pathlib import Path

PATTERN = re.compile(r'^(\d{2})-(.+)\.py$')

def load_numbered_modules(directory: Path):
    """
    Загружает все файлы NN-name.py и возвращает dict:
      { logical_name: module_object }
    logical_name = name без префикса цифр, дефисы -> подчёркивания.
    Сортируем по числовому префиксу.
    """
    candidates = []
    for file in directory.iterdir():
        if file.is_file():
            m = PATTERN.match(file.name)
            if m:
                num, tail = m.groups()
                candidates.append((int(num), tail, file))

    candidates.sort(key=lambda x: x[0])

    modules = {}
    for num, tail, file in candidates:
        logical = tail.replace('-', '_')
        spec = importlib.util.spec_from_file_location(logical, str(file))
        mod = importlib.util.module_from_spec(spec)
        try:
            spec.loader.exec_module(mod)  # type: ignore
        except Exception as e:
            print(f"[loader] FAIL {file.name}: {e}")
            continue
        modules[logical] = mod
    return modules

if __name__ == "__main__":
    canary_dir = Path(__file__).parent
    mods = load_numbered_modules(canary_dir)
    print("Loaded modules:", ", ".join(mods.keys()))
