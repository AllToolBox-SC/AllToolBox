import os
import time

from prompt_toolkit import print_formatted_text, HTML, prompt
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.shortcuts import clear

from command_runner import run
from config import ERROR, INFO, WARN, LINE, style
from menu_choice import menu_choice


def appset():
    run("cls")
    run("call logo")
    result = menu_choice(
        message="应用管理菜单",
        options=[
            ("A", "返回上级菜单"),
            ("1", "安装应用"),
            ("2", "卸载应用"),
            ("3", "安装xtc状态栏"),
            ("4", "设置微信QQ为开机自启应用"),
            ("5", "解除z10安装限制"),
        ],
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


def control():
    run("cls")
    run("call logo")
    result = menu_choice(
        message="连接与调试菜单",
        options=[
            ("A", "返回上级菜单"),
            ("1", "进入qmmi[9008]"),
            ("2", "scrcpy投屏"),
            ("3", "手表信息"),
            ("4", "打开充电可用"),
            ("5", "型号与innermodel对照表"),
            ("6", "高级重启"),
        ],
    )
    if result == "A":
        clear()
        return
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
    run("cls")
    run("call logo")
    result = menu_choice(
        message="刷机与文件菜单",
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
            ("10", "安卓8.1root后优化"),
        ],
    )
    match result:
        case "A":
            clear()
            return
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
            print_formatted_text(HTML(ERROR + "输入错误，请重新输入"), style=style)
    flash()


def xtcservice():
    run("cls")
    run("call logo")
    result = menu_choice(
        message="小天才服务菜单",
        options=[
            ("A", "返回上级菜单"),
            ("1", "手表强加好友[已弃用]"),
            ("2", "ADB/自检校验码计算"),
            ("3", "离线OTA升级"),
        ],
    )
    if result == "A":
        clear()
        return
    if result == "1":
        run("call friend")
    if result == "2":
        run('powershell -ExecutionPolicy Bypass -File ".\\zj.ps1"')
    if result == "3":
        run("call ota")
    xtcservice()


def debug():
    run("cls")
    run("call logo")
    result = menu_choice(
        message="DEBUG菜单",
        options=[
            ("A", "返回上级菜单"),
            ("1", "色卡"),
            ("2", "调整为未使用状态"),
            ("3", "调整为使用状态"),
            ("4", "调整为更新状态"),
            ("5", "debug sel"),
        ],
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
    debug()


def sel():
    run("cls")
    run("call sel file s .")
    run("pause")
    run("call sel file m .")
    run("pause")


def color():
    run("cls")
    print_formatted_text(HTML(INFO + "<black>BLACK</black>"), style=style)
    print_formatted_text(HTML(INFO + "<red>RED</red>"), style=style)
    print_formatted_text(HTML(INFO + "<green>GREEN</green>"), style=style)
    print_formatted_text(HTML(INFO + "<orange>ORANGE</orange>"), style=style)
    print_formatted_text(HTML(INFO + "<blue>BLUE</blue>"), style=style)
    print_formatted_text(HTML(INFO + "<magenta>MAGENTA</magenta>"), style=style)
    print_formatted_text(HTML(INFO + "<cyan>CYAN</cyan>"), style=style)
    print_formatted_text(HTML(INFO + "<white>WHITE</white>"), style=style)
    run("pause")


def help_menu():
    run("cls")
    run("call logo")
    result = menu_choice(
        message="帮助与链接",
        options=[
            ("A", "返回上级菜单"),
            ("1", "远程协助"),
            ("2", "超级恢复文件下载"),
            ("3", "离线OTA下载"),
            ("4", "面具模块下载"),
            ("5", "APK下载"),
            ("6", "工具箱官网"),
            ("7", "开发文档"),
            ("8", "123云盘解除下载限制"),
        ],
    )
    match result:
        case "A":
            clear()
            return
        case "1":
            print_formatted_text(HTML(WARN + "已弃用该功能"))
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
            prompt(HTML(INFO + "按任意键返回上级菜单"), key_bindings=kb, style=style)
        case "8":
            run("call patch123")
    help_menu()


def load_mod_menu():
    mod_dir = ".\\mod"
    if not os.path.isdir(mod_dir):
        print_formatted_text(HTML(ERROR + "未找到 mod 目录"), style=style)
        return None

    dirs = [d for d in os.listdir(mod_dir) if os.path.isdir(os.path.join(mod_dir, d))]

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

    result = menu_choice(message="已加载扩展", options=options)

    if result == "A":
        return None

    return mapping.get(result)


def run_mod_main(modname: str):
    run(f"cd /d mod\\{modname} && call main.bat")


def mod():
    run("cls")
    run("call logo")

    result = menu_choice(
        message="扩展管理",
        options=[
            ("A", "返回上级菜单"),
            ("1", "运行已安装扩展"),
            ("2", "安装扩展"),
            ("3", "卸载扩展"),
        ],
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


def about():
    print_formatted_text(HTML(f"<yellow>{LINE}</yellow>"), style=style)

    print_formatted_text(HTML(INFO + "本脚本由快乐小公爵236等开发者制作"), style=style)

    run("call thank.bat")

    print_formatted_text(HTML(INFO + "工具官网：https://atb.xgj.qzz.io"), style=style)
    print_formatted_text(HTML(INFO + "作者QQ：3247039462"), style=style)
    print_formatted_text(HTML(INFO + "工具箱交流与反馈QQ群：907491503"), style=style)
    print_formatted_text(HTML(INFO + "作者哔哩哔哩账号：https://b23.tv/L54R5ZV"), style=style)
    print_formatted_text(HTML(INFO + "bug与建议反馈邮箱：ATBbug@xgj.qzz.io"), style=style)

    run("call uplog.bat")

    print_formatted_text(HTML(f"<yellow>{LINE}</yellow>"), style=style)

    kb = KeyBindings()
    prompt(HTML(INFO + "按任意键返回上级菜单"), key_bindings=kb, style=style)
