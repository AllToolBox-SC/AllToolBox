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
import time
import threading
import queue
from datetime import datetime, timezone, timedelta
from tqdm import tqdm
from concurrent.futures import ThreadPoolExecutor, as_completed

CURRENT_BAR = None  # Global reference for refreshing progress bar after log output
DISPLAY = None  # Global display manager instance
LOG_PATH = os.path.join("./build", "build.log")

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

def log_line(text: str):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(text + "\n")

class DisplayManager:
    """单独渲染线程：固定高度进度块始终在底部，日志嵌入进度区内。"""
    FIXED_HEIGHT = 10  # 固定块高度，不足补空行，多余截断

    def __init__(self):
        self.q: queue.SimpleQueue = queue.SimpleQueue()
        self.progress_lines: list[str] = []
        self.recent_logs: list[str] = []
        self.last_frame: str = ""
        self.drawn = False  # 是否已经画过第一帧
        self.running = True
        self._cols = 80  # 终端列数缓存
        self.paused = False
        try:
            self._cols = os.get_terminal_size().columns
        except OSError:
            pass
        self.thread = threading.Thread(target=self._loop, daemon=True)
        self.thread.start()

    def log(self, text: str):
        self.q.put(("log", text))

    def set_progress(self, lines: list[str]):
        self.q.put(("progress", lines))

    def stop(self):
        self.running = False
        self.q.put(("stop", None))
        self.thread.join(timeout=2)
        if self.drawn:
            sys.stdout.write(f"\033[{self.FIXED_HEIGHT}F\033[J")
            sys.stdout.flush()

    def pause_for_input(self):
        """在需要交互输入前清理进度区，保证 prompt 可见。"""
        # 标记为暂停，停止渲染；清理已绘制的进度块
        self.paused = True
        if self.drawn:
            try:
                sys.stdout.write(f"\033[{self.FIXED_HEIGHT}F\033[J")
                sys.stdout.flush()
            finally:
                self.drawn = False

    def resume(self):
        """恢复渲染（在输入后调用）。"""
        # 解除暂停状态，允许渲染
        self.paused = False
        try:
            self._cols = os.get_terminal_size().columns
        except OSError:
            pass
        # 在渲染前确保光标在新行，避免覆盖刚刚输入的行
        try:
            sys.__stdout__.write("\n")
            sys.__stdout__.flush()
        except Exception:
            pass
        # 强制重绘当前帧
        try:
            self.last_frame = ""
            self._render()
        except Exception:
            pass

    def _truncate(self, s: str) -> str:
        """截断到终端宽度 - 1，防止自动换行导致光标错位。"""
        max_w = self._cols - 1
        if len(s) > max_w:
            return s[:max_w - 3] + "..."
        return s

    def _build_frame(self) -> list[str]:
        """构建固定高度的帧内容，所有行截断到终端宽度。"""
        lines = list(self.progress_lines)
        if self.recent_logs:
            lines.append("─── Log ───")
            lines.extend(self.recent_logs[-3:])
        # 截断每一行
        lines = [self._truncate(ln) for ln in lines]
        # 固定高度：不足补空行，多余截断
        while len(lines) < self.FIXED_HEIGHT:
            lines.append("")
        return lines[:self.FIXED_HEIGHT]

    def _render(self):
        frame = self._build_frame()
        frame_str = "\n".join(frame)
        if frame_str == self.last_frame:
            return  # 帧一致不重绘
        # 上移到块起始位置
        if self.drawn:
            sys.stdout.write(f"\033[{self.FIXED_HEIGHT}F")
        # 逐行覆写+清行尾
        for ln in frame:
            sys.stdout.write("\r" + ln + "\033[K\n")
        sys.stdout.flush()
        self.drawn = True
        self.last_frame = frame_str

    def _drain_queue(self) -> bool:
        """批量排空队列，返回是否遇到 stop 消息。"""
        while True:
            try:
                msg, payload = self.q.get_nowait()
            except queue.Empty:
                return False
            if msg == "stop":
                return True
            if msg == "log":
                self.recent_logs.append(payload)
                if len(self.recent_logs) > 3:
                    self.recent_logs.pop(0)
            elif msg == "progress":
                self.progress_lines = payload or []

    def _loop(self):
        while self.running:
            # 等待至少一条消息（或超时）
            try:
                msg, payload = self.q.get(timeout=0.25)
                if msg == "stop":
                    break
                if msg == "log":
                    self.recent_logs.append(payload)
                    if len(self.recent_logs) > 3:
                        self.recent_logs.pop(0)
                elif msg == "progress":
                    self.progress_lines = payload or []
            except queue.Empty:
                # 超时也刷新一次（保持周期渲染）
                self._render()
                continue
            # 批量排空剩余消息
            if self._drain_queue():
                break
            # 若处于暂停状态则不渲染
            if not self.paused:
                self._render()

