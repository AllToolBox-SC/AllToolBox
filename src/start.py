# -*- coding: utf-8 -*-

import os
import sys
import shutil
import platform
import time
import asyncio
from typing import Optional, Tuple, Iterable, List
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
import socket
import requests
import filehash
import json
import winreg



style = Style.from_dict({
    # Dark base, subtle accents, minimal fill
    "yellow": "fg:#f1c40f",
    "red": "fg:#ff7b7b",
    "orange": "fg:#f4a261",
    "info": "fg:#9dcffb",
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

flag = False
key = False

LINE = "-" * 68

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

# session = subprocess.Popen(["cmd.exe"], shell=True)

Option = Tuple[str, str]


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
):
    option_list: List[tuple] = list(options)
    if not option_list:
        raise ValueError("menu_choice requires at least one option")

    selected_index = 0
    display_index = 0
    animate_in = True
    visible_count = 0 if animate_in else len(option_list)
    move_task = None

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


def choose(message: str, options: Iterable[Option], default: str | None = None, extra_bindings: KeyBindings | None = None):
    page_transition(message or "正在切换...")
    return menu_choice(message=message, options=options, default=default, style_override=style, extra_bindings=extra_bindings)

def set_env_variable(name, value, user=True):
    """
    设置环境变量（用户或系统）
    user=True 设置到当前用户
    user=False 设置到系统（需要管理员权限）
    """
    root = winreg.HKEY_CURRENT_USER if user else winreg.HKEY_LOCAL_MACHINE
    path = r'Environment'
    try:
        registry_key = winreg.OpenKey(root, path, 0, winreg.KEY_SET_VALUE)
    except FileNotFoundError:
        registry_key = winreg.CreateKey(root, path)

    winreg.SetValueEx(registry_key, name, 0, winreg.REG_SZ, value)
    winreg.CloseKey(registry_key)


def get_env_variable(name, user=True) -> Optional[str]:
    """Read environment variable directly from registry to avoid stale process env."""
    root = winreg.HKEY_CURRENT_USER if user else winreg.HKEY_LOCAL_MACHINE
    path = r'Environment'
    try:
        registry_key = winreg.OpenKey(root, path, 0, winreg.KEY_READ)
        value, _ = winreg.QueryValueEx(registry_key, name)
        winreg.CloseKey(registry_key)
        return value
    except FileNotFoundError:
        return None

def menu() -> str:
    global style
    if os.path.exists("mod") and os.path.isdir("mod"):
        print_formatted_text(HTML(info + "已加载扩展列表："), style=style) if len(os.listdir("mod")) != 0 else print_formatted_text(HTML(info + "已加载扩展列表：未加载任何扩展"), style=style)
        if len(os.listdir("mod")) != 0:
            i: int = 1
            for item in os.listdir("mod"):
                print_formatted_text(f"{i}. {item}", style=style)
                i += 1
    else:
        print_formatted_text(HTML(warn + "扩展文件夹没有创建，正在创建..."), style=style)
        os.remove("mod") if os.path.isfile("mod") else ...
        os.makedirs("mod", exist_ok=True)
    kb = KeyBindings()
    # @kb.add('R')
    # def _(event):
    #     event.app.exit(result="SHIFT_R")
    
    @kb.add('D')
    def _(event):
        event.app.exit(result="SHIFT_D")


    print_formatted_text(ANSI(colorama.Fore.RESET + colorama.Fore.YELLOW + "XTC AllToolBox 控制台&主菜单 " + colorama.Fore.BLUE + "by xgj_236" + colorama.Fore.LIGHTYELLOW_EX))
    # style = Style.from_dict(
    #     {
    #         "number": "bold",
    #         "selected-option": "underline bold",
    #     }
    # )
    
    result = choose(
        message="",
        options=[
            ("onekeyroot", "一键Root"),
            ("openshell", "在此处打开cmd[含adb环境]"),
            ("forceupdate", "强制更新脚本"),
            ("about", "关于脚本"),
            ("mods", "扩展管理"),
            ("flash-files", "刷机与文件[子菜单]"),
            ("connection-debug", "连接与调试[子菜单]"),
            ("man-apps", "应用管理[子菜单]"),
            ("imoo-services", "小天才服务[子菜单]"),
            ("help-links", "帮助与链接[子菜单]"),
            ("exit", "退出脚本")
        ],
        default="onekeyroot",
        extra_bindings=kb
    )

    clear(); return result

def run(cmd):
    subprocess.run(["cmd.exe", "/v:on", "/c", f'''
                    @echo off &
                    setlocal enabledelayedexpansion 1>nul 2>nul &
                    call .\\color.bat &
                    set PATH=%cd%\\;C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem;C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\;C:\\Windows\\System32\\OpenSSH\\;%PATH% &
                    set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC; &
                    @{cmd} &
                    endlocal 1>nul 2>nul &
                    '''.replace("\n", "").replace(20*" ", "")], shell=True)


def appset():
    global style
    clear()
    run("call logo")
    result = choose(
        message="应用管理菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "安装应用"),
            ("2", "卸载应用"),
            ("3", "安装xtc状态栏"),
            ("4", "设置微信QQ为开机自启应用"),
            ("5", "解除z10安装限制"),
        ],
        default="A"
    )
    if result == "A":
        clear(); return
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

