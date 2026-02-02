import logging
import argparse
import os
import sys
import shutil
import platform
import time
import datetime
import asyncio
from typing import Optional, Tuple, Iterable, List
import ctypes
from concurrent.futures import ThreadPoolExecutor, as_completed
from prompt_toolkit import (
    print_formatted_text, 
    ANSI, 
    HTML, 
    prompt,
    PromptSession
)
from prompt_toolkit.styles import Style, merge_styles
from prompt_toolkit.shortcuts import clear, set_title
from prompt_toolkit.key_binding import KeyBindings, merge_key_bindings
from prompt_toolkit.application import Application
from prompt_toolkit.application.current import get_app
from prompt_toolkit.layout import Layout
from prompt_toolkit.layout.containers import Window
from prompt_toolkit.layout.controls import FormattedTextControl
from prompt_toolkit.mouse_events import MouseEventType, MouseButton
import colorama
import subprocess
import requests
import py7zr
import tqdm
import tkinter as tk
from tkinter import filedialog


def ensure_admin():
    """Elevate to admin on Windows if not already elevated."""
    if os.name != "nt":
        return
    try:
        if ctypes.windll.shell32.IsUserAnAdmin():
            return
    except Exception:
        return

    script = os.path.abspath(sys.argv[0])
    params = " ".join([f'"{a}"' if " " in a else a for a in sys.argv[1:]])
    try:
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, f'"{script}" {params}', None, 1)
    finally:
        sys.exit(0)


ensure_admin()

print("请选择bin目录")
root = tk.Tk()
root.withdraw()
chose = filedialog.askdirectory()
if not chose:
    print("未选择目录，已退出。")
    sys.exit(1)

from pathlib import Path
Path(chose).mkdir(parents=True, exist_ok=True)

# Logging setup
log_dir = Path("logs")
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / f"allrepairtool_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
logger = logging.getLogger("allrepairtool")
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler(log_file, encoding="utf-8")
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)
logger.info("Logger initialized at %s", log_file)


def pause_hint(message: str = "按任意键继续..."):
    try:
        input(message)
    except EOFError:
        pass

def download_file(url, filename, show_progress=True):
    import os
    import requests

    if not url or not url.startswith("http"):
        raise Exception(f"URL错误: {url}")

    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"}

    logger.info("Start download: %s -> %s", url, filename)

    try:
        r = requests.get(url, headers=headers, stream=True, timeout=30, verify=True)
        r.raise_for_status()
    except Exception as e:
        logger.exception("Download failed: %s", url)
        raise Exception(f"下载失败: {e}")

    total = int(r.headers.get("content-length", 0))
    bar = tqdm.tqdm(total=total if total > 0 else None, unit="B", unit_scale=True, desc=os.path.basename(filename), leave=False) if show_progress else None

    with open(filename, "wb") as f:
        for data in r.iter_content(chunk_size=1024 * 1024):
            if not data:
                continue
            f.write(data)
            if bar:
                bar.update(len(data))

    if bar:
        bar.close()
    logger.info("Download finished: %s", filename)
    print(f"下载{filename} 完成 .")
    return filename


def extract_archive(archive_path: str, dest_dir: str) -> None:
    """Extract 7z archive to dest_dir with best-effort cleanup of existing files."""
    dest = Path(dest_dir)
    dest.mkdir(parents=True, exist_ok=True)
    logger.info("Extracting %s -> %s", archive_path, dest_dir)
    with py7zr.SevenZipFile(archive_path, mode="r") as a:
        try:
            for name in a.getnames():
                target = dest / name
                if target.is_file():
                    try:
                        target.unlink()
                    except PermissionError:
                        pass
                elif target.is_dir():
                    # Keep directories; remove only if extraction will recreate files inside.
                    continue
        except Exception:
            # Fallback: ignore cleanup issues, attempt extraction anyway.
            pass
        a.extractall(path=dest)
    print(f"解压完成！")
    logger.info("Extract finished: %s", archive_path)
    try:
        os.remove(archive_path)
        logger.info("Removed archive: %s", archive_path)
    except Exception as exc:
        logger.warning("Failed to remove archive %s: %s", archive_path, exc)
    


class MultilineFormatter(logging.Formatter):
    def format(self, record):
        original = super().format(record)
        lines = original.splitlines()
        if len(lines) <= 1:
            return original
        prefix = lines[0][:len(lines[0]) - len(record.getMessage())]
        return '\n'.join([lines[0]] + [prefix + line for line in lines[1:]])