class GradleProgressBar:
    """Gradle/pip 风格进度条，固定底部显示线程槽位和任务。"""
    def __init__(self, total_tasks, thread_capacity: int = 4, display: DisplayManager | None = None):
        self.total_tasks = max(1, int(total_tasks or 0))
        self.thread_capacity = max(1, thread_capacity)
        self.task_names: list[str] = []
        self.active_tasks: list[str] = []      # 当前运行中的任务（保持顺序）
        self.completed_set: set[str] = set()   # 仅记录真实完成任务
        self.lock = threading.Lock()
        self.last_height = 0
        self.display = display
        self.last_rendered_content = ""  # 缓存上次渲染的内容，用于比较
        self._update_display()  # 初始化立即渲染

    def _sync_total_locked(self):
        self.total_tasks = max(1, len(self.task_names))

    def add_task(self, task_name):
        with self.lock:
            if task_name not in self.task_names:
                self.task_names.append(task_name)
                self._sync_total_locked()
        self._update_display()

    def start_task(self, task_name):
        with self.lock:
            if task_name not in self.task_names:
                self.task_names.append(task_name)
                self._sync_total_locked()
            if task_name in self.completed_set:
                self.completed_set.remove(task_name)
            if task_name not in self.active_tasks:
                self.active_tasks.append(task_name)
        self._update_display()

    def complete_task(self, task_name):
        with self.lock:
            if task_name not in self.task_names:
                self.task_names.append(task_name)
                self._sync_total_locked()
            if task_name in self.active_tasks:
                self.active_tasks.remove(task_name)
            self.completed_set.add(task_name)
        self._update_display()

    def _update_display(self):
        with self.lock:
            total = max(1, self.total_tasks)
            completed = len(self.completed_set)

            if completed < 0:
                completed = 0
            if completed > total:
                completed = total

            bar_length = 30
            filled_length = int(bar_length * completed / total)
            filled_length = max(0, min(bar_length, filled_length))
            bar = '=' * filled_length + '.' * (bar_length - filled_length)
            percent = int(completed * 100 / total)
            percent = max(0, min(100, percent))
            active_count = len(self.active_tasks)
            active_count = min(active_count, self.thread_capacity)

            lines = []
            lines.append(f"Progress [{bar}] {percent:3d}% ({completed}/{total})")
            lines.append(f"> threads {self.thread_capacity} | active {active_count}")

            for i in range(self.thread_capacity):
                if i < active_count:
                    lines.append(f"< {self.active_tasks[i]}")
                else:
                    lines.append("< " + colorama.Fore.LIGHTBLACK_EX + "IDLE" + colorama.Fore.RESET)

            current_content = "\n".join(lines)
            if current_content != self.last_rendered_content:
                self.last_rendered_content = current_content
                if self.display:
                    self.display.set_progress(lines)

    def redraw(self):
        """供外部在产生新日志后重绘状态行。"""
        self._update_display()


