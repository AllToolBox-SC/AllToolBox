# -*- coding: utf-8 -*-

import logging
import argparse
import os
import sys
import shutil
import platform
import time
import datetime
import asyncio
from typing import Optional, Tuple, Iterable, List, Dict, Any
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
from flash_ak3 import AnyKernel3
import colorama
import subprocess
import socket
import requests
import filehash
import json
import traceback
import pluginutils, pluginutils.load, pluginutils.manage
from pathlib import Path

try:
    import debughook
except ImportError:
    pass


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

INFO = "<info>[信息]</info>"
ERROR = "<red>[错误]</red>"
WARN = "<orange>[警告]</orange>"

flag = False
key = False
started = False
BUILD_CONF_PATH: Optional[Path] = None
CURRENT_BUILD_META: Dict[str, str] = {}
ENV_HEADER_CLICK_COUNT = 0

LINE = "-" * 68
DEBUG = os.getenv("ATB_DEBUG_MODE", "0") == "1"
allow_xtc = False

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
logger.handlers.clear()
os.makedirs("logs", exist_ok=True)
filename = f"logs/atb_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
file_handler = logging.FileHandler(filename, encoding="utf-8")
file_handler.setLevel(logging.DEBUG)
formatter = MultilineFormatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


class BreakOut(Exception):
    pass


# ==================== UTILITY FUNCTIONS ====================

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


def onerror(fn):
    def wrapper(*args, **kwargs):
        global logger
        global style
        global ERROR
        try:
            return fn(*args, **kwargs)
        except Exception as e:
            err_msg = traceback.format_exc()
            logger.error(f"Error in {fn.__name__}: {e}")
            logger.error(err_msg)
            print_formatted_text(HTML(ERROR + "抱歉，脚本遇到了未经捕获的异常，即将退出..."), style=style)
            print_formatted_text(HTML(INFO + "错误详情已记录到 bin/logs 文件夹中，您可以将该文件发送给技术支持以获取帮助。"), style=style)
            time.sleep(3)
            cleanup(-1)
    return wrapper


def run(cmd):
    subprocess.run(["cmd.exe", "/v:on", "/c", f'''
                    @echo off &
                    setlocal enabledelayedexpansion 1>nul 2>nul &
                    call .\\color.bat &
                    set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC; &
                    @{cmd} &
                    endlocal 1>nul 2>nul &
                    '''.replace("\n", "").replace(20*" ", "")])


def checkwin() -> Tuple[str, str, str, str]:
    return (
        platform.system(),
        platform.release(),
        platform.version(),
        platform.architecture()
    )


def pause():
    kb = KeyBindings()

    @kb.add('<any>')
    def _(event):
        global pressed_key
        pressed_key = event.key_sequence[0].key
        event.app.exit()

    PromptSession(key_bindings=kb).prompt("")


def check_adb_server() -> Tuple[bool, Optional[Exception]]:
    adb_server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # ADB Server request timeout: fast 0.2, usually 0.25, default 0.3, slowly 0.6
    adb_server.settimeout(0.3)
    try:
        adb_server.connect(("127.0.0.1", 5037))
    except socket.timeout:
        return False, None
    except Exception as e:
        return False, e
    adb_server.close()
    return True, None


""" CONFIGURATION/BUILD FUNCTIONS """

def load_build_metadata() -> Tuple[Dict[str, str], bool, Optional[Path]]:
    """Load build metadata from conf/build.conf if present.

    Returns (metadata, found_flag, conf_path).
    """
    base_dir = Path(sys.executable).parent if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
    candidates = [
        base_dir / "conf" / "build.conf",
        base_dir.parent / "conf" / "build.conf",
        base_dir / ".." / "bin" / "conf" / "build.conf",
        Path.cwd() / "conf" / "build.conf",
    ]
    meta: Dict[str, str] = {}
    conf_path: Optional[Path] = None
    for cand in candidates:
        if cand.is_file():
            conf_path = cand
            break
    if not conf_path:
        # Auto-create a minimal build.conf with safe defaults when missing.
        conf_path = candidates[0]
        try:
            conf_path.parent.mkdir(parents=True, exist_ok=True)
            meta = {
                "ro.build.type": "release",
            }
            write_build_metadata(conf_path, meta)
            return meta, True, conf_path
        except Exception:
            return meta, False, None
    try:
        with conf_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                meta[k.strip()] = v.strip()
    except Exception:
        return meta, False, conf_path
    return meta, True, conf_path


def write_build_metadata(conf_path: Path, meta: Dict[str, str]) -> None:
    keys_in_order = list(meta.keys())
    with conf_path.open("w", encoding="utf-8") as f:
        for k in keys_in_order:
            f.write(f"{k}={meta[k]}\n")