def control():
    clear()
    run("call logo")
    result = choose(
        message="连接与调试菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "进入qmmi[9008]"),
            ("2", "scrcpy投屏"),
            ("3", "手表信息"),
            ("4", "打开充电可用"),
            ("5", "型号与innermodel对照表"),
            ("6", "高级重启"),
        ],
        default="A"
    )
    if result == "A":
        clear(); return
    if result == "1":
        run("call qmmi")
    if result == "2":
        run("start scrcpy-noconsole.vbs")
    if result == "3":
        run("call listbuild")
    if result == "4":
        run("call opencharge")
    if result == "5":
        run("call innermodel")
    if result == "6":
        run("call rebootpro")
    control()

def flash():
    global style
    clear()
    run("call logo")
    result = choose(
        message="刷机与文件菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "从云端更新文件"),
            ("2", "导入本地root文件"),
            ("3", "一键root[不刷userdata]"),
            ("4", "恢复出厂设置"),
            ("5", "开机自刷Recovery"),
            ("6", "刷入TWRP"),
            ("7", "刷入XTC Patch"),
            ("8", "刷入Magisk模块"),
            ("9", "备份与恢复"),
            ("10", "安卓8.1root后优化")
        ],
        default="A"
    )
    match result:
        case "A":
            clear(); return
        case "1":
            run("call cloud")
        case "2":
            run("call pashroot")
        case "3":
            run("call root nouserdata")
        case "4":
            run("call miscre")
        case "5":
            run("call pashtwrppro")
        case "6":
            run("call pashtwrp")
        case "7":
            run("call xtcpatch")
        case "8":
            run("call userinstmodule")
        case "9":
            run("call backup")
        case "10":
            run("call rootpro")
        case _:
            print_formatted_text(HTML(error + "输入错误，请重新输入"), style=style)
        
    flash()

def xtcservice():

    global style
    clear()
    run("call logo")
    result = choose(
        message="小天才服务菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "手表强加好友[已弃用]"),
            ("2", "ADB/自检校验码计算"),
            ("3", "离线OTA升级"),
        ],
        default="A"
    )
    if result == "A":
        clear(); return
    if result == "1":
        run("call friend")
    if result == "2":
        run('powershell -ExecutionPolicy Bypass -File zj.ps1')
    if result == "3":
        run("call ota")
    xtcservice()

