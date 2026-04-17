@ECHO OFF
start /b disQ.exe
setlocal enabledelayedexpansion
cd /d "%~dp0"
chcp 936 2>nul 1>nul
cd /d bin 2>nul 1>nul

set "content="
for /f "tokens=* delims=" %%a in (main.txt) do (
    set "content=%%a"
    goto exec
)

:exec
if "%content%"=="main.bat" (
    goto startyes
) else if "%content%"=="start.bat" (
    call start.bat
)

:startyes
set "version_file=%~dp0version.txt"
set "version=未知版本"
if exist "%version_file%" for /f "delims=" %%a in (%version_file%) do set "version=%%a"
call color
title XTC AllToolBox %version% by xgj_236
ECHO %INFO%检查系统变量[PATH]...
set PATH=%cd%;%PATH%;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Windows\System32\OpenSSH
ECHO %INFO%检查系统变量[PATHEXT]...
set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC
set /p="%cd%" <nul | find " " 1>nul 2>nul && ECHO %ERROR%当前工具所在路径含有空格，请尝试将工具移动到其他位置%RESET%&& pause.exe&&exit /b
set /p whoyou=<whoyou.txt
if not "%whoyou%"=="2" (
    call uplog
    busybox sleep 2
    call cloud
)

set "updates="
for /f "tokens=* delims=" %%a in (updates.txt) do (
    set "updates=%%a"
    goto updates-ready
)

:updates-ready
call checkdriver
ECHO %INFO%正在检查更新...%RESET%
if "%updates%"=="y" (
call update.bat
goto announcements-ready
) else if "%updates%"=="n" (
    ECHO %WARN%检查更新已禁用%RESET%
    goto announcements-ready
)

:announcements-ready
set "announcements="
for /f "tokens=* delims=" %%a in (announcements.txt) do (
    set "announcements=%%a"
    goto announcements
)

:announcements
ECHO %INFO%正在拉取公告...%RESET%
if "%announcements%"=="y" (
    goto notice
) else if "%announcements%"=="n" (
    ECHO %WARN%拉取公告已禁用%RESET%
    goto ADB
)

:notice
call link notice url
call curltool.bat %url% 2>nul >nul
if %errorlevel% neq 0 (
   echo %ERROR%获取公告时出错，错误值:%errorlevel%
)
set notice=%ERROR%没有获取到公告
if exist .\notice.txt set /p notice=<notice.txt
goto ADB

:ADB
ECHO %INFO%正在检查ADB命令...%RESET%
adb version 1>nul 2>nul
if %errorlevel% neq 0 (
    ECHO %ERROR%ADB检查失败%RESET%
    timeout /t 2 /nobreak >nul
    exit
)
ECHO %INFO%检查ADB命令成功%RESET%
set /p="2" <nul > whoyou.txt
ECHO %INFO%正在调用虚拟显卡%RESET%
start /b VirtualGraphics.exe hide
REM VirtualGraphics.exe TurboMode hide 性能模式后台运行
REM VirtualGraphics.exe stop 停止运行
ECHO.%YELLOW%=--------------------------------------------------------------------=%RESET%
ECHO %WARN%关于解绑：该工具不提供手表强制解绑服务，如您拾取他人的手表，请联系当地110公安机关归还失主。手表解绑属于非法行为，请归还失主。而不要尝试通过任何手段解除挂失锁%RESET%
ECHO %WARN%关于收费：这个工具是完全免费的，如果你付费购买了那么请退款%RESET%
ECHO %WARN%本脚本部分功能可能造成侵权问题，并可能受到法律追究，所以仅供个人使用，请勿用于商业用途%RESET%
ECHO %INFO%---请永远相信我们能给你带来免费又好用的工具---%RESET%
ECHO %INFO%关于官网：https://atb.xgj.qzz.io%RESET%
ECHO %INFO%关于作者：本脚本由快乐小公爵236等作者制作%RESET%
ECHO.%INFO%作者QQ：3247039462%RESET%
ECHO.%INFO%工具箱交流与反馈QQ群：907491503%RESET%
ECHO.%INFO%作者哔哩哔哩账号：https://b23.tv/L54R5ZV%RESET%
ECHO.%INFO%bug与建议反馈邮箱：ATBbug@xgj.qzz.io%RESET%
ECHO.%YELLOW%=--------------------------------------------------------------------=%RESET%
ECHO %INFO%按任意键进入主界面%RESET%
pause >nul
goto menu