def toggle_environment(conf_path: Path, meta: Dict[str, str]) -> str:
    """Toggle between release and userdebug environment by updating build.conf."""
    is_userdebug = (
        meta.get("ro.build.type") == "userdebug"
    )

    if is_userdebug:
        meta["ro.build.type"] = "release"
        target = "release"
    else:
        meta["ro.build.type"] = "userdebug"
        target = "userdebug"

    write_build_metadata(conf_path, meta)
    return target


def debug_features_allowed(meta: Dict[str, str]) -> bool:
    return (
        (
            meta.get("ro.build.type") == "debug"
        )
        or
        (
            meta.get("ro.build.type") == "userdebug"
        )
        or
        (
            meta.get("ro.build.type") == "Debug"
        )
    )


""" UI/MENU FUNCTIONS """

def menu_choice(
    message: str,
    options: Iterable[Tuple[Any, str]],
    default: Optional[str] = None,
    style_override: Optional[Style] = None,
    extra_bindings: Optional[KeyBindings] = None,
    header_text: Optional[str] = None,
    header_click_callback=None,
):
    option_list: List[Tuple[Any, str]] = list(options)
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
        # You can add MouseEventType.MOUSE_MOVE event type to allow mouse-move-select.
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


class Option:
    def __init__(self, value, label):
        self.value = value
        self.label = label


def choose(message: str, options: Iterable[Option], default: Optional[str] = None,
           extra_bindings: Optional[KeyBindings] = None, header_text: Optional[str] = None,
           header_click_callback=None):
    page_transition(message or "正在切换...")
    return menu_choice(
        message=message,
        options=[(opt.value, opt.label) for opt in options],
        default=default,
        style_override=style,
        extra_bindings=extra_bindings,
        header_text=header_text,
        header_click_callback=header_click_callback,
    )


@onerror
def menu() -> str:
    global style
    global ENV_HEADER_CLICK_COUNT, BUILD_CONF_PATH, CURRENT_BUILD_META
    if os.path.exists("mod") and os.path.isdir("mod"):
        print_formatted_text(HTML("已加载扩展列表："), style=style) if len(os.listdir("mod")) != 0 else print_formatted_text(HTML("已加载扩展列表：未加载任何扩展"), style=style)
        if len(os.listdir("mod")) != 0:
            i: int = 1
            for item in os.listdir("mod"):
                print_formatted_text(f"{i}. {item}", style=style)
                i += 1
    else:
        # print_formatted_text(HTML(WARN + "扩展文件夹没有创建，正在创建..."), style=style)
        os.remove("mod") if os.path.isfile("mod") else ...
        os.makedirs("mod", exist_ok=True)
    kb = KeyBindings()

    @kb.add('D')
    def _(event):
        event.app.exit(result="SHIFT_D")

    print_formatted_text(ANSI("鼠标双击或按回车键确定，方向键，数字键，鼠标单击来选择功能"))

    def header_click():
        global ENV_HEADER_CLICK_COUNT
        ENV_HEADER_CLICK_COUNT += 1
        if ENV_HEADER_CLICK_COUNT >= 10:
            ENV_HEADER_CLICK_COUNT = 0
            if not BUILD_CONF_PATH:
                print_formatted_text(HTML(ERROR + "未找到 build.conf，无法切换环境"), style=style)
                return
            try:
                target_env = toggle_environment(BUILD_CONF_PATH, CURRENT_BUILD_META)
                print_formatted_text(HTML(INFO + f"已切换环境为: {target_env}"), style=style)
            except Exception as exc:
                print_formatted_text(HTML(ERROR + f"切换环境失败: {exc}"), style=style)

    # Compose header with embedded softversion if available.
    version_str = CURRENT_BUILD_META.get("ro.product.current.softversion") or ""
    header = f"XTC AllToolBox {version_str} 控制台&主菜单 by xgj_236" if version_str else "XTC AllToolBox 控制台&主菜单 by xgj_236"

    result = choose(
        message="",
        options=[
            Option("onekeyroot", "一键Root"),
            Option("openshell", "在此处打开cmd[含adb环境]"),
            Option("about", "关于脚本"),
            Option("mods", "扩展管理"),
            Option("commonly", "常用合集[子菜单]"),
            Option("help-links", "链接合集[子菜单]"),
            Option("man-apps", "应用管理[子菜单]"),
            Option("magisk-mod", "magisk模块管理[子菜单]"),
            Option("user-debug", "开发合集[子菜单]"),
            Option("exit", "退出工具")
        ],
        default="onekeyroot",
        extra_bindings=kb,
        header_text=header,
        header_click_callback=header_click,
    )

    clear()
    return result


""" SPECIAL FUNCTIONS """

@onerror
def sel():
    clear()
    run("call sel file s .")
    run("pause")
    run("call sel file m .")
    run("pause")