style = Style.from_dict({
    "yellow": "fg:#f1c40f",
    "red": "fg:#ff7b7b",
    "orange": "fg:#f4a261",
    "info": "fg:#3B78FF",
    "black": "fg:#0c1118",
    "cyan": "fg:#67e0c2",
    "green": "fg:#7ad1a8",
    "blue": "fg:#8ab4f8",
    "magenta": "fg:#c7a0ff",
    "white": "fg:#e6edf3",
    "reset": "",
    "number": "bold",
    "selected-option": "fg:#e6edf3 bold underline",
})

info = "<info>[信息]</info>"
error = "<red>[错误]</red>"
warn = "<orange>[警告]</orange>"
def run(cmd):
    subprocess.run(["cmd.exe", "/v:on", "/c", f'''
                    @echo off &
                    setlocal enabledelayedexpansion 1>nul 2>nul &
                    call .\\color.bat &
                    set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC; &
                    @{cmd} &
                    endlocal 1>nul 2>nul &
                    '''.replace("\n", "").replace(20*" ", "")])

def page_transition(text: str = "", duration: float = 0.35) -> None:
    """Simple console transition animation when switching pages."""
    msg = text.strip() or "正在切换..."
    frames = ["", ".", "..", "...", " ..", "  ."]
    end_time = time.monotonic() + duration
    width = len(msg) + 4
    while time.monotonic() < end_time:
        for frame in frames:
            if time.monotonic() >= end_time:
                break
            sys.stdout.write(f"\r{msg}{frame:<3}")
            sys.stdout.flush()
            time.sleep(max(duration / (len(frames) * 2), 0.02))
    sys.stdout.write("\r" + " " * width + "\r")
    sys.stdout.flush()
class Option:
    def __init__(self, value, label):
        self.value = value
        self.label = label
def menu_choice(
    message: str,
    options: Iterable[tuple],
    default: str | None = None,
    style_override: Style | None = None,
    extra_bindings: KeyBindings | None = None,
    header_text: str | None = None,
    header_click_callback=None,
):
    option_list: List[tuple] = list(options)
    if not option_list:
        raise ValueError("menu_choice requires at least one option")

    selected_index = 0
    display_index = 0
    animate_in = True
    visible_count = 0 if animate_in else len(option_list)
    move_task = None
    header_rows = 1 if header_text else 0

    if default is not None:
        for idx, (value, _) in enumerate(option_list):
            if value == default:
                selected_index = idx
                display_index = idx
                break

    kb = KeyBindings()

    @kb.add("enter", eager=True)
    @kb.add(" ", eager=True)
    def _(event):
        idx = selected_index or 0
        event.app.exit(result=option_list[idx][0])

    digit_buf = {"text": "", "t": 0.0}

    def _select_by_number(event, digit: str) -> None:
        now = time.monotonic()
        if now - digit_buf["t"] > 0.2:
            digit_buf["text"] = ""
        digit_buf["text"] += digit
        digit_buf["t"] = now
        try:
            idx = int(digit_buf["text"]) - 1
        except ValueError:
            return
        if 0 <= idx < len(option_list):
            _set_selection(idx, event.app)

    for d in "0123456789":
        @kb.add(d, eager=True)
        def _(event, _d=d):
            _select_by_number(event, _d)

    def _clamp(idx: int) -> int:
        count = len(option_list)
        return max(0, min(count - 1, idx))

    def _animate_move(target: int, app):
        nonlocal display_index, move_task
        if move_task and not move_task.done():
            move_task.cancel()

        async def _run():
            nonlocal display_index
            while display_index != target:
                step = 1 if display_index < target else -1
                display_index += step
                app.invalidate()
                await asyncio.sleep(0.02)
            app.invalidate()

        move_task = app.create_background_task(_run())

    def _set_selection(idx: int, app):
        nonlocal selected_index, display_index
        selected_index = _clamp(idx)
        _animate_move(selected_index, app)

    @kb.add("up")
    @kb.add("k")
    def _(event):
        _set_selection(selected_index - 1, event.app)

    @kb.add("down")
    @kb.add("j")
    def _(event):
        _set_selection(selected_index + 1, event.app)

    last_click = {"idx": None, "t": 0.0}

    def mouse_handler(mouse_event):
        nonlocal selected_index
        if mouse_event.event_type != MouseEventType.MOUSE_UP:
            return NotImplemented

        y = mouse_event.position.y
        if header_rows and y == 0:
            if header_click_callback:
                header_click_callback()
            return None

        if header_rows:
            y -= header_rows
        current_len = visible_count if animate_in else len(option_list)
        if current_len == 0:
            return None
        if 0 <= y < current_len:
            _set_selection(y, get_app())

        if mouse_event.event_type == MouseEventType.MOUSE_UP and mouse_event.button == MouseButton.LEFT:
            now = time.monotonic()
            idx = selected_index
            if idx == last_click["idx"] and (now - last_click["t"]) <= 0.5:
                value = option_list[idx][0]
                get_app().exit(result=value)
            last_click["idx"] = idx
            last_click["t"] = now
        return None

    def render_lines():
        fragments = []
        if header_text:
            fragments.append(("class:menu-header", header_text))
            fragments.append(("", "\n"))

        current_len = visible_count if animate_in else len(option_list)
        if current_len == 0:
            current_len = 1
        current_len = min(current_len, len(option_list))
        sel = min(display_index, current_len - 1)

        for idx, (_, label) in enumerate(option_list[:current_len]):
            pointer = ">" if idx == sel else " "
            prefix = f" {pointer} " if idx == sel else "   "
            text = f"{prefix}{idx + 1}. {label}"
            style_class = "class:radio-selected" if idx == sel else "class:radio"
            fragments.append((style_class, text))
            if idx != current_len - 1:
                fragments.append(("", "\n"))
        return fragments

    class MenuControl(FormattedTextControl):
        def __init__(self, render_fn, handler):
            super().__init__(render_fn, focusable=True, show_cursor=False)
            self._handler = handler

        def mouse_handler(self, mouse_event):
            return self._handler(mouse_event)

    control = MenuControl(render_lines, mouse_handler)
    window = Window(content=control, always_hide_cursor=True, dont_extend_width=True, dont_extend_height=True)

    radio_style = Style.from_dict(
        {
            "radio-list": "",
            "radio": "fg:#cbd6e2",
            "radio-selected": "fg:#e6edf3 bold underline",
            "radio-checked": "fg:#7ad1a8",
            "radio-number": "fg:#9dcffb bold",
        }
    )

    app_style = merge_styles([style_override, radio_style]) if style_override else radio_style

    kb_final = merge_key_bindings([kb, extra_bindings]) if extra_bindings else kb

    app = Application(
        layout=Layout(window, focused_element=control),
        key_bindings=kb_final,
        mouse_support=True,
        full_screen=False,
        style=app_style,
    )

    if animate_in:
        async def _animate_in():
            nonlocal visible_count, selected_index
            for i in range(1, len(option_list) + 1):
                visible_count = i
                if selected_index >= visible_count:
                    selected_index = visible_count - 1
                get_app().invalidate()
                await asyncio.sleep(0.03)
        app.pre_run_callables.append(lambda: app.create_background_task(_animate_in()))

    result = app.run()
    if result is None:
        sel = selected_index or 0
        result = option_list[sel][0]
    return result

