#!/usr/bin/env python3
"""Check fresh-install defaults and preserve unknown/old persisted settings."""
from pathlib import Path
import re

source = Path("module/config.sh").read_text(encoding="utf-8").splitlines()
defaults = {}
for line in source:
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if "=" not in line:
        raise SystemExit(f"Malformed config line: {line!r}")
    key, value = line.split("=", 1)
    if not re.fullmatch(r"[A-Z_]+|config_[a-z0-9_]+", key):
        raise SystemExit(f"Invalid config key: {key}")
    if key in defaults:
        raise SystemExit(f"Duplicate config key: {key}")
    defaults[key] = value
checks = {
    "config_shrink_buffer_size": "0",
    "config_hide_ksu_directories": "0",
    "config_auto_hide": "0",
    "config_use_custom_cmdline_or_bootconfig": "0",
}
for key, value in checks.items():
    if defaults.get(key) != value:
        raise SystemExit(f"Unsafe/missing fresh-install default: {key}={defaults.get(key)!r}")
print(f"PASS: {len(defaults)} valid unique configuration keys; opt-in defaults preserved")
