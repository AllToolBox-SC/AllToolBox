@echo off
setlocal enabledelayedexpansion
set args1=%1
set args2=%2
set args3=%3
:callinst
echo %CYAN%正在安装：%RESET%%PINK%%args1%%RESET%
REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"
REM 执行安装并将输出重定向到临时文件
if "%args2%"=="" adb wait-for-device install -r -t -d --no-streaming "%args1%" > ".\tmp\instapptmp.txt"
if "%args2%"=="install" adb wait-for-device install -r -t -d --no-streaming "%args1%" > ".\tmp\instapptmp.txt"
if "%args2%"=="data" goto data
if "%args2%"=="create" goto create
if "%args2%"=="3install" goto 3install
:instfind
REM 检查输出中是否包含Success
find /i "Success" "%cd%\tmp\instapptmp.txt" >nul
if !errorlevel! equ 0 (
    echo %GREEN% 安装成功！%RESET%
) else goto error

REM 删除临时文件
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1

endlocal
exit /b

:data

goto instfind

:create

setlocal enabledelayedexpansion
set "APK_PATH=%~1"
set "APK_SIZE=%~2"
set "APK_NAME=%~nx1"

echo %INFO% 使用 pm install-create 安装...%RESET%

REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"

REM 创建安装会话
set "SESSION_ID="
for /f "tokens=2 delims=[]" %%i in ('adb shell pm install-create -r -t -S !APK_SIZE!') do (
    set "SESSION_ID=%%i"
)

if "!SESSION_ID!"=="" (
    echo %ERROR% 创建安装会话失败%RESET%
    REM 删除临时文件
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    endlocal
    exit /b 1
)

echo %INFO% 会话创建成功: [!SESSION_ID!]%RESET%

REM 推送APK文件到设备临时目录
echo %INFO% 推送APK文件到设备...%RESET%
adb wait-for-device push "!APK_PATH!" /data/local/tmp/!APK_NAME!

REM 写入会话
echo %INFO% 写入安装会话...%RESET%
adb shell pm install-write !SESSION_ID! base.apk /data/local/tmp/!APK_NAME!

REM 提交安装并将输出重定向到临时文件
echo %INFO% 提交安装...%RESET%
adb shell pm install-commit !SESSION_ID! > ".\tmp\instapptmp.txt" 2>&1

REM 检查输出中是否包含Success
find /i "Success" ".\tmp\instapptmp.txt" >nul
if !errorlevel! equ 0 (
    echo %GREEN% pm install-create 安装成功%RESET%
    REM 清理临时文件
    adb shell rm -f /data/local/tmp/!APK_NAME!
    REM 删除临时文件
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    endlocal
    exit /b 0
) else (
    echo %ERROR% pm install-create 安装失败%RESET%
    REM 清理临时文件
    adb shell rm -f /data/local/tmp/!APK_NAME!
    REM 删除临时文件
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    endlocal
    exit /b 1
)
goto instfind

:3install

goto instfind

:error
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
set /p yesno=%ERROR% 安装失败！按任意键重试...[输入no跳过]%RESET%
if "%yesno%"=="no" endlocal&&exit /b
goto callinst