def choose(message: str, options: Iterable[Option], default: str | None = None, extra_bindings: KeyBindings | None = None, header_text: str | None = None, header_click_callback=None):
    page_transition(message or "正在切换...")
    return menu_choice(
        message=message,
        options=options,
        default=default,
        style_override=style,
        extra_bindings=extra_bindings,
        header_text=header_text,
        header_click_callback=header_click_callback,
    )
def menu() -> str:
    kb = KeyBindings()
    print_formatted_text(ANSI("鼠标双击或按回车键确定，方向键，数字键，鼠标单击来选择功能"))
    def header_click():
        pass
    header = f"AllToolBox 联网修补工具"

    result = choose(
        message="",
        options=[
            ("full", "完整包修补（不包含ND03）"),
            ("shell", "下载脚本文件（包含ND03Root.bat）"),
            ("files", "下载文件夹（包含部分Root文件）"),
            ("Dll", "下载Dll文件"),
            ("ND03", "下载ND03-Root文件"),
            ("Conf", "下载最新正式版配置文件"),
            ("Other", "其他文件下载（有用）"),
            ("wipe", "wipe.img文件下载"),
            ("exe", "exe文件下载"),
            ("Unlock", "解除ATB-XTC限制补丁"),
            ("exit", "退出工具")
        ],
        default="full",
        extra_bindings=kb,
        header_text=header,
        header_click_callback=header_click,
    )

    clear(); return result
def logo():
    run("call logo")
