%userdebug%

set /p whoyou=<whoyou.txt
if "%whoyou%"=="1" (
    call uplog
)

REM edl
set "QUALCOMM=0"
if exist "%SystemRoot%\System32\DriverStore\FileRepository\qdbusb*" (
    set "QUALCOMM=1"
)
if exist "%SystemRoot%\System32\DriverStore\FileRepository\qcusb*" (
    set "QUALCOMM=1"
)
if exist "%SystemRoot%\System32\DriverStore\FileRepository\qcmbn*" (
    set "QUALCOMM=1"
)
REM ADB
set "ADB_INSTALLED=0"
if exist "%SystemRoot%\System32\DriverStore\FileRepository\android_winusb.inf*" (
    set "ADB_INSTALLED=1"
)
REM VC运行库
set "VC_RUNTIMES=0"
if exist "%SystemRoot%\System32\vc*" (
    set "VC_RUNTIMES=1"
)

if %QUALCOMM% equ 1 if %ADB_INSTALLED% equ 1 if %VC_RUNTIMES% equ 1 (
    exit /b
)
echo %ERROR%检查到驱动未安装或环境不完整
if not exist .\drivers call cloud drivers
if %ADB_INSTALLED% neq 1 (
    echo %INFO%安装ADB驱动...
    pnputil /add-driver ".\drivers\adb\android_winusb.inf" /install
    echo %INFO%安装ADB驱动完毕
)
if %QUALCOMM% neq 1 (
    echo %INFO%安装Qualcomm驱动...
    .\drivers\9008.exe
    echo %INFO%安装Qualcomm驱动完毕
)
if %VC_RUNTIMES% neq 1 (
    echo %INFO%安装VC运行库...
    .\drivers\vc.exe
    echo %INFO%安装VC运行库完毕
)
echo %INFO%驱动和环境配置完毕，部分更改可能需要重启电脑以完成安装
exit /b