def debug():
    global style
    clear()
    run("call logo")
    result = choose(
        message="DEBUG菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "色卡"),
            ("2", "调整为未使用状态"),
            ("3", "调整为使用状态"),
            ("4", "调整为更新状态"),
            ("5", "debug sel"),
        ],
        default="A"
    )
    match result:
        case "A":
            clear(); return
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
    debug()

def sel():
    clear()
    run("call sel file s .")
    run("pause")
    run("call sel file m .")
    run("pause")

def color():
    clear()
    print_formatted_text(HTML(info +"<black>BLACK</black>"), style=style)
    print_formatted_text(HTML(info +"<red>RED</red>"), style=style)
    print_formatted_text(HTML(info +"<green>GREEN</green>"), style=style)
    print_formatted_text(HTML(info +"<orange>ORANGE</orange>"), style=style)
    print_formatted_text(HTML(info +"<blue>BLUE</blue>"), style=style)
    print_formatted_text(HTML(info +"<magenta>MAGENTA</magenta>"), style=style)
    print_formatted_text(HTML(info +"<cyan>CYAN</cyan>"), style=style)
    print_formatted_text(HTML(info +"<white>WHITE</white>"), style=style)
    run("pause")

def help_menu():
    clear()
    run("call logo")
    result = choose(
        message="帮助与链接",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "远程协助"),
            ("2", "超级恢复文件下载"),
            ("3", "离线OTA下载"),
            ("4", "面具模块下载"),
            ("5", "APK下载"),
            ("6", "工具箱官网"),
            ("7", "开发文档"),
            ("8", "123云盘解除下载限制")
        ],
        default="A"
    )
    match result:
        case "A":
            clear()
            return
        case "1":
            print_formatted_text(HTML(warn + "已弃用该功能"))
        case "2":
            run("start https://www.123865.com/s/Q5JfTd-hEbWH")
        case "3":
            run("start https://www.123865.com/s/Q5JfTd-HEbWH")
        case "4":
            run("start https://www.123684.com/s/Q5JfTd-cEbWH")
        case "5":
            run("start https://www.123684.com/s/Q5JfTd-ZEbWH")
        case "6":
            run("start https://atb.xgj.qzz.io")
        case "7":
            with open("开发文档.txt", "r", encoding="utf-8") as f:
                doc = f.read()
                print_formatted_text(HTML(doc), style=style)
            kb = KeyBindings()
            prompt(
                HTML(info + "按任意键返回上级菜单"),
                key_bindings=kb,
                style=style
            )
        case "8":
            run("call patch123")
        
    help_menu()

def load_mod_menu():
    mod_dir = ".\\mod"
    if not os.path.isdir(mod_dir):
        print_formatted_text(HTML(error + "未找到 mod 目录"), style=style)
        return None

    dirs = [d for d in os.listdir(mod_dir)
            if os.path.isdir(os.path.join(mod_dir, d))]

    if not dirs:
        print_formatted_text(HTML(warn + "未发现任何扩展"), style=style)
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
        options=options,
        default="A"
    )

    if result == "A":
        return None

    return mapping.get(result)


def run_mod_main(modname):
    run(f'cd /d mod\\{modname} && call main.bat')

def mod():
    clear()
    run("call logo")

    result = choose(
        message="扩展管理",
        options=[
            ("A", "返回上级菜单"),
            ("1", "运行已安装扩展"),
            ("2", "安装扩展"),
            ("3", "卸载扩展"),
        ],
        default="A"
    )

    if result == "A":
        clear(); return

    if result == "1":
        modname = load_mod_menu()
        if modname:
            run_mod_main(modname)

    if result == "2":
        run("call mod")

    if result == "3":
        run("call unmod")

    mod()


