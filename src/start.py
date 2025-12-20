import os
import sys
import shutil
from prompt_toolkit import (
    choice, 
    print_formatted_text, 
    ANSI, 
    HTML, 
    prompt,
    PromptSession
)
from prompt_toolkit.styles import Style
from prompt_toolkit.shortcuts import clear, set_title
from prompt_toolkit.key_binding import KeyBindings
import colorama
import subprocess
style = Style.from_dict({
    "yellow": "fg:yellow",
    "red": "fg:red",
    "orange": "fg:orange",
    "info": "fg:lightblue",
    "reset": "",
})

info = "<info>[信息]</info>"
error = "<red>[错误]</red>"
warn = "<orange>[警告]</orange>"

flag = False
key = False

LINE = "-" * 68

def menu() -> str:
    kb = KeyBindings()
    @kb.add('R')
    def _(event):
        event.app.exit(result="SHIFT_R")

    print_formatted_text(ANSI(colorama.Fore.RESET + colorama.Fore.YELLOW + "XTC AllToolBox 控制台&主菜单 " + colorama.Fore.BLUE + "by xgj_236" + colorama.Fore.LIGHTYELLOW_EX))
    style = Style.from_dict(
        {
            "number": "bold",
            "selected-option": "underline bold",
        }
    )
    
    result = choice(
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
        style=style,
        key_bindings=kb
    )

    clear(); return result

def run(cmd):
    subprocess.run(["cmd.exe", "/c", f"@echo off && call .\\color.bat && {cmd}"], shell=True)

def appset():
    run("cls")
    run("call logo")
    result = choice(
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
    )
    if result == "A":
        clear(); return
    if result == "1":
        run("call instapp")
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
    result = choice(
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
    run("cls")
    run("call logo")
    result = choice(
        message="刷机与文件菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "从云端更新文件"),
            ("2", "导入本地root文件"),
            ("3", "一键root"),
            ("4", "恢复出厂设置"),
            ("5", "开机自刷Recovery"),
            ("6", "刷入TWRP"),
            ("7", "刷入XTC Patch"),
            ("8", "刷入Magisk模块"),
        ],
    )
    if result == "A":
        clear(); return
    if result == "1":
        run("call cloud")
    if result == "2":
        run("call pashroot")
    if result == "3":
        run("call root nouserdata")
    if result == "4":
        run("call miscre")
    if result == "5":
        run("call pashtwrppro")
    if result == "6":
        run("call pashtwrp")
    if result == "7":
        run("call xtcpatch")
    if result == "8":
        run("call userinstmodule")
    flash()

def xtcservice():
    run("cls")
    run("call logo")
    result = choice(
        message="小天才服务菜单",
        #text="请选择",
        options=[
            ("A", "返回上级菜单"),
            ("1", "手表强加好友"),
            ("2", "ADB/自检校验码计算"),
            ("3", "离线OTA升级"),
        ],
    )
    if result == "A":
        clear(); return
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
    result = choice(
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
    )
    if result == "A":
        clear(); return
    if result == "1":
        color()
    if result == "2":
        run('echo 1>whoyou.txt')
    if result == "3":
        run('echo 2>whoyou.txt')
    if result == "4":
        run('echo 3>whoyou.txt')
    if result == "5":
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
    print(info + "BLACK")
    print(info + "RED")
    print(info + "GREEN")
    print(info + "ORANGE")
    print(info + "BLUE")
    print(info + "MAGENTA")
    print(info + "CYAN")
    print(info + "WHITE")
    run("pause")

def help_menu():
    run("cls")
    run("call logo")
    result = choice(
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
        ],
    )
    if result == "A":
        clear(); return
    if result == "1":
        run("call todesk")
    if result == "2":
        run("start https://www.123865.com/s/Q5JfTd-hEbWH")
    if result == "3":
        run("start https://www.123865.com/s/Q5JfTd-HEbWH")
    if result == "4":
        run("start https://www.123684.com/s/Q5JfTd-cEbWH")
    if result == "5":
        run("start https://www.123684.com/s/Q5JfTd-ZEbWH")
    if result == "6":
        run("start https://atb.xgj.qzz.io")
    if result == "7":
        run("type 开发文档.txt")
        run("pause")
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
        return None

    base = 10
    mapping = {}
    options = [("A", "返回上级菜单")]

    for i, name in enumerate(dirs, start=base + 1):
        key = str(i)
        mapping[key] = name
        options.append((key, name))

    result = choice(
        message="已加载扩展",
        options=options
    )

    if result == "A":
        return None

    return mapping.get(result)


def run_mod_main(modname):
    run(f'cd /d mod\\{modname} && call main.bat')