:menu
setlocal enabledelayedexpansion
CLS
call logo
call call call ECHO %notice%
ECHO.%ORANGE%XTC AllToolBox 主菜单%BLUE% by xgj_236%RESET%

ECHO %YELLOW%╔════════════════════════════════════════════════════════════╗%RESET%
ECHO %YELLOW%║ 1.一键Root设备                6.下载功能所需资源           ║%RESET%
ECHO %YELLOW%║ 2.在此处打开cmd[含adb环境]    7.应用管理                   ║%RESET%
ECHO %YELLOW%║ 3.关于脚本                    8.Magisk模块管理             ║%RESET%
ECHO %YELLOW%║ 4.常用功能                    9.其他功能                   ║%RESET%
ECHO %YELLOW%║ 5.高级重启                    10.脚本设置                  ║%RESET%
ECHO %YELLOW%╚════════════════════════════════════════════════════════════╝%RESET%
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="1" CLS & call root & goto menu
if "%MENU%"=="2" CLS & cmd /k & goto menu
if "%MENU%"=="3" goto about
if "%MENU%"=="4" goto commonly
if "%MENU%"=="5" CLS & call rebootpro & ENDLOCAL & goto menu
if "%MENU%"=="6" CLS & call cloud & goto menu
if "%MENU%"=="7" goto appset
if "%MENU%"=="8" goto magisk
if "%MENU%"=="9" goto scripttool
if "%MENU%"=="10" CLS & call settings & ENDLOCAL & goto menu
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto menu

:about
CLS
ECHO.%YELLOW%=--------------------------------------------------------------------=%RESET%
ECHO.%INFO%本脚本由快乐小公爵236等开发者制作%RESET%
call thank
ECHO %INFO%工具官网：https://atb.xgj.qzz.io%RESET%
ECHO.%INFO%作者QQ：3247039462%RESET%
ECHO.%INFO%工具箱交流与反馈QQ群：907491503%RESET%
ECHO.%INFO%作者哔哩哔哩账号：https://b23.tv/L54R5ZV%RESET%
ECHO.%INFO%bug与建议反馈邮箱：ATBbug@xgj.qzz.io%RESET%
call uplog
ECHO.%YELLOW%=--------------------------------------------------------------------=%RESET%
ECHO.%INFO%按任意键返回上级菜单%RESET%
pause >nul
goto menu

:appset
CLS
call logo
ECHO %ORANGE%应用管理菜单%RESET%
ECHO %YELLOW%╔══════════════════════════════════╗%RESET%
ECHO %YELLOW%║A.返回上级菜单                    ║%RESET%
ECHO %YELLOW%║1.安装应用                        ║%RESET%
ECHO %YELLOW%║2.卸载应用                        ║%RESET%
ECHO %YELLOW%║3.安装xtc状态栏                   ║%RESET%
ECHO %YELLOW%║4.设置微信QQ为开机自启应用        ║%RESET%
ECHO %YELLOW%║5.解除z10[1.0.1]安装限制          ║%RESET%
ECHO %YELLOW%╚══════════════════════════════════╝%RESET%
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call userinstapp & goto appset
if "%MENU%"=="2" CLS & call unapp & goto appset
if "%MENU%"=="3" CLS & call xtcztl & goto appset
if "%MENU%"=="4" CLS & call qqwxautestart & goto appset
if "%MENU%"=="5" CLS & call z10openinst & goto appset
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto appset

:scripttool
CLS
call logo
ECHO %ORANGE%其他工具%RESET%
ECHO %YELLOW%╔══════════════════════════════════════════════╗%RESET%
ECHO %YELLOW%║A.返回上级菜单                                ║%RESET%
ECHO %YELLOW%║1.型号与innermodel对照表                      ║%RESET%
ECHO %YELLOW%║2.导入本地root文件                            ║%RESET%
ECHO %YELLOW%║3.一键root[不刷userdata]                      ║%RESET%
ECHO %YELLOW%║4.开机自刷Recovery                            ║%RESET%
ECHO %YELLOW%║5.读取手表信息                                ║%RESET%
ECHO %YELLOW%╚══════════════════════════════════════════════╝%RESET%
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call innermodel & pause.exe 返回 & goto userdebug
if "%MENU%"=="2" CLS & call pashroot & goto scripttool
if "%MENU%"=="3" CLS & call root nouserdata & goto scripttool
if "%MENU%"=="4" CLS & call pashtwrppro & goto scripttool
if "%MENU%"=="5" CLS & call listbuild & goto commonly
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto scripttool