@onerror
def color():
    clear()
    print_formatted_text(HTML(INFO + "<black>BLACK</black>"), style=style)
    print_formatted_text(HTML(INFO + "<red>RED</red>"), style=style)
    print_formatted_text(HTML(INFO + "<green>GREEN</green>"), style=style)
    print_formatted_text(HTML(INFO + "<orange>ORANGE</orange>"), style=style)
    print_formatted_text(HTML(INFO + "<blue>BLUE</blue>"), style=style)
    print_formatted_text(HTML(INFO + "<magenta>MAGENTA</magenta>"), style=style)
    print_formatted_text(HTML(INFO + "<cyan>CYAN</cyan>"), style=style)
    print_formatted_text(HTML(INFO + "<white>WHITE</white>"), style=style)
    run("pause")


""" FLASHING FUNCTIONS """

@onerror
def flash_anykernel3(ak3_path, boot_path):
    global logger
    try:
        ak3 = AnyKernel3(ak3_path)
        ak3.extract_zip()
        ak3.unpack_bootimg(boot_path, "./tmp/boot_unpacked")
        ak3.rename_mainfile()
        ak3.patch_bootimg()
        ak3.repack_bootimg(repack_to="./tmp/boot_patched.img")
        ak3.clean_up()
        os.remove("./tmp/kernel")
    except Exception as e:
        logger.error(traceback.format_exc())
        return 1


def flash_partation(imgpath: str, part: Optional[str] = "boot"):
    run("device_check.exe fastboot")
    print("\n")
    run(f"fastboot.exe flash {part} {imgpath}")


@onerror
def anykernel3():
    global style
    paths = ["/dev/block/by-name/", "/dev/block/bootdevice/by-name"]
    print_formatted_text(HTML(WARN + "目前仅支持boot.img修补，并可能存在未知问题！"), style=style)
    result = choose(message="", options=[
        Option("A", "返回上级菜单"),
        Option("1", "A-only槽位"),
        Option("2", "AB分区-A槽位"),
        Option("3", "AB分区-B槽位")
    ], default="A")
    match result:
        case "A":
            clear()
            return
        case "1":
            run("adb start-server 1>nul")
            run("device_check.exe adb")
            print_formatted_text("\n", style=style)
            for i in paths:
                process = subprocess.run(["adb.exe", "shell", f"su -c \"dd if={i}boot of=/sdcard/boot.img bs=2048"], )
                if process.returncode == 0:
                    break
            process = subprocess.run(["adb.exe", "pull", "/sdcard/boot.img", "./tmp/boot.img"])
            if process.returncode != 0:
                print_formatted_text(HTML(ERROR + "提取Boot失败"))
                return 1
            print_formatted_text(HTML(INFO + "请加载AnyKernel3 Zip"), style=style)
            run("call sel file s .")
            with open("./tmp/output.txt", "r", encoding="utf-8") as f:
                filepath = f.read().rstrip("\r\n").rstrip("\n")
                flash_anykernel3(filepath, "./tmp/boot.img")
                flash_partation("./tmp/boot_patched.img", "boot")
            print_formatted_text(HTML(INFO + "刷入成功"), style=style)
        case "2":
            run("adb start-server 1>nul")
            run("device_check.exe adb")
            print_formatted_text("\n", style=style)
            for i in paths:
                process = subprocess.run(["adb.exe", "shell", f"su -c \"dd if={i}boot_a of=/sdcard/boot.img bs=2048"], )
                if process.returncode == 0:
                    break
            process = subprocess.run(["adb.exe", "pull", "/sdcard/boot.img", "./tmp/boot.img"])
            if process.returncode != 0:
                print_formatted_text(HTML(ERROR + "提取Boot失败"))
                return 1
            print_formatted_text(HTML(INFO + "请加载AnyKernel3 Zip"), style=style)
            run("call sel file s .")
            with open("./tmp/output.txt", "r", encoding="utf-8") as f:
                filepath = f.read().rstrip("\r\n").rstrip("\n")
                flash_anykernel3(filepath, "./tmp/boot.img")
                flash_partation("./tmp/boot_patched.img", "boot_a")
            print_formatted_text(HTML(INFO + "刷入成功"), style=style)

        case "3":
            run("adb start-server 1>nul")
            run("device_check.exe adb")
            print_formatted_text("\n", style=style)
            for i in paths:
                process = subprocess.run(["adb.exe", "shell", f"su -c \"dd if={i}boot_b of=/sdcard/boot.img bs=2048"], )
                if process.returncode == 0:
                    break
            process = subprocess.run(["adb.exe", "pull", "/sdcard/boot.img", "./tmp/boot.img"])
            if process.returncode != 0:
                print_formatted_text(HTML(ERROR + "提取Boot失败"))
                return 1
            print_formatted_text(HTML(INFO + "请加载AnyKernel3 Zip"), style=style)
            run("call sel file s .")
            with open("./tmp/output.txt", "r", encoding="utf-8") as f:
                filepath = f.read().rstrip("\r\n").rstrip("\n")
                flash_anykernel3(filepath, "./tmp/boot.img")
                flash_partation("./tmp/boot_patched.img", "boot_b")
            print_formatted_text(HTML(INFO + "刷入成功"), style=style)
    anykernel3()