def mod():
    run("cls")
    run("call logo")

    result = choice(
        message="扩展管理",
        options=[
            ("A", "返回上级菜单"),
            ("1", "运行已安装扩展"),
            ("2", "安装扩展"),
            ("3", "卸载扩展"),
        ],
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

    subprocess.run(["cmd.exe", "/c",  "call", "thank.bat"], shell=True)

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

    subprocess.run(["cmd.exe", "/c",  "call", "uplog.bat"], shell=True)

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

def pre_main() -> bool:
    global flag
    run("@echo off")
    run("setlocal enabledelayedexpansion")

    # subprocess.run(["chcp", "65001"], shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print_formatted_text(HTML(info + "正在启动中..."), style=style)
    colorama.init(autoreset=True)
    run("call .\\color.bat")
    print_formatted_text(HTML(info + "检查系统变量[PATH]..."), style=style)
    run("set PATH=%PATH%;C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem;C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\;C:\\Windows\\System32\\OpenSSH\\;%cd%\\")
    print_formatted_text(HTML(info + "检查系统变量[PATHEXT]..."), style=style)
    run("set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;")
    set_title("XTC AllToolBox by xgj_236")
    os.makedirs("mod", exist_ok=True)
    for item in os.listdir("mod"):
        item_path = os.path.join("mod", item)
        if os.path.isdir(item_path):
            if os.path.exists(os.path.join(item_path, "autoexec.bat")):
                run(f'cd /d mod\\{item} && call autoexec.bat')

    os.chdir("..\\bin")
    wmic = subprocess.run(["cmd.exe", "/c", "where", "wmic.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True)

    if wmic.returncode != 0:
        r = input("WMIC工具未找到，是否安装WMIC？(Y/N)：")
        if r.lower() != "y":
            print_formatted_text(HTML(info + "正在安装WMIC..."), style=style)
            run("DISM /Online /Add-Capability /CapabilityName:WMIC~~~~")
    run("call withone")
    run("call afterup")
    print_formatted_text(HTML(info + "正在检查更新..."), style=style)
    run("call upall.bat run")
    print_formatted_text(HTML(info + "正在检查Windows属性..."), style=style)
    run("call checkwin")
    adb_process = subprocess.Popen(["adb.exe", "version"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, shell=True)
    adb_process.wait()
    if adb_process.returncode != 0:
        print_formatted_text(HTML(error + "ADB检查失败，返回值：", str(adb_process.returncode)), style=style)
        return False
    print_formatted_text(HTML(info + "检查ADB命令成功"), style=style)
    whoyou = open("whoyou.txt", "w", encoding="gbk")
    whoyou.write("2")
    whoyou.close()
    print_formatted_text(HTML("<yellow>" + LINE + "</yellow>"), style=style)
    print_formatted_text(HTML(f"""
        {warn}关于解绑：该工具不提供手表强制解绑服务，如您拾取他人的手表，请联系当地110公安机关归还失主。手表解绑属于非法行为，请归还失主。而不要尝试通过任何手段解除挂失锁
        {warn}关于收费：这个工具是完全免费的，如果你付费购买了那么请退款
        {warn}本脚本部分功能可能造成侵权问题，并可能受到法律追究，所以仅供个人使用，请勿用于商业用途
        {info}---请永远相信我们能给你带来免费又好用的工具---
        {info}关于官网：https://atb.xgj.qzz.io
        {info}关于作者：本脚本由快乐小公爵236等作者制作
        {info}作者QQ：3247039462
        {info}工具箱交流与反馈QQ群：907491503
        {info}作者哔哩哔哩账号：https://b23.tv/L54R5ZV
        {info}bug与建议反馈邮箱：ATBbug@xgj.qzz.io
    """.replace(" " * 8, "")), style=style)
    print_formatted_text(HTML("<yellow>" + LINE + "</yellow>"), style=style)
    print_formatted_text(HTML(info + "按任意键进入主界面"), style=style)

    kb = KeyBindings()

    @kb.add('<any>')
    def _(event):
        global pressed_key
        pressed_key = event.key_sequence[0].key
        event.app.exit()
    
    PromptSession(key_bindings=kb).prompt("")
    flag = True
    clear()
    return True

def main() -> int:
    global flag
    global key
    try:
        clear()
        pre = pre_main() if not flag else True
        if not pre: return 1
        run("call logo")
        result = menu()
        match result:
            case "SHIFT_R":
                run("call start.bat"); return 0
            case "onekeyroot":
                run("call root.bat")
            case "openshell":
                subprocess.run(["cmd.exe", "/k"], shell=True); return 0
            case "forceupdate":
                run("call upall.bat up"); return 0
            case "about": about()
            case "mods": mod()
            case "flash-files": flash()
            case "connection-debug": control()
            case "man-apps": appset()
            case "imoo-services": xtcservice()
            case "help-links":  help_menu()
            case "exit": return 0
        return main()
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

def cleanup(code: int):
    print_formatted_text(HTML(info + "正在结束ADB服务..."), style=style)
    subprocess.run(["adb.exe", "kill-server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True)
    sys.exit(code)

if __name__ == "__main__":
    cleanup(main())
