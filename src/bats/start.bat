@ECHO OFF
setlocal enabledelayedexpansion
chcp 936 2>nul 1>nul
cd /d bin 2>nul 1>nul
ECHO.
ECHO [信息]正在启动中...
ECHO [信息]检查系统变量[PATH]...
set PATH=%PATH%;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Windows\System32\OpenSSH;%cd%
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
goto menu

:menu
setlocal enabledelayedexpansion
del /Q /F .\dir.tmp 1>nul 2>nul
CLS
call logo
ECHO.%ORANGE%XTC AllToolBox 控制台^&主菜单%BLUE% by xgj_236%YELLOW%
if exist .\mod (
    ECHO.%BLUE%已加载扩展:&cd mod&dir /b /ad >..\dir.tmp&cd ..
    set count=10
    for /f "tokens=*" %%a in (dir.tmp) do (
        set /a count+=1
        echo !count!.%%a
        set "dir_!count!=%%a"
    )
)
ECHO %YELLOW%╔════════════════════════════════════════════════════════════╗
ECHO ║1.一键root                    6.刷机与文件[子菜单]          ║
ECHO ║2.在此处打开cmd[含adb环境]    7.连接与调试[子菜单]          ║
ECHO ║3.强制更新脚本                8.应用管理[子菜单]            ║
ECHO ║4.关于脚本                    9.小天才服务[子菜单]          ║
ECHO ║5.扩展管理                    10.帮助与链接[子菜单]         ║
ECHO ╚════════════════════════════════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
for %%a in (dir_!MENU!) do set "modmain=!%%a!"
if "%MENU%"=="1" CLS & call root & ENDLOCAL & goto MENU
if "%MENU%"=="2" CLS & cmd /k & goto MENU
if "%MENU%"=="3" CLS & call upall up & goto MENU
if "%MENU%"=="4" goto about
if "%MENU%"=="5" goto mod
if "%MENU%"=="6" goto flash
if "%MENU%"=="7" goto control
if "%MENU%"=="8" goto appset
if "%MENU%"=="9" goto xtcservice
if "%MENU%"=="10" goto help
if "%MENU%"=="debug" goto debug
if exist .\mod\!modmain!\start.bat (
    call .\mod\!modmain!\start.bat
    goto menu
)
if exist .\mod\%MENU%\start.bat (
    call .\mod\%MENU%\start.bat
    goto menu
)
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
ECHO %ORANGE%应用管理菜单%YELLOW%
ECHO ╔══════════════════════════════════╗
ECHO ║A.返回上级菜单                    ║
ECHO ║1.安装应用                        ║
ECHO ║2.卸载应用                        ║
ECHO ║3.安装xtc状态栏                   ║
ECHO ║4.设置微信QQ为开机自启应用        ║
ECHO ║5.解除z10安装限制                 ║
ECHO ╚══════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" CLS & call instapp & goto appset
if "%MENU%"=="2" CLS & call unapp & goto appset
if "%MENU%"=="3" CLS & call xtcztl & goto appset
if "%MENU%"=="4" CLS & call qqwxautestart & goto appset
if "%MENU%"=="5" CLS & call z10openinst & goto appset
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto appset


:control
CLS
call logo
ECHO %ORANGE%连接与调试菜单%YELLOW%
ECHO ╔══════════════════════════════════════════════╗
ECHO ║A.返回上级菜单                                ║
ECHO ║1.进入qmmi[9008]    4.打开充电可用            ║
ECHO ║2.scrcpy投屏        5.型号与innermodel对照表  ║
ECHO ║3.手表信息          6.高级重启                ║
ECHO ╚══════════════════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" CLS & call qmmi & pause & goto control
if "%MENU%"=="2" CLS & device_check.exe adb & start scrcpy-noconsole.vbs & goto control
if "%MENU%"=="3" CLS & call listbuild & goto control
if "%MENU%"=="4" CLS & call opencharge & goto control
if "%MENU%"=="5" CLS & call innermodel & ECHO.%YELLOW%按任意键返回%RESET% & pause >nul & goto control
if "%MENU%"=="6" CLS & call rebootpro & goto control
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto control

:flash
CLS
call logo
ECHO %ORANGE%刷机与文件菜单%YELLOW%
ECHO ╔═════════════════════════════════════════════════════════════════════╗
ECHO ║A.返回上级菜单                                                       ║
ECHO ║1.从云端更新文件                     5.每次开机自刷入Recovery[不推荐]║
ECHO ║2.导入本地root文件                   6.刷入TWRP-recovery             ║
ECHO ║3.一键root[不刷userdata]             7.刷入XTC Patch                 ║
ECHO ║4.恢复出厂设置[不是超级恢复]         8.刷入Magisk模块                ║
ECHO ╚═════════════════════════════════════════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" CLS & call cloud & goto flash
if "%MENU%"=="2" CLS & call pashroot & goto flash
if "%MENU%"=="3" CLS & call root nouserdata & goto flash
if "%MENU%"=="4" CLS & call miscre & goto flash
if "%MENU%"=="5" CLS & call pashtwrppro & goto flash
if "%MENU%"=="6" CLS & call pashtwrp & goto flash
if "%MENU%"=="7" CLS & call xtcpatch & goto flash
if "%MENU%"=="8" CLS & call userinstmodule & goto flash
if "%MENU%"=="debug" CLS & call filemg & goto flash
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto flash