""" FEATURE MENU HANDLERS """

@onerror
def root():
    global allow_xtc
    global style
    clear()
    run("call logo")
    if allow_xtc:
        result = choose(
            message="一键Root菜单",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "小天才一键Root"),
                Option("2", "手机通用Root"),
            ],
            default="A"
        )
    else:
        print_formatted_text(HTML(INFO + "由于版权原因，暂时下线XTCRoot功能，敬请谅解"), style=style)
        result = choose(
            message="一键Root菜单",
            options=[
                Option("A", "返回上级菜单"),
                Option("2", "手机通用Root"),
            ],
            default="A"
        )
    match result:
        case "A":
            clear()
            return
        case "1":
            run("call root.bat")
        case "2":
            run("call otherroot.bat 3")
    root()


@onerror
def appset():
    global style, allow_xtc
    clear()
    run("call logo")
    if allow_xtc:
        result = choose(
            message="应用管理菜单",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "安装应用"),
                Option("2", "卸载应用"),
                Option("3", "安装xtc状态栏"),
                Option("4", "设置微信QQ为开机自启应用"),
                Option("5", "解除z10安装限制"),
            ],
            default="A"
        )
    else:
        print_formatted_text(HTML(INFO + "由于版权原因，暂时下线部分功能，敬请谅解"), style=style)
        result = choose(
            message="应用管理菜单",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "安装应用"),
                Option("2", "卸载应用"),
                Option("3", "安装状态栏悬浮窗"),
                Option("4", "设置微信QQ为开机自启应用"),
            ],
            default="A"
        )
    if result == "A":
        clear()
        return
    if result == "1":
        run("call userinstapp")
    if result == "2":
        run("call unapp")
    if result == "3":
        run("call xtcztl")
    if result == "4":
        run("call qqwxautestart")
    if result == "5":
        run("call z10openinst")
    appset()


@onerror
def userdebug():
    global style
    global allow_xtc
    clear()
    run("call logo")
    if allow_xtc:
        result = choose(
            message="开发合集",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "手表信息"),
                Option("2", "打开充电可用"),
                Option("3", "型号与innermodel对照表"),
                Option("4", "导入本地root文件"),
                Option("5", "一键root[不刷userdata]"),
                Option("6", "恢复出厂设置[不是超级恢复]"),
                Option("7", "开机自刷Recovery"),
                Option("8", "强制加好友[已失效]"),
            ],
            default="A"
        )
    else:
        print_formatted_text(HTML(INFO + "由于版权原因，暂时下线部分功能，敬请谅解"), style=style)
        result = choose(
            message="开发合集",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "手表信息"),
                Option("2", "打开充电可用"),
                Option("3", "型号与innermodel对照表"),
                Option("4", "导入本地root文件"),
                Option("6", "恢复出厂设置[不是超级恢复]"),
                Option("7", "开机自刷Recovery"),
            ],
            default="A"
        )

    if result == "A":
        clear()
        return
    if result == "1":
        run("call listbuild")
    if result == "2":
        run("call opencharge")
    if result == "3":
        run("call innermodel")
        print_formatted_text(HTML(INFO + "按任意键返回上级菜单"), style=style)
        pause()
    if result == "4":
        run("call pashroot")
    if result == "5":
        run("call root nouserdata")
    if result == "6":
        run("call miscre")
    if result == "7":
        run("call pashtwrppro")
    if result == "8":
        run("call friend")
    userdebug()


