#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#Made by AHA
from pathlib import Path
import argparse
import sys


def find_build_conf(explicit: str | None = None) -> Path | None:
    candidates = []
    if explicit:
        p = Path(explicit)
        if p.is_file():
            return p
        return None

    base = Path(__file__).resolve().parent
    candidates += [
        base / ".." / "conf" / "build.conf",
        base / "conf" / "build.conf",
        base.parent / "conf" / "build.conf",
        base / ".." / "bin" / "conf" / "build.conf",
        Path.cwd() / "conf" / "build.conf",
        Path("conf/build.conf"),
        Path("build/main/bin/conf/build.conf"),
        Path("./build/main/bin/conf/build.conf"),
    ]
    seen = set()
    for c in candidates:
        try:
            c = c.resolve()
        except Exception:
            c = c
        if str(c) in seen:
            continue
        seen.add(str(c))
        if c.is_file():
            return c
    return None


def read_conf_lines(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8", errors="surrogateescape") as f:
        return f.readlines()


def write_conf_lines(path: Path, lines: list[str]) -> None:
    with path.open("w", encoding="utf-8", errors="surrogateescape") as f:
        f.writelines(lines)


def set_conf_key(lines: list[str], key: str, value: str) -> list[str]:
    key_eq = key + "="
    found = False
    out = []
    for ln in lines:
        stripped = ln.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            out.append(ln)
            continue
        k, rest = ln.split("=", 1)
        if k.strip() == key:
            out.append(f"{key}={value}\n")
            found = True
        else:
            out.append(ln)
    if not found:
        # append at end with newline
        if len(out) and not out[-1].endswith("\n"):
            out[-1] = out[-1] + "\n"
        out.append(f"{key}={value}\n")
    return out


def main():
    parser = argparse.ArgumentParser(description="Force-enable persist.atb.xtc.allow in build.conf")
    parser.add_argument("--path", "-p", type=str, default=None, help="指定 build.conf 的路径（可选）")
    parser.add_argument("--lock", action="store_true", help="同时写入 persist.xtc_allow_lock_True=True")
    args = parser.parse_args()

    # If user explicitly sets --path, ensure that path exists (create dirs + file if missing)
    conf_path: Path | None = None
    if args.path:
        candidate = Path(args.path)
        if not candidate.exists():
            candidate.parent.mkdir(parents=True, exist_ok=True)
            candidate.write_text("ro.build.type=release\n", encoding="utf-8")
            print(f"指定路径不存在，已创建新的 build.conf: {candidate}")
        conf_path = candidate
    else:
        conf_path = find_build_conf(None)
        if not conf_path:
            print("未找到 build.conf，尝试在当前工作目录或常见位置创建 conf/build.conf 以便写入。")
            candidate = Path.cwd() / "conf" / "build.conf"
            candidate.parent.mkdir(parents=True, exist_ok=True)
            conf_path = candidate
            if not conf_path.exists():
                conf_path.write_text("ro.build.type=release\n", encoding="utf-8")
                print(f"已创建新的 build.conf: {conf_path}")

    print(f"使用 build.conf: {conf_path}")
    lines = read_conf_lines(conf_path)
    lines = set_conf_key(lines, "persist.atb.xtc.allow", "True")
    if args.lock:
        lines = set_conf_key(lines, "persist.xtc_allow_lock_True", "True")
    write_conf_lines(conf_path, lines)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(2)
