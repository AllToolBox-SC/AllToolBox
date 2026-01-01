@ECHO OFF
setlocal enabledelayedexpansion
chcp 936 2>nul 1>nul
cd /d bin 2>nul 1>nul
ECHO.
ECHO [信息]正在启动中...
ECHO [信息]检查系统变量[PATH]...
set PATH=%cd%;%PATH%;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Windows\System32\OpenSSH
ECHO [信息]检查系统变量[PATHEXT]...
set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC
title XTC AllToolBox by xgj_236
call withone
call afterup
ECHO [信息]正在为你的cmd染上颜色...
call color
set /p="%cd%" <nul | find " " 1>nul 2>nul && ECHO %ERROR%当前工具所在路径含有空格，请尝试将工具移动到其他位置%RESET%&& pause&&exit /b
ECHO %INFO%正在检查更新...%RESET%
call upall run
ECHO %INFO%正在检查Windows属性...%RESET%
call checkwin

ECHO %INFO%正在检查ADB命令...%RESET%
adb version 1>nul 2>nul
if %errorlevel% neq 0 (
    ECHO %ERROR%ADB检查失败%RESET%
    timeout /t 2 /nobreak >nul
    exit
)
ECHO %INFO%检查ADB命令成功%RESET%
set /p="2" <nul > whoyou.txt
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
exit /b