@onerror
def commonly():
    global style, allow_xtc
    clear()
    run("call logo")
    if allow_xtc:
        result = choose(
            message="常用合集",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "某天才-ADB/自检校验码计算"),
                Option("2", "某天才-离线OTA升级"),
                Option("3", "某天才-刷入TWRP"),
                Option("4", "某天才-刷入XTC Patch"),
                Option("5", "备份与恢复"),
                Option("6", "某天才-安卓8.1root后优化"),
                Option("7", "某天才-进入qmmi[9008]"),
                Option("8", "scrcpy投屏"),
                Option("9", "高级重启"),
                Option("10", "刷入AnyKernel3[实验性]")
            ],
            default="A"
        )
    else:
        print_formatted_text(HTML(INFO + "由于版权原因，暂时下线ADB/自检校验码计算功能，敬请谅解"), style=style)
        result = choose(
            message="常用合集",
            options=[
                Option("A", "返回上级菜单"),
                Option("2", "离线OTA升级"),
                Option("3", "刷入TWRP"),
                Option("5", "备份与恢复"),
                Option("7", "某天才-进入qmmi[9008]"),
                Option("8", "scrcpy投屏"),
                Option("9", "高级重启"),
                Option("10", "刷入AnyKernel3[实验性]")
            ],
            default="A"
        )
    match result:
        case "A":
            clear()
            return
        case "1":
            run("powershell -ExecutionPolicy Bypass -File zj.ps1")
        case "2":
            run("call ota")
        case "3":
            run("call pashtwrp")
        case "4":
            run("call xtcpatch")
        case "5":
            run("call backup")
        case "6":
            run("call rootpro")
        case "7":
            run("call qmmi")
            print_formatted_text(HTML(INFO + "按任意键返回上级菜单"), style=style)
            pause()
        case "8":
            run("call scrcpy-ui.bat")
        case "9":
            run("call rebootpro")
        case "10":
            clear()
            anykernel3()
        case _:
            print_formatted_text(HTML(ERROR + "输入错误，请重新输入"), style=style)
    commonly()


@onerror
def magisk():
    global style
    clear()
    run("call logo")
    result = choose(
        message="magisk模块管理",
        options=[
            Option("A", "返回上级菜单"),
            Option("1", "刷入Magisk模块"),
            # Option("2", "刷入LSPosed-Android8.1机型"),
        ],
        default="A"
    )
    if result == "A":
        clear()
        return
    if result == "1":
        run("call userinstmodule")
    if result == "2":
        run("call InstLSPosed810")
    magisk()


@onerror
def debug():
    global style, allow_xtc
    clear()
    run("call logo")
    result = choose(
        message="DEBUG菜单",
        options=[
            Option("A", "返回上级菜单"),
            Option("1", "色卡"),
            Option("2", "调整为未使用状态"),
            Option("3", "调整为使用状态"),
            Option("4", "调整为更新状态"),
            Option("5", "debug sel"),
            Option("6", "切换环境 (release/userdebug)"),
            Option("7", "允许使用xtc一键root功能"),
        ],
        default="A"
    )
    match result:
        case "A":
            clear()
            return
        case "1":
            color()
        case "2":
            open("whoyou.txt", "w").write("1")
        case "3":
            open("whoyou.txt", "w").write("2")
        case "4":
            open("whoyou.txt", "w").write("3")
        case "5":
            sel()
        case "6":
            global BUILD_CONF_PATH, CURRENT_BUILD_META
            if not BUILD_CONF_PATH:
                print_formatted_text(HTML(ERROR + "未找到 build.conf，无法切换环境"), style=style)
                time.sleep(1)
                return debug()
            try:
                target_env = toggle_environment(BUILD_CONF_PATH, CURRENT_BUILD_META)
                print_formatted_text(HTML(INFO + f"已切换环境为: {target_env}"), style=style)
            except Exception as exc:
                print_formatted_text(HTML(ERROR + f"切换环境失败: {exc}"), style=style)
            time.sleep(1)
        case "7":
            allow_xtc = True
            print_formatted_text(HTML(INFO + "已允许使用xtc一键root功能"), style=style)
            time.sleep(1)
    debug()


@onerror
def help_menu():
    global style, allow_xtc
    clear()
    run("call logo")
    if allow_xtc:
        result = choose(
            message="帮助与链接",
            options=[
                Option("A", "返回上级菜单"),
                Option("1", "超级恢复文件下载"),
                Option("2", "离线OTA下载"),
                Option("3", "面具模块下载"),
                Option("4", "APK下载"),
                Option("5", "工具箱官网"),
                Option("6", "开发文档"),
                Option("7", "123云盘解除下载限制")
            ],
            default="A"
        )
    else:
        result = choose(
            message="帮助与链接",
            options=[
                Option("A", "返回上级菜单"),
                Option("2", "离线OTA下载"),
                Option("3", "面具模块下载"),
                Option("5", "工具箱官网"),
                Option("6", "开发文档"),
                Option("7", "123云盘解除下载限制")
            ],
            default="A"
        )
    match result:
        case "A":
            clear()
            return
        case "1":
            run("start https://www.123865.com/s/Q5JfTd-hEbWH")
        case "2":
            run("start https://www.123865.com/s/Q5JfTd-HEbWH")
        case "3":
            run("start https://www.123684.com/s/Q5JfTd-cEbWH")
        case "4":
            run("start https://www.123684.com/s/Q5JfTd-ZEbWH")
        case "5":
            run("start https://atb.xgj.qzz.io")
        case "6":
            with open("开发文档.txt", "r", encoding="utf-8") as f:
                doc = f.read()
                print_formatted_text(HTML(doc), style=style)
            kb = KeyBindings()
            prompt(
                HTML(INFO + "按任意键返回上级菜单"),
                key_bindings=kb,
                style=style
            )
        case "7":
            run("call patch123")

    help_menu()