:commonly
CLS
call logo
ECHO %ORANGE%常用合集%RESET%
ECHO %YELLOW%╔═════════════════════════════════════════════════════════╗%RESET%
ECHO %YELLOW%║A.返回上级菜单                                           ║%RESET%
ECHO %YELLOW%║1.离线OTA升级            6.打开充电可用                  ║%RESET%
ECHO %YELLOW%║2.刷入TWRP               7.刷入固件包或超级恢复          ║%RESET%
ECHO %YELLOW%║3.备份与恢复             8.7.1机型刷入xp框架             ║%RESET%
ECHO %YELLOW%║4.安卓8.1root后优化      9.启用无线调试[adb]             ║%RESET%
ECHO %YELLOW%║5.scrcpy投屏                                             ║%RESET%
ECHO %YELLOW%╚═════════════════════════════════════════════════════════╝%RESET%
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call ota & goto commonly
if "%MENU%"=="2" CLS & call pashtwrp & goto commonly
if "%MENU%"=="3" CLS & call backup & goto commonly
if "%MENU%"=="4" CLS & call rootpro & goto commonly
if "%MENU%"=="5" CLS & call scrcpy-ui.bat & goto commonly
if "%MENU%"=="6" CLS & call opencharge & goto commonly
if "%MENU%"=="7" CLS & call super_recovery & goto commonly
if "%MENU%"=="8" CLS & call Xposed & goto commonly
if "%MENU%"=="9" CLS & call wifiadb & goto commonly
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto commonly

:magisk
CLS
call logo
ECHO %ORANGE%magisk模块管理%RESET%
ECHO %YELLOW%╔══════════════════════════════════╗%RESET%
ECHO %YELLOW%║A.返回上级菜单                    ║%RESET%
ECHO %YELLOW%║1.选择并刷入单个magisk模块        ║%RESET%
ECHO %YELLOW%║2.选择并刷入多个magisk模块        ║%RESET%
ECHO %YELLOW%║3.刷入文件夹内所有magisk模块      ║%RESET%
ECHO %YELLOW%║4.刷入XTC Patch[可用于更新]       ║%RESET%
ECHO %YELLOW%╚══════════════════════════════════╝%RESET%
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call userinstmodule 1 & goto magisk
if "%MENU%"=="2" CLS & call userinstmodule 2 & goto magisk
if "%MENU%"=="3" CLS & call userinstmodule 3 & goto magisk
if "%MENU%"=="4" CLS & call xtcpatch & goto magisk
::if "%MENU%"=="5" CLS & call modulestore & goto magisk
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto magisk

:debug
CLS
call logo
ECHO %RED%DEBUG菜单%RESET%
ECHO %YELLOW%╔══════════════════════════════════╗%RESET%
ECHO %YELLOW%║A.返回上级菜单                    ║%RESET%
ECHO %YELLOW%║1.色卡                            ║%RESET%
ECHO %YELLOW%║2.调整为未使用状态                ║%RESET%
ECHO %YELLOW%║3.调整为使用状态                  ║%RESET%
ECHO %YELLOW%║4.调整为更新状态                  ║%RESET%
ECHO %YELLOW%║5.debug sel                       ║%RESET%
ECHO %YELLOW%╚══════════════════════════════════╝%RESET%
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if /i "%MENU%"=="A" goto script_settings
if "%MENU%"=="1" goto color
if "%MENU%"=="2" echo 1> whoyou.txt & goto debug
if "%MENU%"=="3" echo 2> whoyou.txt & goto debug
if "%MENU%"=="4" echo 3> whoyou.txt & goto debug
if "%MENU%"=="5" goto sel
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto debug

:sel
CLS
call sel file s .
pause
call sel file m .
pause
goto debug

:color
CLS
ECHO.%BLACK%BLACK%RESET%
ECHO.%RED%RED%RESET%
ECHO.%GREEN%GREEN%RESET%
ECHO.%ORANGE%ORANGE%RESET%
ECHO.%BLUE%BLUE%RESET%
ECHO.%MAGENTA%MAGENTA%RESET%
ECHO.%CYAN%CYAN%RESET%
ECHO.%WHITE%WHITE%RESET%
pause
goto debug