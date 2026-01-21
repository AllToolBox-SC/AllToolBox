# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import requests
import venv
import py7zr
import shutil
import argparse
import colorama
from tqdm import tqdm


def pick_python_exe():
    """Choose python executable preferring .venv312, then .venv, then current."""
    candidates = [
        os.path.join("./.venv312", "Scripts", "python.exe"),
        os.path.join("./.venv", "Scripts", "python.exe"),
        sys.executable,
    ]
    for c in candidates:
        if c and os.path.isfile(c):
            return c
    return sys.executable



def onerror(func):
    def handler(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            print(colorama.Fore.RED + "E: " + colorama.Fore.RESET + f"Error during {func.__name__}: {e}")
            sys.exit(1)
            
    return handler

@onerror
def find_upx_dir():
    """Locate UPX executable directory, preferring explicit env then common paths."""
    candidates = []

    upx_in_path = shutil.which("upx") or shutil.which("upx.exe")
    if upx_in_path:
        candidates.append(os.path.dirname(upx_in_path))

    env_upx = os.getenv("UPX_DIR") or os.getenv("UPXPATH")
    if env_upx:
        candidates.append(env_upx)

    candidates += [
        os.path.join(".", "upx"),
        os.path.join(".", "tools", "upx"),
        os.path.join(".", "bin"),
    ]

    for c in candidates:
        if not c:
            continue
        upx_exe = os.path.join(c, "upx.exe")
        if os.path.isfile(upx_exe):
            return c
    return None

@onerror
def pyinstaller_cmd(python_exe: str, script: str, dist: str, debug: bool, upx_dir: str | None):
    # Use python -m PyInstaller to honor selected interpreter.
    cmd = [python_exe, "-m", "PyInstaller", "--onefile", "--distpath", dist]
    if upx_dir:
        cmd.append(f"--upx-dir={upx_dir}")
    if debug:
        cmd.extend(["-d", "all", "--hidden-import", "debughook"])
    else:
        cmd.extend(["--exclude-module", "debughook"])
    cmd.append(script)
    return cmd


def get_rust_target_triple():
    result = subprocess.run(["rustc", "-vV"], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if line.startswith("host:"):
            return line.split()[1]
    return None


@onerror
def resolve_tool(candidates, extra_dirs=None):
    extra_dirs = extra_dirs or []
    for name in candidates:
        path = shutil.which(name)
        if path:
            return path
        for d in extra_dirs:
            if not d:
                continue
            candidate = os.path.join(d, name)
            if os.path.isfile(candidate):
                return candidate
    return None


@onerror
def download_dependency():
    url = ""
    if os.path.exists("bin.7z"):
        print("bin.7z already exists.")
        return True
    if os.path.exists("binary_link.txt"):
        with open("binary_link.txt", "r") as f:
            url = f.read().strip()
    else:
        url_response = requests.get("https://atb.xgj.qzz.io/other/binary_link.txt")
        url = url_response.text.strip()
    print(f"Downloading bin.7z from {url} ...")
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        total_size = int(response.headers.get('content-length', 0))
        with open("bin.7z", "wb") as f, tqdm(
            desc="Downloading",
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                bar.update(len(chunk))
        print("Downloaded bin.7z successfully.")
        return True
    else:
        print(f"Failed to download bin.7z. Status code: {response.status_code}")
        return False


@onerror
def run_step(cmd, bar, **kwargs):
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=False,
        bufsize=1,
        **kwargs
    )
    for line_bytes in p.stdout:
        try:
            line = line_bytes.decode('gbk')
        except UnicodeDecodeError:
            line = line_bytes.decode('utf-8', errors='replace')
        tqdm.write(line.rstrip())
    p.wait()
    bar.update(1)
    if p.returncode != 0:
        raise RuntimeError(f"Command failed (exit {p.returncode}): {' '.join(map(str, cmd))}")


@onerror
def main(python_builder: int, profile: int, bmode: str, builder: int, winsdk_dir: str | None, winsdk_include: str | None, mingw_bin_override: str | None, msvc_bin_override: str | None, msvc_include_override: str | None):
    print("Build script running...")
    print("Release build") if profile == 0 else print("Debug Build")
    os.environ["PYTHONUTF8"] = "1"
    if not os.path.exists("./src/FileDialog/FileDialog.csproj"):
        print("找不到 FileDialog.csproj， 请递归克隆仓库。git clone --recurse-submodules <repo_url>")
        return 1
    upx_dir = find_upx_dir()
    if upx_dir:
        print(f"Using UPX at: {upx_dir}")
    else:
        print("UPX not found, skipping UPX compression (set UPX_DIR to enable).")
    rust_toolset = get_rust_target_triple()
    print(f"Rust target triple: {rust_toolset}")
    dotnet_hint_dirs: list[str] = []
    dotnet_root = os.getenv("DOTNET_ROOT")
    if dotnet_root:
        dotnet_hint_dirs.append(dotnet_root)
        dotnet_hint_dirs.append(os.path.join(dotnet_root, "sdk"))
    dotnet_exe = resolve_tool(["dotnet.exe", "dotnet"], extra_dirs=dotnet_hint_dirs)
    if not dotnet_exe:
        raise RuntimeError("dotnet SDK not found. Install .NET SDK (x64) and set DOTNET_ROOT if needed.")
    print(f"Using dotnet: {dotnet_exe}")
    extra_bins = []
    for env_name in ("MINGW64_BIN", "MSYS2_MINGW64_BIN"):
        v = os.getenv(env_name)
        if v:
            extra_bins.append(v)
    if mingw_bin_override:
        extra_bins.append(mingw_bin_override)
    extra_bins.append(r"E:\mingw64\bin")
    if msvc_bin_override:
        extra_bins.append(msvc_bin_override)
    if winsdk_dir:
        extra_bins.append(winsdk_dir)

    # Resolve Windows SDK include root automatically if not provided.
    include_parts: list[str] = []
    resolved_winsdk_include = winsdk_include
    if not resolved_winsdk_include and winsdk_dir:
        # If winsdk_dir looks like .../bin/<ver>/<arch>, map to ../Include/<ver>
        arch_dir = os.path.basename(winsdk_dir.rstrip("/\\"))
        ver_dir = os.path.basename(os.path.dirname(winsdk_dir.rstrip("/\\")))
        bin_parent = os.path.dirname(os.path.dirname(winsdk_dir.rstrip("/\\")))
        candidate = os.path.join(bin_parent, "Include", ver_dir)
        if os.path.isdir(candidate):
            resolved_winsdk_include = candidate
    if not resolved_winsdk_include:
        sdk_root = os.getenv("WindowsSdkDir")
        sdk_ver = os.getenv("WindowsSdkVer")
        if sdk_root and sdk_ver:
            candidate = os.path.join(sdk_root, "Include", sdk_ver.strip("\\/"))
            if os.path.isdir(candidate):
                resolved_winsdk_include = candidate

    if resolved_winsdk_include:
        # Prepend provided/derived include roots and common subfolders so rc/cl can find Windows SDK headers.
        include_parts = [resolved_winsdk_include]
        for sub in ("ucrt", "shared", "um", "winrt", "cppwinrt"):
            candidate = os.path.join(resolved_winsdk_include, sub)
            if os.path.isdir(candidate):
                include_parts.append(candidate)

    # Collect MSVC include/lib paths (needed for std headers and link libs)
    vc_include_parts: list[str] = []
    vc_lib_parts: list[str] = []
    vc_tools_dir = None

    if msvc_bin_override:
        # Derive MSVC tools root and include from a bin path like .../MSVC/<ver>/bin/Hostx64/x64
        bin_root = os.path.normpath(msvc_bin_override)
        maybe_tools_root = os.path.normpath(os.path.join(bin_root, os.pardir, os.pardir, os.pardir))
        if os.path.isdir(maybe_tools_root):
            vc_tools_dir = maybe_tools_root
            candidate = os.path.join(maybe_tools_root, "include")
            if os.path.isdir(candidate):
                vc_include_parts.append(candidate)
            lib_candidate = os.path.join(maybe_tools_root, "lib", "x64")
            if os.path.isdir(lib_candidate):
                vc_lib_parts.append(lib_candidate)

    if not vc_tools_dir:
        vc_tools_dir = os.getenv("VCToolsInstallDir")
    if vc_tools_dir and not vc_include_parts:
        candidate = os.path.join(vc_tools_dir, "include")
        if os.path.isdir(candidate):
            vc_include_parts.append(candidate)
        lib_candidate = os.path.join(vc_tools_dir, "lib", "x64")
        if os.path.isdir(lib_candidate):
            vc_lib_parts.append(lib_candidate)
    if not vc_include_parts:
        vc_install = os.getenv("VCINSTALLDIR")
        if vc_install:
            candidate = os.path.join(vc_install, "include")
            if os.path.isdir(candidate):
                vc_include_parts.append(candidate)
        else:
            vs_install = os.getenv("VSINSTALLDIR")
            if vs_install:
                tools_root = os.path.join(vs_install, "VC", "Tools", "MSVC")
                if os.path.isdir(tools_root):
                    # Pick latest version folder
                    versions = sorted([d for d in os.listdir(tools_root) if os.path.isdir(os.path.join(tools_root, d))], reverse=True)
                    for ver in versions:
                        candidate = os.path.join(tools_root, ver, "include")
                        if os.path.isdir(candidate):
                            vc_include_parts.append(candidate)
                            lib_candidate = os.path.join(tools_root, ver, "lib", "x64")
                            if os.path.isdir(lib_candidate):
                                vc_lib_parts.append(lib_candidate)
                            break

    if not vc_include_parts:
        # Fallback: probe common VS install locations for latest MSVC include (2022/2019, x86 and x64 roots)
        pf86 = os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")
        pf = os.environ.get("ProgramW6432", r"C:\Program Files")
        vs_years = ("2022", "2019")
        editions = ("BuildTools", "Community", "Professional", "Enterprise")
        for root_base in (pf86, pf):
            for year in vs_years:
                for edition in editions:
                    tools_root = os.path.join(root_base, "Microsoft Visual Studio", year, edition, "VC", "Tools", "MSVC")
                    if not os.path.isdir(tools_root):
                        continue
                    versions = sorted([d for d in os.listdir(tools_root) if os.path.isdir(os.path.join(tools_root, d))], reverse=True)
                    for ver in versions:
                        candidate = os.path.join(tools_root, ver, "include")
                        if os.path.isdir(candidate):
                            vc_include_parts.append(candidate)
                            lib_candidate = os.path.join(tools_root, ver, "lib", "x64")
                            if os.path.isdir(lib_candidate):
                                vc_lib_parts.append(lib_candidate)
                            break
                    if vc_include_parts:
                        break
                if vc_include_parts:
                    break
            if vc_include_parts:
                break

    # Resolve Windows SDK lib paths (ucrt/um)
    sdk_lib_parts: list[str] = []
    if resolved_winsdk_include:
        # resolved_winsdk_include = .../Windows Kits/10/Include/<ver>
        version_dir = os.path.basename(resolved_winsdk_include)
        kits_root = os.path.dirname(os.path.dirname(resolved_winsdk_include))  # .../Windows Kits/10
        sdk_lib_base = os.path.join(kits_root, "Lib", version_dir)
        for sub in (os.path.join("ucrt", "x64"), os.path.join("um", "x64")):
            candidate = os.path.join(sdk_lib_base, sub)
            if os.path.isdir(candidate):
                sdk_lib_parts.append(candidate)

    # Fallback: allow searching MinGW/MSYS2 headers only if no MSVC headers were found
    mingw_include_parts: list[str] = []
    have_msvc_includes = bool(vc_include_parts or msvc_include_override)
    if not have_msvc_includes:
        for env_name in ("MINGW64_BIN", "MSYS2_MINGW64_BIN"):
            mingw_bin = os.getenv(env_name)
            if not mingw_bin:
                continue
            mingw_root = os.path.dirname(mingw_bin.rstrip("/\\"))
            for inc in (
                os.path.join(mingw_root, "include"),
                os.path.join(mingw_root, "x86_64-w64-mingw32", "include"),
            ):
                if os.path.isdir(inc):
                    mingw_include_parts.append(inc)
        if mingw_bin_override:
            mingw_root = os.path.dirname(mingw_bin_override.rstrip("/\\"))
            for inc in (
                os.path.join(mingw_root, "include"),
                os.path.join(mingw_root, "x86_64-w64-mingw32", "include"),
            ):
                if os.path.isdir(inc):
                    mingw_include_parts.append(inc)

    # Override MSVC include if explicitly provided
    if msvc_include_override:
        include_parts.append(msvc_include_override)
    include_parts.extend(vc_include_parts)
    if not have_msvc_includes:
        include_parts.extend(mingw_include_parts)
    if include_parts:
        include_chain = ";".join(include_parts)
        os.environ["INCLUDE"] = f"{include_chain};{os.environ.get('INCLUDE', '')}"

    # Assemble LIB paths
    lib_parts: list[str] = []
    lib_parts.extend(vc_lib_parts)
    lib_parts.extend(sdk_lib_parts)
    if lib_parts:
        lib_chain = ";".join(lib_parts)
        os.environ["LIB"] = f"{lib_chain};{os.environ.get('LIB', '')}"

    # Log resolved include/lib paths once for debugging rc/cl/linker lookup
    if include_parts:
        print("Resolved INCLUDE paths for rc/cl:")
        for p in include_parts:
            print(f"  {p}")
    if lib_parts:
        print("Resolved LIB paths for linker:")
        for p in lib_parts:
            print(f"  {p}")

    windres = resolve_tool(["windres.exe", "windres"], extra_bins) if builder == 0 else True
    gxx = resolve_tool(["g++.exe", "g++"], extra_bins) if builder == 0 else True
    iconv = resolve_tool(["iconv.exe", "iconv"], extra_bins) if builder == 0 else True
    dotnet = resolve_tool(["dotnet.exe", "dotnet"], extra_bins)
    cargo = resolve_tool(["cargo.exe", "cargo"], extra_bins)
    cl = resolve_tool(["cl.exe", "cl"], extra_bins) if builder == 1 else True
    rc = resolve_tool(["rc.exe", "rc"], extra_bins) if builder == 1 else True
    cvtres = resolve_tool(["cvtres.exe", "cvtres"], extra_bins) if builder == 1 else True
    missing = []
    if builder == 0 or bmode == "mingw":
        if not windres:
            missing.append("windres.exe (MinGW bin)")
        if not gxx:
            missing.append("g++.exe (MinGW GCC)")
        if not iconv:
            print("Warning: iconv.exe (MinGW/Extra bin) not found. This may cause encoding issues.")
    if builder == 1 or bmode == "msvc":
        if not cl:
            missing.append("cl.exe (MSVC toolchain)")
        if not rc:
            missing.append("rc.exe (Windows SDK)")
        if not cvtres:
            missing.append("cvtres.exe (MSVC toolchain)")
    if not cargo:
        missing.append("cargo.exe (Rust toolchain)")
    if not dotnet:
        missing.append("dotnet.exe (.NET SDK)")

    if missing:
        print("Missing required tools:")
        for m in missing:
            print(f" - {m}")
        print("Please install/point MINGW64_BIN to your mingw64/bin (e.g. E:\\mingw64\\bin).")
        return 1
    else:
        print(f"Using windres: {windres}")
        print(f"Using g++: {gxx}")
    if not os.path.exists("bin.7z"):
        print("Download bin.7z first...")
        result = download_dependency()
        if not result:
            print("Failed to download dependency.")
            return 1

    os.makedirs("build", exist_ok=True)
    os.makedirs("./build/main", exist_ok=True)
    os.makedirs("./build/main/bin", exist_ok=True)
    os.makedirs("./build/rust", exist_ok=True)

    python_exe = pick_python_exe()
    print(f"Using Python: {python_exe}")

    if not (os.path.exists("./.venv312/Scripts/python.exe") or os.path.exists("./.venv/Scripts/python.exe")):
        venv.create("./.venv312", with_pip=True)
        python_exe = os.path.join("./.venv312", "Scripts", "python.exe")

    steps = [
        "windres",
        "g++",
        "pip",
        "nuitka run_cmd",
        "nuitka repair",
        "nuitka start",
        "nuitka check",
        "nuitka menu",
        "cargo",
        "extract",
    ]

    with tqdm(
        total=len(steps),
        desc="Setting up ATB",
        unit="step",
        ncols=80,
        position=0,
        leave=True
    ) as bar:

        

        
        if not builder:
            bar.set_description("Generating ICON Source")

            run_step(
                [windres, "-i", "./src/launch.rc", "-o", "./build/icon.o"],
                bar
            )
            bar.set_description("Building launcher")
            run_step(
                [gxx, "-static", "./src/launch.cpp", "./build/icon.o", "-municode",
                "-o", "build/main/双击运行.exe".encode("utf-8"),
                "-finput-charset=UTF-8", "-fexec-charset=GBK",
                "-lstdc++", "-lpthread", "-O3"],
                bar
            ) if profile == 0 else run_step(
                [gxx, "-Wall", "-static", "./src/launch.cpp", "./build/icon.o", "-municode",
                "-o", "build/main/双击运行.exe".encode("utf-8"),
                "-finput-charset=UTF-8", "-fexec-charset=GBK",
                "-lstdc++", "-lpthread", "-Og"],
                bar
            )
        elif builder == 1:
            bar.set_description("Generating ICON Source")
            rc_include_flags = []
            for p in include_parts:
                # Pack /I with the path (quoted when needed) as a single arg so spaces are handled.
                rc_include_flags.append(f"/I\"{p}\"") if " " in p else rc_include_flags.append(f"/I{p}")
            rc_path = rc
            if not rc_path and msvc_bin_override:
                candidate = os.path.join(msvc_bin_override, "rc.exe")
                if os.path.isfile(candidate):
                    rc_path = candidate
            if not rc_path:
                rc_path = "rc.exe"
            print(f"Using rc: {rc_path}")
            run_step(
                [rc_path, "/nologo", "/fo", "build\\icon.res", *rc_include_flags, "src\\launch.rc"],
                bar
            )
            cvtres_path = cvtres
            if not cvtres_path and msvc_bin_override:
                candidate = os.path.join(msvc_bin_override, "cvtres.exe")
                if os.path.isfile(candidate):
                    cvtres_path = candidate
            if not cvtres_path:
                cvtres_path = "cvtres.exe"
            print(f"Using cvtres: {cvtres_path}")
            run_step(
                [cvtres_path, "/out:build\\icon.obj", "build\\icon.res"],
                bar
            )
            bar.set_description("Building launcher")
            cl_path = cl
            if not cl_path and msvc_bin_override:
                candidate = os.path.join(msvc_bin_override, "cl.exe")
                if os.path.isfile(candidate):
                    cl_path = candidate
            if not cl_path:
                cl_path = "cl.exe"
            print(f"Using cl: {cl_path}")
            lib_flags = []
            for lp in lib_parts:
                lib_flags.append(f"/LIBPATH:{lp}")
            run_step(
                [cl_path, "/MT", "/EHsc", "/Fobuild/launch.obj", "src\\launch.cpp", ".\\build\\icon.obj", "/source-charset:utf-8", "/execution-charset:gbk", "/Fe:build\\main\\双击运行.exe", "/O2", "/link", *lib_flags, "advapi32.lib", "user32.lib", "shell32.lib"],
                bar
            ) if profile == 0 else run_step(
                [cl_path, "/MTd", "/EHsc", "/DEBUG", "/Zi", "/Fobuild/launch.obj", "/Fdbuild/main/双击运行.pdb", "src\\launch.cpp", "build\\icon.obj", "/source-charset:utf-8", "/execution-charset:gbk", "/Fe:build\\main\\双击运行.exe", "/Od", "/link", *lib_flags, "advapi32.lib", "user32.lib", "shell32.lib"],
                bar
            )

        bar.set_description("Installing requirements")
        run_step(
            [python_exe, "-m", "pip", "install", "-r", "requirements.txt"],
            bar
        )

        if python_builder == 1:
            bar.set_description("Preparing Nuitka")
            gcc = os.path.dirname(
                subprocess.run(
                    ["cmd", "/c", "where", "gcc.exe"],
                    stdout=subprocess.PIPE
                ).stdout.decode("utf-8").replace("\r\n", "")
            )

            nuitka_gcc = os.getenv("LOCALAPPDATA") + r"\Nuitka\Nuitka\Cache\downloads\gcc\x86_64\14.2.0posix-19.1.1-12.0.0-msvcrt-r2\mingw64"
            if not os.path.exists(nuitka_gcc):
                os.makedirs(nuitka_gcc, exist_ok=True)
                os.symlink(gcc, nuitka_gcc + r"\bin")
            if profile == 0:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/run_cmd.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--nofollow-import-to=debughook"],
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/repair.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--nofollow-import-to=debughook"],
                    bar
                )

                bar.set_description("check.py -> check.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/check.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--nofollow-import-to=debughook"],
                    bar
                )

                bar.set_description("menu.py -> menu.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/menu.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--nofollow-import-to=debughook"],
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/start.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--nofollow-import-to=debughook"],
                    bar
                )
            else:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug", "--no-debug-c-warnings", "--debugger",
                    "src/run_cmd.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--include-module=debughook"],
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug", "--no-debug-c-warnings", "--debugger",
                    "src/repair.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--include-module=debughook"],
                    bar
                )

                bar.set_description("check.py -> check.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug", "--no-debug-c-warnings", "--debugger",
                    "src/check.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--include-module=debughook"],
                    bar
                )

                bar.set_description("menu.py -> menu.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug", "--no-debug-c-warnings", "--debugger",
                    "src/menu.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--include-module=debughook"],
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    [python_exe, "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug", "--no-debug-c-warnings", "--debugger",
                    "src/start.py", "--mingw" if bmode == "mingw" else "--msvc=latest", "--include-module=debughook"],
                    bar
                )
        else:
            if profile == 0:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/run_cmd.py", "./build/py/dist", debug=False, upx_dir=upx_dir),
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/repair.py", "./build/py/dist", debug=False, upx_dir=upx_dir),
                    bar
                )

                bar.set_description("check.py -> check.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/check.py", "./build/py/dist", debug=False, upx_dir=upx_dir),
                    bar
                )

                bar.set_description("menu.py -> menu.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/menu.py", "./build/py/dist", debug=False, upx_dir=upx_dir),
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/start.py", "./build/py/dist", debug=False, upx_dir=upx_dir),
                    bar
                )
            else:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/run_cmd.py", "./build/py/dist", debug=True, upx_dir=upx_dir),
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/repair.py", "./build/py/dist", debug=True, upx_dir=upx_dir),
                    bar
                )

                bar.set_description("check.py -> check.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/check.py", "./build/py/dist", debug=True, upx_dir=upx_dir),
                    bar
                )

                bar.set_description("menu.py -> menu.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/menu.py", "./build/py/dist", debug=True, upx_dir=upx_dir),
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    pyinstaller_cmd(python_exe, "src/start.py", "./build/py/dist", debug=True, upx_dir=upx_dir),
                    bar
                )

        bar.set_description("Building Rust Sources")
        run_step(
            ["cargo", "build", "--release", "--target-dir", "./build/rust"],
            bar,
            shell=True
        ) if profile == 0 else run_step(
            ["cargo", "build", "--target-dir", "./build/rust"],
            bar,
            shell=True
        )

        bar.set_description("Building FileDialog")
        run_step(
            [dotnet_exe, "build", "./src/FileDialog/FileDialog.csproj", "-c", "Release", "-o", "./build/FileDialog/", "-p:BaseIntermediateOutputPath=../../build/FileDialog/obj/"],
            bar
        ) if profile == 0 else run_step(
            [dotnet_exe, "build", "./src/FileDialog/FileDialog.csproj", "-c", "Debug", "-o", "./build/FileDialog/", "-p:BaseIntermediateOutputPath=../../build/FileDialog/obj/"],
            bar
        )

        bar.set_description("Extracting Binaries")
        with py7zr.SevenZipFile('bin.7z', mode='r') as z:
            z.extractall(path='./build/main/bin')
        bar.update(1)

    src = "./src/bats/"
    dst = "./build/main/bin"
    for root, dirs, files in os.walk(src):
        for file in files:
            src_path = os.path.join(root, file)
            rel = os.path.relpath(src_path, src)
            dst_path = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            shutil.copy2(src_path, dst_path)

    def find_py_output(names):
        dist = "./build/py/dist"
        for n in names:
            candidate = os.path.join(dist, f"{n}.exe")
            if os.path.isfile(candidate):
                return candidate
        return None

    required = {
        "run_cmd": ["run_cmd"],
        "start": ["main", "start"],
        "repair": ["repair"],
        "check": ["check"],
        "menu": ["menu"],
    }

    missing = []
    outputs = {}
    for key, names in required.items():
        found = find_py_output(names)
        if found:
            outputs[key] = found
        else:
            missing.append(f"{key} ({' / '.join(names)})")

    if missing:
        print("Missing built executables:")
        for m in missing:
            print(f" - {m}")
        print("PyInstaller/Nuitka likely failed earlier. Check build output above.")
        return 1

    shutil.copy2(outputs["run_cmd"], "./build/main/bin/run_cmd.exe")
    shutil.copy2(outputs["start"], "./build/main/bin/main.exe")
    shutil.copy2(outputs["repair"], "./build/main/bin/repair.exe")
    shutil.copy2(outputs["check"], "./build/main/bin/check.exe")
    shutil.copy2(outputs["menu"], "./build/main/bin/menu.exe")
    shutil.copy2("./build/FileDialog/FileDialog.exe", "./build/main/bin/FileDialog.exe")
    shutil.copy2("./build/FileDialog/FileDialog.exe.config", "./build/main/bin/FileDialog.exe.config")

    

    if profile == 1:
        shutil.copy2("./build/FileDialog/FileDialog.pdb", "./build/main/bin/FileDialog.pdb")
        if bmode == "msvc":
            try:
                shutil.copy2("build/py/dist/run_cmd.pdb", "./build/main/bin/run_cmd.pdb")
                shutil.copy2("build/py/dist/start.pdb", "./build/main/bin/main.pdb")
                shutil.copy2("build/py/dist/repair.pdb", "./build/main/bin/repair.pdb")
            except Exception as e:
                print(f"Warning: Failed to copy PDB files: {e}")
        if "msvc" in rust_toolset:
            try:
                pdbs = [
                    "jsonutil.pdb",
                    "lolcat.pdb",
                ]
                for pdb in pdbs:
                    src_pdb = os.path.join("./build/rust/debug", pdb)
                    if os.path.isfile(src_pdb):
                        shutil.copy2(src_pdb, f"./build/main/bin/{pdb}")
            except Exception as e:
                print(f"Warning: Failed to copy PDB files: {e}")

    rust_out = "./build/rust/release" if profile == 0 else "./build/rust/debug"
    rust_bins = {
        "jsonutil.exe": os.path.join(rust_out, "jsonutil.exe"),
        "lolcat.exe": os.path.join(rust_out, "lolcat.exe"),
    }
    for name, src_path in rust_bins.items():
        if os.path.isfile(src_path):
            shutil.copy2(src_path, f"./build/main/bin/{name}")
        else:
            print(f"Warning: Rust output not found: {src_path}")

    print("Build completed.")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build ATB.")
    parser.add_argument(
        "-t", "--type",
        choices=["release", "debug"],
        type=str.lower,
        default="release",
        help="Set build profile (release | debug). Default: release"
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--pyinstaller",
        action="store_true",
        help="Use PyInstaller (default)"
    )
    group.add_argument(
        "--nuitka",
        nargs="?",
        const="mingw",
        choices=["mingw", "msvc"],
        default=None,
        help="Use Nuitka with specified compiler (mingw | msvc). Default: mingw if --nuitka is set"
    )

    group1 = parser.add_mutually_exclusive_group()
    group1.add_argument(
        "--mingw",
        action="store_true",
        help="Use MinGW compiler for cpps"
    )
    group1.add_argument(
        "--msvc",
        action="store_true",
        help="Use MSVC compiler for cpps (Please ensure MSVC is properly set up in your environment)"
    )
    parser.add_argument(
        "--winsdk-dir",
        type=str,
        default=None,
        help="Windows SDK bin directory containing rc.exe (e.g. C:/Program Files (x86)/Windows Kits/10/bin/10.0.xxxxx.x/x64)"
    )
    parser.add_argument(
        "--winsdk-include",
        type=str,
        default=None,
        help="Windows SDK include directory (e.g. C:/Program Files (x86)/Windows Kits/10/Include/10.0.xxxxx.x)"
    )
    parser.add_argument(
        "--mingw-bin",
        type=str,
        default=None,
        help="Override MinGW bin directory (used for tool detection and include fallback)"
    )
    parser.add_argument(
        "--msvc-bin",
        type=str,
        default=None,
        help="Override MSVC bin/tools directory (used for tool detection when using /msvc)"
    )
    parser.add_argument(
        "--msvc-include",
        type=str,
        default=None,
        help="Override MSVC include directory (used to resolve std headers like stdarg.h)"
    )
    colorama.init(autoreset=True)
    args = parser.parse_args()
    

    if args.nuitka:
        pybuilder = 1
    else:
        pybuilder = 0
    builder = 0
    if args.mingw:
        builder = 0
    elif args.msvc:
        builder = 1
    profile = 0 if args.type == "release" else 1
    bmode = args.nuitka if args.nuitka else "pyinstaller"

    sys.exit(main(pybuilder, profile, bmode, builder, args.winsdk_dir, args.winsdk_include, args.mingw_bin, args.msvc_bin, args.msvc_include))