# ==================== MOD MANAGEMENT FUNCTIONS ====================

def load_mod_menu():
    mod_dir = ".\\mod"
    if not os.path.isdir(mod_dir):
        print_formatted_text(HTML(ERROR + "未找到 mod 目录"), style=style)
        return None

    dirs = [d for d in os.listdir(mod_dir)
            if os.path.isdir(os.path.join(mod_dir, d))]

    if not dirs:
        print_formatted_text(HTML(WARN + "未发现任何扩展"), style=style)
        time.sleep(2)
        return None

    base = 10
    mapping = {}
    options = [("A", "返回上级菜单")]

    for i, name in enumerate(dirs, start=base + 1):
        key = str(i)
        mapping[key] = name
        options.append((key, name))

    result = choose(
        message="已加载扩展",
        options=[Option(value, label) for value, label in options],
        default="A"
    )

    if result == "A":
        return None

    return mapping.get(result)


@onerror
def run_mod_main(modname):
    run(f'cd /d mod\\{modname} && call main.bat')


@onerror
def mod():
    clear()
    run("call logo")

    result = choose(
        message="扩展管理",
        options=[
            Option("A", "返回上级菜单"),
            Option("1", "运行已安装扩展"),
            Option("2", "安装扩展"),
            Option("3", "卸载扩展"),
        ],
        default="A"
    )

    if result == "A":
        clear()
        return

    if result == "1":
        modname = load_mod_menu()
        if modname:
            run_mod_main(modname)

    if result == "2":
        run("call mod")

    if result == "3":
        run("call unmod")

    mod()


""" MAIN FLOW FUNCTIONS """

@onerror
def about():
    print_formatted_text(
        HTML(f"<yellow>{LINE}</yellow>"),
        style=style
    )

    print_formatted_text(
        HTML(INFO + "本脚本由快乐小公爵236等开发者制作"),
        style=style
    )

    run("call thank.bat")

    print_formatted_text(
        HTML(INFO + "工具官网：https://atb.xgj.qzz.io"),
        style=style
    )
    print_formatted_text(
        HTML(INFO + "作者QQ：3247039462"),
        style=style
    )
    print_formatted_text(
        HTML(INFO + "工具箱交流与反馈QQ群：907491503"),
        style=style
    )
    print_formatted_text(
        HTML(INFO + "作者哔哩哔哩账号：https://b23.tv/L54R5ZV"),
        style=style
    )
    print_formatted_text(
        HTML(INFO + "bug与建议反馈邮箱：ATBbug@xgj.qzz.io"),
        style=style
    )

    run("call uplog.bat")

    print_formatted_text(
        HTML(f"<yellow>{LINE}</yellow>"),
        style=style
    )

    kb = KeyBindings()

    prompt(
        HTML(INFO + "按任意键返回上级菜单"),
        key_bindings=kb,
        style=style
    )


