@echo off
setlocal enabledelayedexpansion
call color.bat
:MAIN_MENU
CLS
echo.
echo %INFO% 检查设备连接...%RESET%

REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"

REM 执行adb devices命令并将输出重定向到临时文件
adb devices > ".\tmp\instapptmp.txt" 2>&1

REM 计算文件行数（不包括空行）
set /a DEVICE_COUNT=0
for /f "usebackq delims=" %%i in (".\tmp\instapptmp.txt") do (
    set /a DEVICE_COUNT+=1
)

REM 行数减1（去掉标题行）
set /a DEVICE_COUNT=!DEVICE_COUNT!-1

REM 判断设备数量并显示相应信息
if !DEVICE_COUNT! equ 0 (
    echo %ERROR% 没有找到连接的设备%RESET%
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
) else (
    echo %CYAN%ADB设备列表：%RESET%
    type ".\tmp\instapptmp.txt"
    echo.
    echo %GREEN%找到 !DEVICE_COUNT! 个设备%RESET%
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
)

if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