:xtcservice
CLS
call logo
ECHO %ORANGE%小天才服务菜单%YELLOW%
ECHO ╔══════════════════════════════════╗
ECHO ║A.返回上级菜单                    ║
ECHO ║1.手表强加好友[已弃用]            ║
ECHO ║2.ADB/自检校验码计算              ║
ECHO ║3.离线OTA升级                     ║
ECHO ╚══════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" CLS & call friend & goto xtcservice
if "%MENU%"=="2" CLS & powershell -ExecutionPolicy Bypass -File ".\zj.ps1" & goto xtcservice
if "%MENU%"=="3" CLS & call ota & goto xtcservice
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto xtcservice

:debug
CLS
call logo
ECHO %RED%DEBUG菜单%YELLOW%
ECHO ╔══════════════════════════════════╗
ECHO ║A.返回上级菜单                    ║
ECHO ║1.色卡                            ║
ECHO ║2.调整为未使用状态                ║
ECHO ║3.调整为使用状态                  ║
ECHO ║4.调整为更新状态                  ║
ECHO ║5.debug sel                       ║
ECHO ╚══════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" goto color
if "%MENU%"=="2" set /p="1" <nul > whoyou.txt & goto debug
if "%MENU%"=="3" set /p="2" <nul > whoyou.txt & goto debug
if "%MENU%"=="4" set /p="3" <nul > whoyou.txt & goto debug
if "%MENU%"=="5" goto sel
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto debug
:sel
CLS & call sel file s .
ECHO.%sel__file_path%，%sel__file_fullname%，%sel__file_name%，%sel__file_ext%，%sel__file_folder%，%sel__files%，%sel__folders% & pause
call sel file m .
ECHO.%sel__file_path%，%sel__file_fullname%，%sel__file_name%，%sel__file_ext%，%sel__file_folder%，%sel__files%，%sel__folders% & pause
goto debug

:color
CLS
ECHO.%BLACK%BLACK小天才工具大全AllToolBox%RESET%
ECHO.%RED_2%RED_2小天才工具大全AllToolBox%RESET%
ECHO.%GREEN_2%GREEN_2小天才工具大全AllToolBox%RESET%
ECHO.%ORANGE%ORANGE小天才工具大全AllToolBox%RESET%
ECHO.%BLUE_2%BLUE_2小天才工具大全AllToolBox%RESET%
ECHO.%MAGENTA%MAGENTA小天才工具大全AllToolBox%RESET%
ECHO.%CYAN_2%CYAN_2小天才工具大全AllToolBox%RESET%
ECHO.%WHITE_2%WHITE_2小天才工具大全AllToolBox%RESET%
ECHO.%GRAY%GRAY小天才工具大全AllToolBox%RESET%
ECHO.%RED%RED小天才工具大全AllToolBox%RESET%
ECHO.%GREEN%GREEN小天才工具大全AllToolBox%RESET%
ECHO.%YELLOW%YELLOW小天才工具大全AllToolBox%RESET%
ECHO.%BLUE%BLUE小天才工具大全AllToolBox%RESET%
ECHO.%PINK%PINK小天才工具大全AllToolBox%RESET%
ECHO.%CYAN%CYAN小天才工具大全AllToolBox%RESET%
ECHO.%WHITE%WHITE小天才工具大全AllToolBox%RESET%
ECHO.%ORANGEPRO%ORANGEPRO小天才工具大全AllToolBox%RESET%
ECHO.%ERROR%ERROR小天才工具大全AllToolBox%RESET%
ECHO.%INFO%INFO小天才工具大全AllToolBox%RESET%
ECHO.%WARN%WARN小天才工具大全AllToolBox%RESET%
ECHO.%RESET%RESET小天才工具大全AllToolBox%RESET%
pause
goto debug

:help
CLS
call logo
ECHO %ORANGE%帮助与链接%YELLOW%
ECHO ╔══════════════════════════════════╗
ECHO ║A.返回上级菜单                    ║
ECHO ║1.远程协助                        ║
ECHO ║2.123云盘解除下载限制             ║
ECHO ║3.超级恢复文件下载                ║
ECHO ║4.离线ota文件下载                 ║
ECHO ║5.面具模块文件下载                ║
ECHO ║6.应用apk文件下载                 ║
ECHO ║7.打开工具箱官网                  ║
ECHO ║8.打开开发文档                    ║
ECHO ╚══════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" CLS & call todesk & goto help
if "%MENU%"=="1" CLS & call patch123 & goto help
if "%MENU%"=="3" CLS & start https://www.123865.com/s/Q5JfTd-hEbWH & goto help
if "%MENU%"=="4" CLS & start https://www.123865.com/s/Q5JfTd-HEbWH & goto help
if "%MENU%"=="5" CLS & start https://www.123684.com/s/Q5JfTd-cEbWH & goto help
if "%MENU%"=="6" CLS & start https://www.123684.com/s/Q5JfTd-ZEbWH & goto help
if "%MENU%"=="7" CLS & start https://atb.xgj.qzz.io & goto help
if "%MENU%"=="8" CLS & echo.%WHITE% & type 开发文档.txt & echo. & pause & goto help
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto help

:mod
CLS
call logo
ECHO %ORANGE%扩展管理%YELLOW%
ECHO ╔══════════════════════════════════╗
ECHO ║A.返回上级菜单                    ║
ECHO ║1.安装扩展                        ║
ECHO ║2.卸载扩展                        ║
ECHO ╚══════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" goto MENU
if "%MENU%"=="a" goto MENU
if "%MENU%"=="1" CLS & call mod & goto mod
if "%MENU%"=="2" CLS & call unmod & goto mod
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto mod