def onerror(func):
    def handler(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            try:
                if DISPLAY:
                    DISPLAY.stop()
            except Exception:
                pass
            try:
                msg = f"Error during {func.__name__}: {e}"
                sys.__stdout__.write(colorama.Fore.RED + "E: " + colorama.Fore.RESET + msg + "\n")
                text = str(e)
                if "\n" in text:
                    sys.__stdout__.write("---- details ----\n")
                    sys.__stdout__.write(text + "\n")
                sys.__stdout__.write(f"See full log: {LOG_PATH}\n")
                sys.__stdout__.flush()
            except Exception:
                print(f"Error during {func.__name__}: {e}", file=sys.__stdout__)
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
def pyinstaller_cmd(
    python_exe: str,
    script: str,
    dist: str,
    debug: bool,
    upx_dir: str | None,
    workpath: str | None = None,
    specpath: str | None = None,
):
    # Use python -m PyInstaller to honor selected interpreter.
    cmd = [
        python_exe,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--clean",
        "--onefile",
        "--distpath",
        dist,
    ]
    if workpath:
        cmd.extend(["--workpath", workpath])
    if specpath:
        cmd.extend(["--specpath", specpath])
    if upx_dir and debug:
        cmd.append(f"--upx-dir={upx_dir}")
    if debug:
        cmd.extend(["-d", "all"])
    else:
        cmd.extend([
            "--exclude-module", "debughook",
            "--exclude-module", "debugpy",
            "--exclude-module", "pydevd",
            "--exclude-module", "unittest",
            "--exclude-module", "pytest",
            "--exclude-module", "pdb",
        ])
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
        for d in extra_dirs:  # prefer explicit/toolchain overrides
            if not d:
                continue
            candidate = os.path.join(d, name)
            if os.path.isfile(candidate):
                return candidate
        path = shutil.which(name)
        if path:
            return path
    return None


def _require_value(name: str, provided: str | None, default: str | None = None) -> str:
    """Return provided value, default, or prompt the user until non-empty."""
    if provided is not None and str(provided).strip() != "":
        return str(provided).strip()
    if default is not None:
        try:
            log_line(f"{name} = {default}")
        except Exception:
            pass
        return default
    while True:
        # 在输入前暂停渲染，确保 prompt 可见
        try:
            if DISPLAY:
                DISPLAY.pause_for_input()
        except Exception:
            pass
        try:
            # Write directly to real stdout, avoid being captured by DisplayManager
            sys.__stdout__.write(f"Enter {name}: ")
            sys.__stdout__.flush()
            line = sys.stdin.readline()
            if line is None:
                val = ""
            else:
                val = line.strip()
        finally:
            # Don't resume rendering here, wait until echo is done
            pass
        if val:
            # Echo input to real stdout first, to ensure user can see it
            try:
                # Only record to log file, not to terminal
                log_line(f"{name} = {val}")
            except Exception:
                pass
            try:
                if DISPLAY:
                    DISPLAY.resume()
            except Exception:
                pass
            return val
        # Empty input, resume rendering first then prompt error message
        try:
            if DISPLAY:
                DISPLAY.resume()
        except Exception:
            pass
        custom_write("Value cannot be empty, please re-enter.")


def collect_build_metadata(meta_inputs: dict[str, str | None], build_type: str) -> dict[str, str]:
    """Gather build metadata values with non-interactive defaults.

    Build type is locked by the compiler profile and cannot be overridden.
    """
    tz_cst = timezone(timedelta(hours=8), name="CST")
    now_cst = datetime.now(tz_cst)
    system_date_default = now_cst.strftime("%a %b %d %H:%M:%S %Z %Y")
    utc_epoch_default = str(int(time.time()))

    ro_build_version = (meta_inputs.get("ro.build.version") or now_cst.strftime("%Y.%m.%d.%H%M")).strip()
    soft_version = (meta_inputs.get("ro.product.current.softversion") or ro_build_version).strip()
    product_commit = (meta_inputs.get("ro.product.commit") or "local").strip()
    allow_xtc_value = str(meta_inputs.get("persist.atb.xtc.allow") or "False").strip()

    metadata = {
        "ro.alltoolbox.build.date": (meta_inputs.get("ro.alltoolbox.build.date") or system_date_default).strip(),
        "ro.build.type": build_type,
        "ro.build.version": ro_build_version,
        "ro.build.date.utc": (meta_inputs.get("ro.build.date.utc") or utc_epoch_default).strip(),
        "ro.product.current.softversion": soft_version,
        "ro.product.commit": product_commit,
        "persist.atb.xtc.allow": "True" if allow_xtc_value.lower() in ("1", "true", "yes", "y") else "False",
    }
    return metadata


def write_build_info_module(metadata: dict[str, str], target_path: str) -> None:
    allow_xtc = str(metadata.get("persist.atb.xtc.allow", "True")).lower() in ("1", "true", "yes", "y")
    lines = [
        "# -*- coding: utf-8 -*-",
        '"""Build-time locked metadata. Generated by build.py."""',
        "",
        f'BUILD_TYPE = {metadata.get("ro.build.type", "release")!r}',
        f"ALLOW_XTC = {str(bool(allow_xtc))}",
        "",
    ]
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    with open(target_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def install_build_requirements(python_exe: str, python_builder: int):
    common = [
        "py7zr==1.0.0",
        "tqdm==4.67.1",
        "requests==2.32.5",
        "prompt_toolkit==3.0.52",
        "colorama==0.4.6",
        "filehash==0.2.dev1",
    ]
    backend = ["nuitka==2.8.9"] if python_builder == 1 else ["pyinstaller==6.17.0"]
    packages = common + backend
    run_step([python_exe, "-m", "pip", "install", *packages], None)


@onerror
def download_dependency():
    url = ""
    if os.path.exists("bin.7z"):
        custom_write("bin.7z already exists.")
        return True
    if os.path.exists("binary_link.txt"):
        with open("binary_link.txt", "r") as f:
            url = f.read().strip()
    else:
        url_response = requests.get("https://atb.xgj.qzz.io/other/binary_link.txt", headers={"User-Agent":"pan.baidu.com"})
        url = url_response.text.strip()
    custom_write(f"Downloading bin.7z from {url} ...")
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        total_size = int(response.headers.get('content-length', 0))
        rows = os.get_terminal_size().lines
        with open("bin.7z", "wb") as f, tqdm(
            desc="Downloading",
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
            position=rows-1,
            leave=False
        ) as bar:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                bar.update(len(chunk))
        custom_write("Downloaded bin.7z successfully.")
        return True
    else:
        custom_write(f"Failed to download bin.7z. Status code: {response.status_code}")
        return False


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
        text = line.rstrip()
        log_line(text)
        if DISPLAY:
            DISPLAY.log(text)
    p.wait()
    if p.returncode != 0:
        error_msg = f"Command failed (exit {p.returncode}): {' '.join(map(str, cmd))}"
        log_line(error_msg)
        if DISPLAY:
            DISPLAY.log(error_msg)
        raise RuntimeError(error_msg)


def run_python_compilation_task(cmd, src_script, exe_name, bar, env=None):
    """运行编译任务，输出走日志不直接写控制台。"""
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=False,
        bufsize=1,
        env=env
    )
    captured_lines: list[str] = []
    for line_bytes in p.stdout:
        try:
            line = line_bytes.decode('gbk')
        except UnicodeDecodeError:
            line = line_bytes.decode('utf-8', errors='replace')
        text = line.rstrip()
        captured_lines.append(text)
        log_line(text)
        if DISPLAY:
            DISPLAY.log(text)
    p.wait()
    if p.returncode != 0:
        error_tail = "\n".join(captured_lines[-20:])
        raise RuntimeError(
            f"Command failed (exit {p.returncode}): {' '.join(map(str, cmd))}"
            + (f"\nLast output:\n{error_tail}" if error_tail else "")
        )


@onerror
def main(python_builder: int, profile: int, bmode: str, platform: str, builder: int, winsdk_dir: str | None, winsdk_include: str | None, mingw_bin_override: str | None, msvc_bin_override: str | None, msvc_include_override: str | None, meta_inputs: dict[str, str | None], max_threads: int = 4, batch: bool = False):
    # reset log file
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "w", encoding="utf-8") as _f:
        _f.write("[build] log start\n")
    custom_write("Build script running...")
    custom_write("Release build") if profile == 0 else custom_write("Debug Build")
    os.environ["PYTHONUTF8"] = "1"
    if not os.path.exists("./src/FileDialog/FileDialog.csproj"):
        custom_write("FileDialog.csproj not found, please recursively clone the repo. git clone --recurse-submodules <repo_url>")
        return 1
    upx_dir = find_upx_dir()
    if upx_dir:
        custom_write(f"Using UPX at: {upx_dir}")
    else:
        custom_write("UPX not found, skipping UPX compression (set UPX_DIR to enable).")
    rust_toolset = get_rust_target_triple()
    custom_write(f"Rust target triple: {rust_toolset}")
    dotnet_hint_dirs: list[str] = []
    dotnet_root = os.getenv("DOTNET_ROOT")
    if dotnet_root:
        dotnet_hint_dirs.append(dotnet_root)
        dotnet_hint_dirs.append(os.path.join(dotnet_root, "sdk"))
    dotnet_exe = resolve_tool(["dotnet.exe", "dotnet"], extra_dirs=dotnet_hint_dirs)
    if not dotnet_exe:
        raise RuntimeError("dotnet SDK not found. Install .NET SDK (x64) and set DOTNET_ROOT if needed.")
    custom_write(f"Using dotnet: {dotnet_exe}")
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
        os.path.basename(winsdk_dir.rstrip("/\\"))
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
    preferred_msvc_bin: str | None = None

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

    if vc_tools_dir and not preferred_msvc_bin:
        candidate_bin = os.path.join(vc_tools_dir, "bin", "Hostx64", "x64")
        if os.path.isdir(candidate_bin):
            preferred_msvc_bin = candidate_bin

    # Platform handling: win32 vs win64
    is_win32 = str(platform).lower() == "win32"
    # g++ arch flag (-m32 for 32-bit, -m64 for 64-bit)
    gxx_arch_flag = "-m32" if is_win32 else "-m64"
    # machine token for MSVC/cvtres
    msvc_machine = "X86" if is_win32 else "X64"
    # Nuitka compiler selection flag
    nuitka_compiler_flag = None
    if bmode == "mingw":
        nuitka_compiler_flag = "--mingw" if is_win32 else "--mingw64"
    elif bmode == "msvc":
        # Use generic MSVC selection for Nuitka. Recent Nuitka versions
        # do not accept --msvc-x86/--msvc-x64; use --msvc and let Nuitka
        # pick the proper toolchain (or rely on environment overrides).
        nuitka_compiler_flag = "--msvc=latest"

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

    # Prefer resolved toolchain bins to PATH to avoid mixing versions
    if winsdk_dir and winsdk_dir not in extra_bins:
        extra_bins.insert(0, winsdk_dir)
    if preferred_msvc_bin and preferred_msvc_bin not in extra_bins:
        extra_bins.insert(0, preferred_msvc_bin)

    # Log resolved include/lib paths once for debugging rc/cl/linker lookup
    if include_parts:
        custom_write("Resolved INCLUDE paths for rc/cl:")
        for p in include_parts:
            custom_write(f"  {p}")
    if lib_parts:
        custom_write("Resolved LIB paths for linker:")
        for p in lib_parts:
            custom_write(f"  {p}")

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
            custom_write("Warning: iconv.exe (MinGW/Extra bin) not found. This may cause encoding issues.")
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
        custom_write("Missing required tools:")
        for m in missing:
            custom_write(f" - {m}")
        custom_write("Please install/point MINGW64_BIN to your mingw64/bin (e.g. E:\\mingw64\\bin).")
        return 1
    else:
        custom_write(f"Using windres: {windres}")
        custom_write(f"Using g++: {gxx}")
    if not os.path.exists("bin.7z"):
        custom_write("Download bin.7z first...")
        result = download_dependency()
        if not result:
            custom_write("Failed to download dependency.")
            return 1

    os.makedirs("build", exist_ok=True)
    os.makedirs("./build/main", exist_ok=True)
    os.makedirs("./build/main/bin", exist_ok=True)
    os.makedirs("./build/rust", exist_ok=True)

    python_exe = pick_python_exe()
    custom_write(f"Using Python: {python_exe}")

    if not (os.path.exists("./.venv312/Scripts/python.exe") or os.path.exists("./.venv/Scripts/python.exe")):
        venv.create("./.venv312", with_pip=True)
        python_exe = os.path.join("./.venv312", "Scripts", "python.exe")

    # Initialize display manager and progress bar
    global DISPLAY
    DISPLAY = None if batch else DisplayManager()
    if batch:
        custom_write("Batch mode enabled: progress UI disabled, logging only.")

    # Calculate total tasks dynamically based on build configuration
    total_tasks = 0

    # Base tasks that always run
    total_tasks += 2  # icon generation and launcher build

    # Pip install task
    total_tasks += 1

    # Python compilation tasks (4 scripts regardless of PyInstaller vs Nuitka)
    total_tasks += 4

    # Additional build tasks that run in parallel
    total_tasks += 3  # rust build, filedialog build, extract binaries

    # Copy tasks
    total_tasks += 3  # copy files, copy executables, copy rust binaries

    # PDB files task (only in debug mode)
    if profile == 1:  # Only if debug mode
        total_tasks += 1

    # Metadata task
    total_tasks += 1

    gradle_bar = GradleProgressBar(total_tasks, thread_capacity=max_threads, display=DISPLAY)
    global CURRENT_BAR
    CURRENT_BAR = gradle_bar
    launcher_exe_path = "./build/main/launcher.exe"
    launcher_alias_path = "./build/main/双击运行.exe"

    if not builder:
        custom_write("Generating ICON Source")
        gradle_bar.start_task(":generate-icon-source")

        run_step(
            [windres, "-i", "./src/launch.rc", "-o", "./build/icon.o"],
            None  # No progress bar for this step since we're using gradle_bar
        )
        gradle_bar.complete_task(":generate-icon-source")
        custom_write("Building launcher")
        gradle_bar.start_task(":build-launcher")
        run_step(
            [gxx, "-static", "./src/launch.cpp", "./build/icon.o", "-municode",
            "-o", launcher_exe_path,
            "-finput-charset=UTF-8", "-fexec-charset=GBK",
            "-lstdc++", "-lpthread", "-O3", gxx_arch_flag],
            None  # No progress bar for this step since we're using gradle_bar
        ) if profile == 0 else run_step(
            [gxx, "-Wall", "-static", "./src/launch.cpp", "./build/icon.o", "-municode",
            "-o", launcher_exe_path,
            "-finput-charset=UTF-8", "-fexec-charset=GBK",
            "-lstdc++", "-lpthread", "-Og", gxx_arch_flag],
            None  # No progress bar for this step since we're using gradle_bar
        )
        gradle_bar.complete_task(":build-launcher")
    elif builder == 1:
        custom_write("Generating ICON Source")
        gradle_bar.start_task(":generate-icon-source")
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
        custom_write(f"Using rc: {rc_path}")
        run_step(
            [rc_path, "/nologo", "/fo", "build\\icon.res", *rc_include_flags, "src\\launch.rc"],
            None  # No progress bar for this step since we're using gradle_bar
        )
        cvtres_path = cvtres
        if not cvtres_path and msvc_bin_override:
            candidate = os.path.join(msvc_bin_override, "cvtres.exe")
            if os.path.isfile(candidate):
                cvtres_path = candidate
        if not cvtres_path:
            cvtres_path = "cvtres.exe"
        custom_write(f"Using cvtres: {cvtres_path}")
        run_step(
            [cvtres_path, f"/MACHINE:{msvc_machine}", "/out:build\\icon.obj", "build\\icon.res"],
            None  # No progress bar for this step since we're using gradle_bar
        )
        gradle_bar.complete_task(":generate-icon-source")
        custom_write("Building launcher")
        gradle_bar.start_task(":build-launcher")
        cl_path = cl
        if not cl_path and msvc_bin_override:
            candidate = os.path.join(msvc_bin_override, "cl.exe")
            if os.path.isfile(candidate):
                cl_path = candidate
        if not cl_path:
            cl_path = "cl.exe"
        custom_write(f"Using cl: {cl_path}")
        lib_flags = []
        for lp in lib_parts:
            lib_flags.append(f"/LIBPATH:{lp}")
        run_step(
            [cl_path, "/MT", "/EHsc", "/Fobuild/launch.obj", "src\\launch.cpp", ".\\build\\icon.obj", "/source-charset:utf-8", "/execution-charset:gbk", "/Fe:build\\main\\launcher.exe", "/O2", "/link", f"/MACHINE:{msvc_machine}", *lib_flags, "advapi32.lib", "user32.lib", "shell32.lib"],
            None  # No progress bar for this step since we're using gradle_bar
        ) if profile == 0 else run_step(
            [cl_path, "/MTd", "/EHsc", "/DEBUG", "/Zi", "/Fobuild/launch.obj", "/Fdbuild/main/launcher.pdb", "src\\launch.cpp", "build\\icon.obj", "/source-charset:utf-8", "/execution-charset:gbk", "/Fe:build\\main\\launcher.exe", "/Od", "/link", f"/MACHINE:{msvc_machine}", *lib_flags, "advapi32.lib", "user32.lib", "shell32.lib"],
            None  # No progress bar for this step since we're using gradle_bar
        )
        gradle_bar.complete_task(":build-launcher")

    # Keep historical Chinese filename as a best-effort alias.
    try:
        if os.path.isfile(launcher_exe_path):
            shutil.copy2(launcher_exe_path, launcher_alias_path)
            os.remove(launcher_exe_path)
    except Exception as e:
        custom_write(f"Warning: Failed to create launcher alias {launcher_alias_path}: {e}")

    custom_write("Installing build requirements")
    gradle_bar.start_task(":install-requirements")
    install_build_requirements(python_exe, python_builder)
    gradle_bar.complete_task(":install-requirements")

    # Execute remaining build tasks in parallel (these can use all threads)
    def rust_task():
        custom_write("Building Rust Sources")
        gradle_bar.start_task(":rust:build")
        run_step(
            ["cargo", "build", "--release", "--target-dir", "./build/rust"],
            None,  # No progress bar for this step since we're using gradle_bar
            shell=True
        ) if profile == 0 else run_step(
            ["cargo", "build", "--target-dir", "./build/rust"],
            None,  # No progress bar for this step since we're using gradle_bar
            shell=True
        )
        gradle_bar.complete_task(":rust:build")

    def filedialog_task():
        custom_write("Building FileDialog")
        gradle_bar.start_task(":filedialog:build")
        run_step(
            [dotnet_exe, "build", "./src/FileDialog/FileDialog.csproj", "-c", "Release", "-o", "./build/FileDialog/", "-p:BaseIntermediateOutputPath=../../build/FileDialog/obj/"],
            None  # No progress bar for this step since we're using gradle_bar
        ) if profile == 0 else run_step(
            [dotnet_exe, "build", "./src/FileDialog/FileDialog.csproj", "-c", "Debug", "-o", "./build/FileDialog/", "-p:BaseIntermediateOutputPath=../../build/FileDialog/obj/"],
            None  # No progress bar for this step since we're using gradle_bar
        )
        gradle_bar.complete_task(":filedialog:build")

    def extract_task():
        custom_write("Extracting Binaries")
        gradle_bar.start_task(":extract:binaries")
        with py7zr.SevenZipFile('bin.7z', mode='r') as z:
            z.extractall(path='./build/main/bin')
        gradle_bar.complete_task(":extract:binaries")

    locked_build_type = "release" if profile == 0 else "debug"
    metadata = collect_build_metadata(meta_inputs, locked_build_type)
    write_build_info_module(metadata, "./src/build_info.py")
    custom_write(f"Locked build type: {locked_build_type}")

    if python_builder == 1:
        custom_write("Preparing Nuitka")
        # CI/non-interactive safety: avoid blocking on first-time dependency downloads.
        os.environ["NUITKA_ASSUME_YES_FOR_DOWNLOADS"] = "1"
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

        # Define the Python compilation tasks
        python_scripts = [
            ("run_cmd.py", "run_cmd.exe"),
            ("repair.py", "repair.exe"),
            ("menu.py", "menu.exe"),
            ("start.py", "main.exe")
        ]

        # Determine the number of threads to use for Nuitka compilation.
        # For MinGW, force single-worker to avoid concurrent access to Nuitka's
        # shared WinLibs download/cache artifacts on CI (WinError 32 file lock).
        if bmode == "mingw":
            nuitka_max_threads = 1
        else:
            nuitka_max_threads = min(max_threads, 2)

        # Prepare commands based on profile
        commands = []
        nuitka_non_interactive_flags = ["--assume-yes-for-downloads"]
        for src_script, exe_name in python_scripts:
            if profile == 0:  # Release build
                cmd = [python_exe, "-m", "nuitka",
                       "--onefile", "--lto=yes", "--python-flag=-OO", "--remove-output",
                       *nuitka_non_interactive_flags,
                       "--output-dir=./build/py/dist",
                       "--nofollow-import-to=debughook,debugpy,pydevd,pdb,unittest,pytest,test",
                       f"src/{src_script}", nuitka_compiler_flag]
            else:  # Debug build
                cmd = [python_exe, "-m", "nuitka",
                       "--onefile", "--lto=no", *nuitka_non_interactive_flags,
                       "--output-dir=./build/py/dist", "--debug", "--no-debug-c-warnings", "--debugger",
                       f"src/{src_script}", nuitka_compiler_flag]
            commands.append((cmd, src_script, exe_name))

        # Execute Python compilation tasks in parallel with limited threads for Nuitka
        def nuitka_task(cmd, src_script, exe_name):
            gradle_bar.start_task(f":nuitka:{src_script.replace('.py', '')}")
            try:
                run_python_compilation_task(cmd, src_script, exe_name, None)
            finally:
                gradle_bar.complete_task(f":nuitka:{src_script.replace('.py', '')}")

        with ThreadPoolExecutor(max_workers=nuitka_max_threads) as nuitka_executor:
            nuitka_futures = []
            for cmd, src_script, exe_name in commands:
                future = nuitka_executor.submit(nuitka_task, cmd, src_script, exe_name)
                nuitka_futures.append(future)

            # Wait for all Nuitka tasks to complete
            for future in as_completed(nuitka_futures):
                try:
                    future.result()
                except Exception as e:
                    # Stop progress rendering thread to prevent error messages from being cleared
                    try:
                        if DISPLAY:
                            DISPLAY.stop()
                    except Exception:
                        pass
                    # Write directly to real terminal stdout to ensure visibility
                    try:
                        msg = f"Error during Nuitka task: {e}"
                        sys.__stdout__.write(colorama.Fore.RED + "E: " + colorama.Fore.RESET + msg + "\n")
                        text = str(e)
                        if "\n" in text:
                            sys.__stdout__.write("---- details ----\n")
                            sys.__stdout__.write(text + "\n")
                        sys.__stdout__.write(f"See full log: {LOG_PATH}\n")
                        sys.__stdout__.flush()
                    except Exception:
                        print(f"Error during Nuitka task: {e}", file=sys.__stdout__)
                    raise
    else:
        # Define the Python compilation tasks for PyInstaller
        python_scripts = [
            ("run_cmd.py", "run_cmd.exe"),
            ("repair.py", "repair.exe"),
            ("menu.py", "menu.exe"),
            ("start.py", "main.exe")
        ]

        # Prepare commands based on profile
        commands = []
        for src_script, exe_name in python_scripts:
            script_stem = os.path.splitext(src_script)[0]
            script_workpath = os.path.join("./build/py/work", script_stem)
            script_specpath = os.path.join("./build/py/spec", script_stem)
            os.makedirs(script_workpath, exist_ok=True)
            os.makedirs(script_specpath, exist_ok=True)
            if profile == 0:  # Release build
                cmd = pyinstaller_cmd(
                    python_exe,
                    f"src/{src_script}",
                    "./build/py/dist",
                    debug=False,
                    upx_dir=upx_dir,
                    workpath=script_workpath,
                    specpath=script_specpath,
                )
            else:  # Debug build
                cmd = pyinstaller_cmd(
                    python_exe,
                    f"src/{src_script}",
                    "./build/py/dist",
                    debug=True,
                    upx_dir=upx_dir,
                    workpath=script_workpath,
                    specpath=script_specpath,
                )
            commands.append((cmd, src_script, exe_name, script_stem))

        # Execute Python compilation tasks in parallel with full thread count for PyInstaller
        def pyinstaller_task(cmd, src_script, exe_name, script_stem):
            gradle_bar.start_task(f":pyinstaller:{src_script.replace('.py', '')}")
            try:
                # Isolate PyInstaller cache/config per task to avoid parallel DLL lock conflicts.
                pyi_env = os.environ.copy()
                pyi_cache_root = os.path.join("./build/py/pyinstaller-cache", script_stem)
                os.makedirs(pyi_cache_root, exist_ok=True)
                pyi_env["PYINSTALLER_CONFIG_DIR"] = os.path.abspath(pyi_cache_root)
                run_python_compilation_task(cmd, src_script, exe_name, None, env=pyi_env)
            finally:
                gradle_bar.complete_task(f":pyinstaller:{src_script.replace('.py', '')}")

        with ThreadPoolExecutor(max_workers=max_threads) as py_executor:
            py_futures = []
            for cmd, src_script, exe_name, script_stem in commands:
                future = py_executor.submit(pyinstaller_task, cmd, src_script, exe_name, script_stem)
                py_futures.append(future)

            # Wait for all PyInstaller tasks to complete
            for future in as_completed(py_futures):
                try:
                    future.result()
                except Exception as e:
                    # Stop progress rendering thread to prevent error messages from being cleared
                    try:
                        if DISPLAY:
                            DISPLAY.stop()
                    except Exception:
                        pass
                    # Write directly to real terminal stdout to ensure visibility
                    try:
                        msg = f"Error during PyInstaller task: {e}"
                        sys.__stdout__.write(colorama.Fore.RED + "E: " + colorama.Fore.RESET + msg + "\n")
                        text = str(e)
                        if "\n" in text:
                            sys.__stdout__.write("---- details ----\n")
                            sys.__stdout__.write(text + "\n")
                        sys.__stdout__.write(f"See full log: {LOG_PATH}\n")
                        sys.__stdout__.flush()
                    except Exception:
                        print(f"Error during PyInstaller task: {e}", file=sys.__stdout__)
                    raise

    # Start the other build tasks in parallel using all available threads
    other_tasks_executor = ThreadPoolExecutor(max_workers=max_threads)

    # Submit remaining tasks to thread pool
    other_futures = []

    # Rust build
    other_futures.append(other_tasks_executor.submit(rust_task))

    # FileDialog build
    other_futures.append(other_tasks_executor.submit(filedialog_task))

    # Extract binaries
    other_futures.append(other_tasks_executor.submit(extract_task))

    # Wait for all other tasks to complete
    for future in as_completed(other_futures):
        try:
            future.result()
        except Exception as e:
            # Stop progress rendering thread to prevent error messages from being cleared
            try:
                if DISPLAY:
                    DISPLAY.stop()
            except Exception:
                pass
            # Write directly to real terminal stdout to ensure visibility
            try:
                msg = f"Error during other task: {e}"
                sys.__stdout__.write(colorama.Fore.RED + "E: " + colorama.Fore.RESET + msg + "\n")
                text = str(e)
                if "\n" in text:
                    sys.__stdout__.write("---- details ----\n")
                    sys.__stdout__.write(text + "\n")
                sys.__stdout__.write(f"See full log: {LOG_PATH}\n")
                sys.__stdout__.flush()
            except Exception:
                print(f"Error during other task: {e}", file=sys.__stdout__)
            # No longer raise exception, let @onerror decorator handle exit logic
            return 1

    # Shutdown the other tasks executor
    other_tasks_executor.shutdown(wait=True)

    # Move copy operations to the end of the build process
    gradle_bar.start_task(":copy:files")
    src = "./src/bats/"
    dst = "./build/main/bin"
    for root, _, files in os.walk(src):
        for file in files:
            src_path = os.path.join(root, file)
            rel = os.path.relpath(src_path, src)
            dst_path = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            shutil.copy2(src_path, dst_path)
    gradle_bar.complete_task(":copy:files")

    def find_py_output(names):
        dist = "./build/py/dist"
        # Fresh build folders may not have outputs in dist yet if backend names differ.
        # Try both canonical names and common emitted variants.
        candidates = []
        for n in names:
            candidates.append(os.path.join(dist, f"{n}.exe"))
            candidates.append(os.path.join(dist, f"{n}.bin.exe"))
            candidates.append(os.path.join(dist, f"{n}.dist", f"{n}.exe"))
            candidates.append(os.path.join(dist, f"{n}.dist", f"{n}.bin.exe"))
            candidates.append(os.path.join(dist, f"{n}.dist", "main.exe"))
        for candidate in candidates:
            if os.path.isfile(candidate):
                return candidate
        return None

    required = {
        "run_cmd": ["run_cmd"],
        "start": ["main", "start"],
        "repair": ["repair"],
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
        error_lines = ["Missing built executables:"]
        for m in missing:
            error_lines.append(f" - {m}")
        error_lines.append("PyInstaller/Nuitka likely failed earlier. Check build output above.")
        
        # 输出到日志和标准错误流
        for line in error_lines:
            custom_write(line)
            # 同时输出到标准错误流，确保用户能看到
            sys.stderr.write(line + "\n")
            sys.stderr.flush()
        
        return 1

    gradle_bar.start_task(":copy:executables")
    shutil.copy2(outputs["run_cmd"], "./build/main/bin/run_cmd.exe")
    shutil.copy2(outputs["start"], "./build/main/bin/main.exe")
    shutil.copy2(outputs["repair"], "./build/main/bin/repair.exe")
    shutil.copy2(outputs["menu"], "./build/main/bin/menu.exe")
    shutil.copy2("./build/FileDialog/FileDialog.exe", "./build/main/bin/FileDialog.exe")
    shutil.copy2("./build/FileDialog/FileDialog.exe.config", "./build/main/bin/FileDialog.exe.config")
    gradle_bar.complete_task(":copy:executables")

    if profile == 1:
        gradle_bar.start_task(":copy:pdb-files")
        shutil.copy2("./build/FileDialog/FileDialog.pdb", "./build/main/bin/FileDialog.pdb")
        if bmode == "msvc":
            try:
                shutil.copy2("build/py/dist/start.pdb", "./build/main/bin/main.pdb")
                shutil.copy2("build/py/dist/repair.pdb", "./build/main/bin/repair.pdb")
            except Exception as e:
                custom_write(f"Warning: Failed to copy PDB files: {e}")
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
                custom_write(f"Warning: Failed to copy PDB files: {e}")
        gradle_bar.complete_task(":copy:pdb-files")

    gradle_bar.start_task(":copy:rust-binaries")
    rust_out = "./build/rust/release" if profile == 0 else "./build/rust/debug"
    rust_bins = {
        "jsonutil.exe": os.path.join(rust_out, "jsonutil.exe"),
        "lolcat.exe": os.path.join(rust_out, "lolcat.exe"),
    }
    for name, src_path in rust_bins.items():
        if os.path.isfile(src_path):
            shutil.copy2(src_path, f"./build/main/bin/{name}")
        else:
            custom_write(f"Warning: Rust output not found: {src_path}")
    gradle_bar.complete_task(":copy:rust-binaries")

    custom_write("Build metadata locked in src/build_info.py (no runtime conf).")

    gradle_bar.total_tasks = len(gradle_bar.task_names) 
    for task in gradle_bar.task_names:
        if task not in gradle_bar.completed_set:
            gradle_bar.completed_set.add(task)
    gradle_bar._update_display()

    custom_write("Build completed.")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Build ATB.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Metadata defaults: ro.alltoolbox.build.date uses current CST time (e.g. Wed Dec 03 22:24:49 CST 2025); "
            "ro.build.date.utc uses current UTC epoch seconds. Build type is locked by -t (release/debug)."
        ),
    )
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
        "--platform",
        choices=["win32", "win64"],
        default="win64",
        help="Target platform: win32 or win64 (default: win64)"
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
    parser.add_argument(
        "--max-threads",
        type=int,
        default=4,
        help="Maximum number of threads to use for compilation (default: 4)"
    )
    parser.add_argument(
        "--batch",
        action="store_true",
        help="Disable progress UI and output logs only (recommended for CI)"
    )

    parser.add_argument("--ro-build-type", type=str, default=None, help="Deprecated: ignored. Build type is locked by -t")
    parser.add_argument("--ro-build-version", type=str, default=None, help="Value for ro.build.version")
    parser.add_argument("--ro-product-current-softversion", type=str, default=None, help="Value for ro.product.current.softversion")
    parser.add_argument("--ro-product-commit", type=str, default=None, help="Value for ro.product.commit")
    parser.add_argument("--ro-alltoolbox-build-date", type=str, default=None, help="Override ro.alltoolbox.build.date (default: current CST time, e.g. Wed Dec 03 22:24:49 CST 2025)")
    parser.add_argument("--ro-build-date-utc", type=str, default=None, help="Override ro.build.date.utc (default: current UTC epoch seconds)")
    parser.add_argument("--persist-atb-xtc-allow", type=str, default=None, help="Set locked persist.atb.xtc.allow in build_info (True/False)")
    colorama.init(autoreset=True)
    args = parser.parse_args()
    def custom_write(s):
        log_line(s)
        if DISPLAY:
            DISPLAY.log(s)
        else:
            # DISPLAY not initialized yet, write directly to terminal
            sys.__stdout__.write(s + "\n")
            sys.__stdout__.flush()
    tqdm.write = custom_write
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
    platform = args.platform
    locked_build_type = "release" if profile == 0 else "debug"

    if args.ro_build_type and args.ro_build_type.strip().lower() != locked_build_type:
        custom_write(
            f"Warning: --ro-build-type={args.ro_build_type} ignored; locked to {locked_build_type} by -t/--type."
        )

    meta_inputs = {
        "ro.alltoolbox.build.date": args.ro_alltoolbox_build_date,
        "ro.build.version": args.ro_build_version,
        "ro.build.date.utc": args.ro_build_date_utc,
        "ro.product.current.softversion": args.ro_product_current_softversion,
        "ro.product.commit": args.ro_product_commit,
        "persist.atb.xtc.allow": args.persist_atb_xtc_allow,
    }

    ret = 1
    try:
        ret = main(pybuilder, profile, bmode, platform, builder, args.winsdk_dir, args.winsdk_include, args.mingw_bin, args.msvc_bin, args.msvc_include, meta_inputs, args.max_threads, args.batch)
    finally:
        try:
            if DISPLAY:
                DISPLAY.stop()
        except Exception:
            pass
    sys.exit(ret)
