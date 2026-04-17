@ECHO OFF
start /b disQ.exe
setlocal enabledelayedexpansion
chcp 936 2>nul 1>nul
cd /d bin 2>nul 1>nul

set "content="
for /f "tokens=* delims=" %%a in (main.txt) do (
    set "content=%%a"
    goto exec
)

:exec
if "%content%"=="main.bat" (
    call main.bat
) else if "%content%"=="start.bat" (
    goto startyes
)

:startyes
call color
set /p version=<settings\versionuser.txt
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
pause.exe 进入主界面
goto menu

:menu
CLS
call logo
call call call ECHO %notice%
ECHO.%ORANGE%XTC AllToolBox 主菜单%BLUE% by xgj_236%RESET%

del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\main.json
set /p MENU=<menutmp.txt
if "%MENU%"=="1" CLS & call root & goto menu
if "%MENU%"=="2" CLS & cmd /k & goto menu
if "%MENU%"=="3" goto about
if "%MENU%"=="4" goto commonly
if "%MENU%"=="5" CLS & call rebootpro & goto menu
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
pause.exe 返回
goto menu

:appset
CLS
call logo
ECHO %ORANGE%应用管理菜单%RESET%
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\appset.json
set /p MENU=<menutmp.txt
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call userinstapp & goto appset
if "%MENU%"=="2" CLS & call unapp & goto appset
if "%MENU%"=="3" CLS & call xtcztl & goto appset
if "%MENU%"=="4" CLS & call qqwxautestart & goto appset
if "%MENU%"=="5" CLS & call z10openinst & goto appset
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto appset

:commonly
CLS
call logo
ECHO %ORANGE%常用合集%RESET%
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\commonly.json
set /p MENU=<menutmp.txt
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
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\magisk.json
set /p MENU=<menutmp.txt
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call userinstmodule 1 & goto magisk
if "%MENU%"=="2" CLS & call userinstmodule 2 & goto magisk
if "%MENU%"=="3" CLS & call userinstmodule 3 & goto magisk
if "%MENU%"=="4" CLS & call xtcpatch & goto magisk
::if "%MENU%"=="5" CLS & call modulestore & goto magisk
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto magisk

:scripttool
CLS
call logo
ECHO %ORANGE%其他工具%RESET%
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\scripttool.json
set /p MENU=<menutmp.txt
if /i "%MENU%"=="A" goto menu
if "%MENU%"=="1" CLS & call innermodel & pause.exe 返回 & goto userdebug
if "%MENU%"=="2" CLS & call pashroot & goto scripttool
if "%MENU%"=="3" CLS & call root nouserdata & goto scripttool
if "%MENU%"=="4" CLS & call pashtwrppro & goto scripttool
if "%MENU%"=="5" CLS & call listbuild & goto commonly
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto scripttool