"""入口脚本，仅保留菜单相关逻辑，其余功能拆分到独立模块。"""

import os
import subprocess

import colorama
from prompt_toolkit import ANSI, HTML, print_formatted_text
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.shortcuts import clear

from command_runner import run
from config import INFO, WARN, style
from menu_choice import menu_choice
from menus import about, appset, control, debug, flash, help_menu, mod, xtcservice
from startup import cleanup, pre_main

initialized = False
key_interrupted = False


def menu() -> str:
    if os.path.exists("mod") and os.path.isdir("mod"):
        if len(os.listdir("mod")) != 0:
            print_formatted_text(HTML(INFO + "已加载扩展列表："), style=style)
            for idx, item in enumerate(os.listdir("mod"), start=1):
                print_formatted_text(f"{idx}. {item}", style=style)
        else:
            print_formatted_text(HTML(INFO + "已加载扩展列表：未加载任何扩展"), style=style)
    else:
        print_formatted_text(HTML(WARN + "扩展文件夹没有创建，正在创建..."), style=style)
        os.remove("mod") if os.path.isfile("mod") else None
        os.makedirs("mod", exist_ok=True)

    kb = KeyBindings()

    @kb.add('D')
    def _(event):
        event.app.exit(result="SHIFT_D")

    print_formatted_text(ANSI(colorama.Fore.RESET + colorama.Fore.YELLOW + "XTC AllToolBox 控制台&主菜单 " + colorama.Fore.BLUE + "by xgj_236" + colorama.Fore.LIGHTYELLOW_EX))

    result = menu_choice(
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
            ("exit", "退出脚本"),
        ],
        default="onekeyroot",
    )

    clear()
    return result


def main() -> int:
    global initialized
    global key_interrupted
    try:
        clear()

        if not initialized:
            pre_ready = pre_main()
            if not pre_ready:
                return 1
            initialized = True

        run("call logo")
        result = menu()
        match result:
            case "SHIFT_D":
                debug()
            case "onekeyroot":
                run("call root.bat")
            case "openshell":
                subprocess.run(["cmd.exe", "/k"], shell=True)
            case "forceupdate":
                run("start cmd /c upall.bat up")
                return 0
            case "about":
                about()
            case "mods":
                mod()
            case "flash-files":
                flash()
            case "connection-debug":
                control()
            case "man-apps":
                appset()
            case "imoo-services":
                xtcservice()
            case "help-links":
                help_menu()
            case "exit":
                return 0
        return main()
    except KeyboardInterrupt:
        if key_interrupted:
            print_formatted_text(HTML("\n" + WARN + "检测到用户中断，正在退出..."), style=style)
            return 0
        if not initialized:
            print_formatted_text(HTML("\n" + WARN + "检测到用户中断，正在退出..."), style=style)
            return 0
        key_interrupted = True
        clear()
        return main()


if __name__ == "__main__":
    cleanup(main())
