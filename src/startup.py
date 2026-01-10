import os
import sys
import platform
import time
import subprocess
import socket
from typing import Tuple

import colorama
from prompt_toolkit import HTML, print_formatted_text
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.shortcuts import clear, set_title
from prompt_toolkit import PromptSession

from command_runner import run
from config import INFO, WARN, ERROR, style


def checkwin() -> Tuple[str, str, str, str]:
    return (
        platform.system(),
        platform.release(),
        platform.version(),
        platform.architecture()[0],
    )


def pause():
    kb = KeyBindings()

    @kb.add('<any>')
    def _(event):
        event.app.exit()

    PromptSession(key_bindings=kb).prompt("")


def pre_main() -> bool:
    bin_path = os.path.abspath(os.path.join(os.getcwd(), ".", "bin"))
    if os.path.isdir(bin_path):
        os.chdir(bin_path)
    else:
        print_formatted_text(HTML(WARN + f"未找到 bin 目录，跳过切换目录: {bin_path}"), style=style)
    run("@echo off")
    run("setlocal enabledelayedexpansion")
    if os.getenv("ATB_OLD_MENU", "0") == "1":
        run("call start.bat")
        sys.exit()

    print_formatted_text(HTML(INFO + "正在启动中..."), style=style)
    colorama.init(autoreset=True)
    run("call .\\color.bat")
    if " " in os.path.abspath("."):
        if os.getenv("ATB_IGNORE_SPACE_IN_PATH", "0") != "1":
            print_formatted_text(HTML(ERROR + "当前路径包含空格，会导致未知问题，请将工具箱放置在无空格路径下运行，即将退出..."), style=style)
            print_formatted_text(HTML(INFO + "若要跳过此检测，请设置环境变量ATB_IGNORE_SPACE_IN_PATH=1"), style=style)
            time.sleep(2)
            return False
        print_formatted_text(HTML(WARN + "当前路径包含空格，可能导致未知问题，建议将工具箱放置在无空格路径下运行"), style=style)

    print_formatted_text(HTML(INFO + "检查系统变量[PATH]..."), style=style)
    run("set PATH=%PATH%;C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem;C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\;C:\\Windows\\System32\\OpenSSH\\;%cd%\\")
    print_formatted_text(HTML(INFO + "检查系统变量[PATHEXT]..."), style=style)
    run("set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;")
    set_title("XTC AllToolBox by xgj_236")
    os.makedirs("mod", exist_ok=True)
    for item in os.listdir("mod"):
        item_path = os.path.join("mod", item)
        if os.path.isdir(item_path) and os.path.exists(os.path.join(item_path, "start.bat")):
            run(f'cd /d mod\\{item} && call start.bat')

    run("call withone")
    run("call afterup")
    if os.getenv("ATB_SKIP_UPDATE", "0") != "1":
        print_formatted_text(HTML(INFO + "正在检查更新..."), style=style)
        run("call upall.bat run")
    if os.getenv("ATB_SKIP_PLATFORM_CHECK", "0") != "1":
        print_formatted_text(HTML(INFO + "正在检查Windows属性..."), style=style)
        os_name, os_release, os_version, arch = checkwin()
        arch_value = "x64" if arch == "64bit" else "x86" if arch == "32bit" else "arm64-v8a"
        print_formatted_text(HTML(INFO + f"当前运行环境:{os_name}{os_release}_{arch_value}_{os_version}"), style=style)
        try:
            os_vercode = float(os_release)
        except ValueError:
            os_vercode = 0
        if os_vercode <= 7:
            print_formatted_text(HTML(ERROR + "此脚本需要 Windows 8 或更高版本"), style=style)
            pause()
            return False
        print_formatted_text(HTML(INFO + f"当前系统: {os_name} {os_release}"), style=style)

        adb_process = subprocess.Popen(["adb.exe", "version"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, shell=True)
        adb_process.wait()
        if adb_process.returncode != 0:
            print_formatted_text(HTML(ERROR + "ADB检查失败，返回值：" + str(adb_process.returncode)), style=style)
            return False
        print_formatted_text(HTML(INFO + "检查ADB命令成功"), style=style)
    try:
        with open("whoyou.txt", "w", encoding="gbk") as whoyou:
            whoyou.write("2")
    except PermissionError:
        print_formatted_text(HTML(WARN + "写入 whoyou.txt 失败（权限问题），已跳过"), style=style)
    print_formatted_text(
        HTML(
            (
                f"{WARN}关于解绑：该工具不提供手表强制解绑服务，如您拾取他人的手表，请联系当地110公安机关归还失主。手表解绑属于非法行为，请归还失主。而不要尝试通过任何手段解除挂失锁\n"
                f"{WARN}关于收费：这个工具是完全免费的，如果你付费购买了那么请退款\n"
                f"{WARN}本脚本部分功能可能造成侵权问题，并可能受到法律追究，所以仅供个人使用，请勿用于商业用途\n"
                f"{INFO}---请永远相信我们能给你带来免费又好用的工具---\n"
                f"{INFO}关于官网：https://atb.xgj.qzz.io\n"
                f"{INFO}关于作者：本脚本由快乐小公爵236等作者制作\n"
                f"{INFO}作者QQ：3247039462\n"
                f"{INFO}工具箱交流与反馈QQ群：907491503\n"
                f"{INFO}作者哔哩哔哩账号：https://b23.tv/L54R5ZV\n"
                f"{INFO}bug与建议反馈邮箱：ATBbug@xgj.qzz.io"
            )
        ),
        style=style,
    )
    print_formatted_text(HTML(INFO + "按任意键进入主界面"), style=style)

    pause()
    clear()
    return True


def check_adb_server() -> bool:
    adb_server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    adb_server.settimeout(0.25)
    try:
        adb_server.connect(("127.0.0.1", 5037))
    except Exception:
        return False
    adb_server.close()
    return True


def cleanup(code: int = 0):
    print_formatted_text(HTML(INFO + "正在结束ADB服务..."), style=style)
    if check_adb_server():
        subprocess.Popen(["adb.exe", "kill-server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True)

    run("endlocal")
    sys.exit(code)