@onerror
def pre_main() -> bool:
    global allow_xtc
    global flag
    global logger
    global DEBUG
    global BUILD_CONF_PATH, CURRENT_BUILD_META
    run("@echo off & setlocal enabledelayedexpansion")
    colorama.init(autoreset=True)
    run("call .\\color.bat")
    if DEBUG:
        print_formatted_text(HTML(INFO + "已启用调试模式"), style=style)
        logger.debug("Debug mode is enabled")
    if " " in os.path.abspath("."):
        if os.getenv("ATB_IGNORE_SPACE_IN_PATH", "0") != "1":
            print_formatted_text(HTML(ERROR + "当前路径包含空格，会导致未知问题，请将工具箱放置在无空格路径下运行，即将退出..."), style=style)
            print_formatted_text(HTML(INFO + "若要跳过此检测，请设置环境变量ATB_IGNORE_SPACE_IN_PATH=1"), style=style)
            time.sleep(2)
            return False
        else:
            print_formatted_text(HTML(WARN + "当前路径包含空格，可能导致未知问题，建议将工具箱放置在无空格路径下运行"), style=style)
    if getattr(sys, 'frozen', False):
        this_path = os.path.dirname(sys.executable)
    else:
        this_path = os.path.dirname(os.path.abspath(__file__))

    env_path_lower = (os.environ.get("PATH") or "").lower()
    keywords = ["windows", "system32", "powershell"]
    if not all(k in env_path_lower for k in keywords):
        print_formatted_text(HTML(ERROR + "你的系统环境变量异常，这可能导致异常问题，输入no跳过"), style=style)
        answer = input().strip().lower()
        if answer != "no":
            return False

    softver = CURRENT_BUILD_META.get("ro.product.current.softversion") or ""
    title = f"XTC AllToolBox {softver} by xgj_236" if softver else "XTC AllToolBox by xgj_236"
    set_title(title)
    os.makedirs("mod", exist_ok=True)
    for item in os.listdir("mod"):
        item_path = os.path.join("mod", item)
        if os.path.isdir(item_path):
            if os.path.exists(os.path.join(item_path, "start.bat")):
                run(f'cd /d mod\\{item} && call start.bat')

    try:
        candidate_bin = os.path.normpath(os.path.join(this_path, "..", "bin"))
        if os.path.isdir(candidate_bin):
            os.chdir(candidate_bin)
            logger.debug("Changed working directory to %s", candidate_bin)
        else:
            logger.debug("Bin directory not found: %s; continuing in current working directory", candidate_bin)
    except Exception:
        logger.exception("Failed to change working directory to bin; continuing")

    def _run_if_present(base_name: str):
        try:
            if os.path.exists(base_name) or os.path.exists(base_name + ".bat"):
                run(f"call {base_name}")
            else:
                logger.debug("%s not found; skipping", base_name)
        except Exception:
            logger.exception("Error running %s", base_name)

    _run_if_present("withone")
    _run_if_present("afterup")
    if os.path.exists("..\\bugjump.7z"):
        os.remove("..\\bugjump.7z")
    if os.path.exists("..\\repair.exe"):
        os.remove("..\\repair.exe")
    if os.getenv("ATB_SKIP_UPDATE", "0") != "1":
        print_formatted_text(HTML(INFO + "正在检查更新..."), style=style)
        try:
            meta_update, meta_found_update, conf_path_update = load_build_metadata()
            if meta_found_update:
                BUILD_CONF_PATH = conf_path_update
                CURRENT_BUILD_META = meta_update
            is_userdebug = meta_update.get("ro.build.type") == "userdebug"
            base = "https://raw.githubusercontent.com/xgj236/AllToolBox/main"
            utc_url = f"{base}/utctmp.txt"
            version_tmp_url = f"{base}/versiontmp.txt"
            if is_userdebug:
                utc_url = f"{base}/betautctmp.txt"
                version_tmp_url = f"{base}/betaversiontmp.txt"

            local_path = "bugversion.txt"
            if not os.path.exists(local_path):
                with open(local_path, "w") as bv:
                    bv.write("0")

            with open(local_path, "r") as fv:
                try:
                    filev = int(fv.read().strip())
                except ValueError:
                    filev = 0

            resp = requests.get(
                utc_url,
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36)'},
                timeout=8
            )
            resp.raise_for_status()
            try:
                webv = int(resp.text.strip())
            except ValueError:
                webv = filev

            if webv > filev:
                new_version = meta_update.get("ro.product.current.softversion", "") if meta_update else ""
                if not new_version:
                    try:
                        vt = requests.get(
                            version_tmp_url,
                            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36)'},
                            timeout=8
                        )
                        vt.raise_for_status()
                        new_version = vt.text.strip()
                    except Exception:
                        new_version = ""
                print_formatted_text(HTML(WARN + "当前补丁版本过时，必须更新"), style=style)
                if new_version:
                    print_formatted_text(HTML(INFO + f"最新补丁版本：{new_version}"), style=style)
                print_formatted_text(HTML(INFO + "按任意键开始更新..."), style=style)
                pause()
                shutil.copy2("repair.exe", "..\\repair.exe")
                os.chdir("..\\")
                subprocess.run(["cmd", "/c", "start", "repair.exe"])
                cleanup(2)
        except Exception:
            pass
        run("call upall.bat run")
        try:
            if CURRENT_BUILD_META.get("persist.xtc_allow_lock_True") == "True":
                allow_xtc = True
            elif str(CURRENT_BUILD_META.get("persist.atb.xtc.allow", "")).lower() in ("true", "1", "yes", "y"):
                allow_xtc = True
            elif debug_features_allowed(CURRENT_BUILD_META):
                allow_xtc = True
            else:
                try:
                    allow_xtc = requests.get(
                        "https://atb.xgj.qzz.io/other/xtcpolicy.json",
                        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36)'},
                        timeout=8
                    ).json().get("allowXTC", False)
                except Exception:
                    logger.error(traceback.format_exc())
                    allow_xtc = False
        except Exception:
            logger.error(traceback.format_exc())
            allow_xtc = False
    if os.getenv("ATB_SKIP_PLATFORM_CHECK", "0") != "1":
        print_formatted_text(HTML(INFO + "正在检查Windows属性..."), style=style)
        os_name, os_release, os_version, arch = checkwin()
        match arch[0]:
            case "64bit":
                arch = "x64"
            case "32bit":
                arch = "x86"
            case _:
                arch = "arm64-v8a"
        print_formatted_text(HTML(INFO + f"当前运行环境:{os_name}{os_release}_{arch}_{os_version}"), style=style)
        os_vercode = 0
        try:
            os_vercode = float(os_release)
        except ValueError:
            pass
        if os_vercode <= 7:
            print_formatted_text(HTML(ERROR + "此脚本需要 Windows 8 或更高版本"), style=style)
            pause()
            return 1
        print_formatted_text(HTML(INFO + f"当前系统: {os_name} {os_release}"), style=style)
        adb_process = subprocess.Popen(["adb.exe", "version"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, shell=True)
        adb_process.wait()
        if adb_process.returncode != 0:
            print_formatted_text(HTML(ERROR + "ADB检查失败，返回值：", str(adb_process.returncode)), style=style)
            return False
        print_formatted_text(HTML(INFO + "检查ADB命令成功"), style=style)
    whoyou = open("whoyou.txt", "w", encoding="gbk")
    whoyou.write("2")
    whoyou.close()
    print_formatted_text(HTML(f"""{WARN}关于解绑：该工具不提供手表强制解绑服务，如您拾取他人的手表，请联系当地110公安机关归还失主。手表解绑属于非法行为，请归还失主。而不要尝试通过任何手段解除挂失锁
        {WARN}关于收费：这个工具是完全免费的，如果你付费购买了那么请退款
        {WARN}本脚本部分功能可能造成侵权问题，并可能受到法律追究，所以仅供个人使用，请勿用于商业用途
        {INFO}---请永远相信我们能给你带来免费又好用的工具---
        {INFO}关于官网：https://atb.xgj.qzz.io
        {INFO}关于作者：本脚本由快乐小公爵236等作者制作
        {INFO}作者QQ：3247039462
        {INFO}工具箱交流与反馈QQ群：907491503
        {INFO}作者哔哩哔哩账号：https://b23.tv/L54R5ZV
        {INFO}bug与建议反馈邮箱：ATBbug@xgj.qzz.io""".replace(" " * 8, "")), style=style)
    print_formatted_text(HTML(INFO + "按任意键进入主界面"), style=style)

    pause()
    flag = True
    clear()
    return True


@onerror
def cleanup(code: int = 0):
    global style
    print_formatted_text(HTML(INFO + "正在结束ADB服务..."), style=style)
    if check_adb_server()[0]:
        subprocess.Popen(["adb.exe", "kill-server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True)
    sys.exit(code)


@onerror
def main() -> int:
    # do
    global flag
    global key
    global style
    global BUILD_CONF_PATH
    global CURRENT_BUILD_META
    build_meta, meta_found, conf_path = load_build_metadata()
    BUILD_CONF_PATH = conf_path
    CURRENT_BUILD_META = build_meta
    debug_allowed = debug_features_allowed(build_meta) if meta_found else True
    try:
        if not meta_found:
            logger.warning("BUILD.CONF 丢失")

        def handle_action(action: str) -> None:
            match action:
                case "root":
                    clear()
                    run("call root.bat")
                    clear()
                case "openshell":
                    clear()
                    subprocess.run(["cmd.exe", "/k"], shell=True)
                    clear()
                case "about":
                    about()
                case "mods":
                    mod()
                case "commonly":
                    commonly()
                case "user-debug":
                    userdebug()
                case "man-apps":
                    appset()
                case "magisk-mod":
                    magisk()
                case "help-links":
                    help_menu()
                case _:
                    pass

        # Start interactive (UI/menu) flow. Run pre-main checks once.
        pre_ok = pre_main() if not flag else True
        if not pre_ok:
            return 1
        clear()
        run("call logo")

        result = menu()
        match result:
            case "SHIFT_D":
                if debug_allowed:
                    debug()
                else:
                    return main()  # loop
            case "onekeyroot":
                root()
            case "openshell":
                clear()
                subprocess.run(["cmd.exe", "/k"], shell=True)
                clear()
            case "about":
                about()
            case "mods":
                mod()
            case "commonly":
                commonly()
            case "user-debug":
                userdebug()
            case "man-apps":
                appset()
            case "magisk-mod":
                magisk()
            case "help-links":
                help_menu()
            case "exit":
                return 0
        main()  # loop

    except KeyboardInterrupt:
        if key:
            print_formatted_text(HTML("\n" + WARN + "检测到用户中断，正在退出..."), style=style)
            return 0
        else:
            if not flag:
                print_formatted_text(HTML("\n" + WARN + "检测到用户中断，正在退出..."), style=style)
                return 0
            key = True
            clear()
            main()


if __name__ == "__main__":
    result = main()
    logger.debug("ATBExitEvent, main returned: %s", result)
    cleanup(result)
    