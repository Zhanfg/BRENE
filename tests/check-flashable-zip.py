#!/usr/bin/env python3
"""Verify the exact ZIP selected in KernelSU/SukiSU is directly flashable.

Actions/upload-artifact@v4 wraps the module ZIP in a *second ZIP*.
Older BRENE CI passed unzip -t on the inner module ZIP, which didn't
verify the actual file a user downloaded from Actions.
"""
import sys
import zipfile
import re
from pathlib import PurePosixPath

REQUIRED = {
    "module.prop", "customize.sh", "config.sh", "post-fs-data.sh",
    "boot-completed.sh", "autoshield.sh", "kstat-rules.sh",
    "tools/susfs", "webroot/index.html", "webroot/script.js",
}


def check(path: str) -> None:
    if not zipfile.is_zipfile(path):
        raise ValueError(f"{path}: not a valid ZIP")
    with zipfile.ZipFile(path) as package:
        bad_member = package.testzip()
        if bad_member:
            raise ValueError(f"ZIP CRC check failed: {bad_member}")
        members = package.namelist()
        if len(members) != len(set(members)):
            raise ValueError("ZIP has duplicate member names")
        for name in members:
            normalized = PurePosixPath(name)
            if (
                name.startswith("/")
                or "\\" in name
                or name.startswith("./")
                or ".." in normalized.parts
            ):
                raise ValueError(f"Unsafe or noncanonical ZIP member: {name}")
        missing = sorted(REQUIRED.difference(members))
        if missing:
            nested = [x for x in members if x.lower().endswith(".zip")]
            raise ValueError(
                f"Missing module files at ZIP root: {missing}. "
                + (
                    f"Found nested ZIP(s) instead: {nested}. "
                    "Do not flash the GitHub Actions wrapper."
                    if nested else ""
                )
            )
        props = package.read("module.prop")
        if len(props) > 64 * 1024:
            raise ValueError("module.prop exceeds 64 KiB")
        lines = props.decode("utf-8").splitlines()
        prop = dict(
            line.split("=", 1)
            for line in lines
            if line and not line.lstrip().startswith("#") and "=" in line
        )
        if prop.get("id") != "brene":
            raise ValueError(f"Unexpected module ID: {prop.get('id')}")
        if not re.fullmatch(r"[0-9]+", prop.get("versionCode", "")):
            raise ValueError("Invalid versionCode")
        print(
            f"PASS: directly flashable: {path}; "
            f"module={prop['id']}; entries={len(members)}"
        )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: check-flashable-zip.py <zip>")
    try:
        check(sys.argv[1])
    except (ValueError, OSError, zipfile.BadZipFile, UnicodeError) as error:
        sys.exit(f"FAIL: {error}")