def full():
    page_transition("完整修补ATB（不包含ND03文件）")
    tasks = [shell, files, dll, conf, other, wipe, exe]
    print_formatted_text(HTML(f"{info} 开始并行下载/解压，线程数=64"), style=style)
    logger.info("Running full download with 64 threads")
    errors: list[str] = []
    try:
        with ThreadPoolExecutor(max_workers=64) as executor:
            future_map = {executor.submit(fn, False): fn.__name__ for fn in tasks}
            for fut in as_completed(future_map):
                name = future_map[fut]
                try:
                    fut.result()
                except Exception as exc:
                    errors.append(f"{name}: {exc}")
                    logger.exception("Task %s failed", name)
                    print_formatted_text(HTML(f"{error} {name} 失败: {exc}"), style=style)
    except Exception as e:
        errors.append(str(e))
        logger.exception("Full run failed")
        print_formatted_text(HTML(f"{error} 执行完整修补时出错: {e}"), style=style)

    if errors:
        print_formatted_text(HTML(f"{warn} 完整修补完成但存在错误: {'; '.join(errors)}"), style=style)
    else:
        print_formatted_text(HTML(f"{info} 完整修补操作完成。"), style=style)
    pause_hint()
    return
def shell(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/Shell.7z?sign=cSsVChelV8sl9i43JXUnU2-cTzohXrSYj_HsLLnSGoE=:0"#2
    file="shell.7z"
    logger.info("Begin task shell")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def files(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/Files.7z?sign=V31ULZ50ojVncJSgfBallgxPpmjqv5_iXf_HQJuxyIE=:0"
    file="files.7z"
    logger.info("Begin task files")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def dll(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/dll.7z?sign=jLaJqCQqD75wAKsmoOja7YsY0ShFV9dZl0TEJIR0Zmo=:0"#5
    file="dll.7z"
    logger.info("Begin task dll")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def ND03(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/ND03.7z?sign=9sKN0gBnPt0bbjoWuufEyYzjXSXTSsKq_EcDG4fD_Hw=:0"
    file="ND03.7z"
    logger.info("Begin task ND03")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def conf(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/Conf.7z?sign=-i7OwoX56sSFWqda2P71NZR1QUPf1QHbq2Xp5udGnM0=:0"#1
    file="conf.7z"
    logger.info("Begin task conf")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def other(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/Other.7z?sign=yaFYvOjON3XN3WfXGmrwKKrNaAK5ewQQydMvwXdoSGM=:0"#4
    file="other.7z"
    logger.info("Begin task other")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def wipe(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/wipe.7z?sign=oeFihkkdjLK_oKPHnu-hvYtl7mGsLD109emy_RV4RSw=:0"#3
    file="wipe.7z"
    logger.info("Begin task wipe")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def exe(need_pause: bool = True):
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/exe.7z?sign=vChl-_WUgokPcQiNKkI9Y3XM3u7dGFqmVQZkl1DVrhI=:0"#6
    file="exe.7z"
    logger.info("Begin task exe")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    if need_pause:
        pause_hint()
def unlock():
    url="https://pan.xgj.qzz.io/d/123alldown-webdav/unlock.7z?sign=7vNi8ArDfchFDhM8yw4YR39vlhvAEeohlP0hNVGWt2A=:0"#7
    file="unlock.7z"
    logger.info("Begin task unlock")
    download_file(url, file)
    print("下载完成，开始解压...", flush=True)
    extract_archive(file, chose)
    page_transition("正在运行解除ATB-XTC限制补丁脚本...")
    Command= chose +"/Unlock.exe --lock --path" + " " + chose + "/conf/build.conf"
    print(Command)
    run(Command)
    pause_hint()
def main() -> int:
    set_title("AllToolBox 联网修补工具")
    global chose
    # do
    global flag
    global key
    global style
    try:
        def handle_action(action: str) -> None:
            match action:
                case "full":
                    full()
                case "shell":
                    shell() 
                case "files": files()
                case "Dll": dll()
                case "ND03": ND03()
                case "Conf": conf()
                case "Other": other()
                case "wipe": wipe()
                case "exe": exe()
                case "Unlock": unlock()
                case _:
                    pass

        clear()
        run("call logo")

        result = menu()
        os.system("cls")
        match result:
            case "full":
                full()
            case "shell":
                shell() 
            case "files":
                files()
            case "Dll":
                dll()
            case "ND03":
                ND03()
            case "Conf":
                conf()
            case "Other":
                other()
            case "wipe":
                wipe()
            case "exe":
                exe()
            case "Unlock":
                unlock()
            case "exit": return 0
        return main() # loop
    except KeyboardInterrupt:
        if key: 
            print_formatted_text(HTML("\n" + warn + "检测到用户中断，正在退出..."), style=style)
            return 0
        else:
            if not flag:
                print_formatted_text(HTML("\n" + warn + "检测到用户中断，正在退出..."), style=style)
                return 0
            key = True
            clear()
            return main()
if __name__ == "__main__":
    sys.exit(main())