def about():
    print_formatted_text(
        HTML(f"<yellow>{LINE}</yellow>"),
        style=style
    )

    print_formatted_text(
        HTML(info + "本脚本由快乐小公爵236等开发者制作"),
        style=style
    )

    run("call thank.bat")

    print_formatted_text(
        HTML(info + "工具官网：https://atb.xgj.qzz.io"),
        style=style
    )
    print_formatted_text(
        HTML(info + "作者QQ：3247039462"),
        style=style
    )
    print_formatted_text(
        HTML(info + "工具箱交流与反馈QQ群：907491503"),
        style=style
    )
    print_formatted_text(
        HTML(info + "作者哔哩哔哩账号：https://b23.tv/L54R5ZV"),
        style=style
    )
    print_formatted_text(
        HTML(info + "bug与建议反馈邮箱：ATBbug@xgj.qzz.io"),
        style=style
    )

    run("call uplog.bat")

    print_formatted_text(
        HTML(f"<yellow>{LINE}</yellow>"),
        style=style
    )

    kb = KeyBindings()


    prompt(
        HTML(info + "按任意键返回上级菜单"),
        key_bindings=kb,
        style=style
    )

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


def pre_main() -> bool:
    global flag
    run("@echo off")
    run("setlocal enabledelayedexpansion")
    if os.getenv("ATB_OLD_MENU", "0") == "1":
        run("call start.bat")
        sys.exit()
    # subprocess.run(["chcp", "65001"], shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print_formatted_text(HTML(info + "正在启动中..."), style=style)
    colorama.init(autoreset=True)
    run("call .\\color.bat")
    if " " in os.path.abspath("."):
        if os.getenv("ATB_IGNORE_SPACE_IN_PATH", "0") != "1":
            print_formatted_text(HTML(error + "当前路径包含空格，会导致未知问题，请将工具箱放置在无空格路径下运行，即将退出..."), style=style)
            print_formatted_text(HTML(info + "若要跳过此检测，请设置环境变量ATB_IGNORE_SPACE_IN_PATH=1"), style=style)
            time.sleep(2)
            return False
        else:
            print_formatted_text(HTML(warn + "当前路径包含空格，可能导致未知问题，建议将工具箱放置在无空格路径下运行"), style=style)
    if getattr(sys, 'frozen', False):
        this_path = os.path.dirname(sys.executable)
    else:
        this_path = os.path.dirname(os.path.abspath(__file__))

    def clean_env_value(val: Optional[str]) -> Optional[str]:
        if not val:
            return val
        return val.strip().strip('"').strip().rstrip(';')

    atb_path_env = clean_env_value(os.getenv("ATB_PATH"))
    atb_path_reg = clean_env_value(get_env_variable("ATB_PATH"))
    atb_path = atb_path_env or atb_path_reg
    path_v = os.getenv("PATH") or ""
    path_updated = False

    def norm_path(p: str) -> str:
        return os.path.normcase(os.path.normpath(p.rstrip("\\/")))

    if not atb_path:
        with open("whoyou.txt", "w", encoding="utf-8") as f:
            f.write("1")

    # Clean and drop empty entries from PATH for stable comparisons
    path_parts = [clean_env_value(p.strip()) for p in path_v.split(";") if p.strip()]
    path_parts = [p for p in path_parts if p]
    this_norm = norm_path(this_path)
    atb_norm = norm_path(atb_path) if atb_path else None

    # Normalize PATH: drop old ATB entry, remove dupes, ensure current path is present
    cleaned_parts = []
    seen = set()
    for p in path_parts:
        norm = norm_path(p)
        if atb_norm and norm == atb_norm and this_norm != atb_norm:
            continue
        if norm in seen:
            continue
        seen.add(norm)
        cleaned_parts.append(os.path.normpath(p))

    # Ensure current path is present exactly once
    if this_norm not in seen:
        cleaned_parts.insert(0, os.path.normpath(this_path))
        seen.add(this_norm)

    new_path = ";".join(cleaned_parts)
    normed_current = [norm_path(p) for p in path_parts]
    normed_new = [norm_path(p) for p in cleaned_parts]

    # Only update PATH when normalized lists differ
    if normed_new != normed_current:
        set_env_variable("PATH", new_path)
        path_updated = True

    atb_same = bool(atb_path) and (atb_norm == this_norm)
    if not atb_same:
        set_env_variable("ATB_PATH", this_path)
        os.environ["ATB_PATH"] = this_path  # keep current process in sync
        path_updated = True  # trigger refresh once
        print_formatted_text(HTML(info + "设置环境变量[PATH]..."), style=style)#Test do not remove
    with open("whoyou.txt", "w", encoding="utf-8") as f:
        f.write("2")

    if path_updated:
        run("call refreshenv 1>nul 2>nul")
    print_formatted_text(HTML(info + "检查系统变量[PATH]..."), style=style)
    run("set PATH=%PATH%;C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem;C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\;C:\\Windows\\System32\\OpenSSH\\;%cd%\\")
    
    print_formatted_text(HTML(info + "检查系统变量[PATHEXT]..."), style=style)
    run("set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;")
    set_title("XTC AllToolBox by xgj_236")
    os.makedirs("mod", exist_ok=True)
    for item in os.listdir("mod"):
        item_path = os.path.join("mod", item)
        if os.path.isdir(item_path):
            if os.path.exists(os.path.join(item_path, "start.bat")):
                run(f'cd /d mod\\{item} && call start.bat')

    os.chdir("..\\bin")
    # tip: 已停止对WMIC的支持
    # wmic = subprocess.run(["cmd.exe", "/c", "where", "wmic.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True)

    # if wmic.returncode != 0:
    #     r = input("WMIC工具未找到，是否安装WMIC？(Y/N)：")
    #     if r.lower() == "y":
    #         print_formatted_text(HTML(info + "坐和放宽，把时间交给我们..."), style=style)
    #         print_formatted_text(HTML(info + "若提示是否重启，建议选择重启"), style=style)
    #         run("DISM /Online /Add-Capability /CapabilityName:WMIC~~~~")
    #         run("call refreshenv")
    #     else:
    #         print_formatted_text(HTML(warn + "WMIC未安装，可能导致未知问题"), style=style)
        
    run("call withone")
    run("call afterup")
    if os.path.exists("..\\bugjump.7z"): os.remove("..\\bugjump.7z")
    if os.path.exists("..\\repair.exe"): os.remove("..\\repair.exe")
    if os.getenv("ATB_SKIP_UPDATE", "0") != "1":
        print_formatted_text(HTML(info + "正在检查更新..."), style=style)
        try:
            if not os.path.exists("bugversion.txt"): 
                bv = open("bugversion.txt", "w")
                bv.write("0")
                bv.close()
            with open("bugversion.txt", "r") as fv:
                vcf = open("version.txt")
                vc = vcf.read().strip()
                vcf.close()
                webv = requests.get(f"https://atb.xgj.qzz.io/other/bugup/{vc}/manifest.json", headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'})
                webv = webv.json()["latestBugUpdate"]["ver"]
                filev = int(fv.read().strip())
                if webv > filev:
                    print_formatted_text(HTML(warn+"当前补丁版本过时，必须更新"), style=style)
                    print_formatted_text(HTML(info+"按任意键开始更新..."), style=style)
                    pause()
                    shutil.copy2("repair.exe", "..\\repair.exe")
                    os.chdir("..\\")
                    subprocess.run(["cmd", "/c", "start", "repair.exe"])
                    cleanup(2)
        except Exception as e:
            print_formatted_text(HTML(warn + f"漏洞补丁获取失败，已经跳过"))
        run("call upall.bat run")
    if os.getenv("ATB_SKIP_PLATFORM_CHECK", "0") != "1":
        print_formatted_text(HTML(info + "正在检查Windows属性..."), style=style)
        # run("call checkwin")
        os_name, os_release, os_version, arch = checkwin()
        match arch[0]:
            case "64bit": arch = "x64"
            case "32bit": arch = "x86"
            case _: arch = "arm64-v8a"
        print_formatted_text(HTML(info + f"当前运行环境:{os_name}{os_release}_{arch}_{os_version}"), style=style)
        os_vercode = 0
        try:
            os_vercode = float(os_release)
        except ValueError:
            pass
        if os_vercode <= 7:
            print_formatted_text(HTML(error + "此脚本需要 Windows 8 或更高版本"), style=style)
            pause(); return 1
        print_formatted_text(HTML(info + f"当前系统: {os_name} {os_release}"), style=style)

        # print_formatted_text(HTML(info + "Windows属性成功检测"), style=style)
        adb_process = subprocess.Popen(["adb.exe", "version"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, shell=True)
        adb_process.wait()
        if adb_process.returncode != 0:
            print_formatted_text(HTML(error + "ADB检查失败，返回值：", str(adb_process.returncode)), style=style)
            return False
        print_formatted_text(HTML(info + "检查ADB命令成功"), style=style)
    whoyou = open("whoyou.txt", "w", encoding="gbk")
    whoyou.write("2")
    whoyou.close()
    print_formatted_text(HTML(f"""{warn}关于解绑：该工具不提供手表强制解绑服务，如您拾取他人的手表，请联系当地110公安机关归还失主。手表解绑属于非法行为，请归还失主。而不要尝试通过任何手段解除挂失锁
        {warn}关于收费：这个工具是完全免费的，如果你付费购买了那么请退款
        {warn}本脚本部分功能可能造成侵权问题，并可能受到法律追究，所以仅供个人使用，请勿用于商业用途
        {info}---请永远相信我们能给你带来免费又好用的工具---
        {info}关于官网：https://atb.xgj.qzz.io
        {info}关于作者：本脚本由快乐小公爵236等作者制作
        {info}作者QQ：3247039462
        {info}工具箱交流与反馈QQ群：907491503
        {info}作者哔哩哔哩账号：https://b23.tv/L54R5ZV
        {info}bug与建议反馈邮箱：ATBbug@xgj.qzz.io""".replace(" " * 8, "")), style=style)
    print_formatted_text(HTML(info + "按任意键进入主界面"), style=style)

    pause()
    flag = True
    clear()
    return True

def check_adb_server() -> Tuple[bool, Optional[Exception]: None]:
    adb_server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    adb_server.settimeout(0.25)
    try:
        adb_server.connect(("127.0.0.1", 5037))
    except socket.timeout:
        return False
    except Exception as e:
        return False, e
    adb_server.close()
    return True


def cleanup(code: int = 0):
    global style
    print_formatted_text(HTML(info + "正在结束ADB服务..."), style=style)
    if check_adb_server():
        subprocess.Popen(["adb.exe", "kill-server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True)
        # TODO: 优化kill-server
        # try:
        #     adbd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        #     adbd.settimeout(4)
        #     adbd.connect(("127.0.0.1", 5037))
        #     cmd = "kill"
        #     length_hex = f"{len(cmd):04X}"
        #     adbd.sendall((length_hex + cmd).encode("ascii"))
        #     adbd.close()
        # except socket.timeout, Exception:
        #     pass


    sys.exit(code)


def main() -> int:
    # do
    global flag
    global key
    global style
    try:
        clear()

        pre = pre_main() if not flag else True
        if not pre: return 1
        run("call logo")
        result = menu()
        match result:
            case "SHIFT_R":
                clear(); run("call start.bat"); return 0
            case "SHIFT_D": debug()
            case "onekeyroot":
                clear(); run("call root.bat")
            case "openshell":
                clear(); subprocess.run(["cmd.exe", "/k"], shell=True)
            case "forceupdate":
                clear(); run("start cmd /c upall.bat up"); return 0
            case "about": about()
            case "mods": mod()
            case "flash-files": flash()
            case "connection-debug": control()
            case "man-apps": appset()
            case "imoo-services": xtcservice()
            case "help-links":  help_menu()
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
    cleanup(main())
