%userdebug%
setlocal enabledelayedexpansion
set args1=%~1
set args2=%~2
set args3=%~3
:callinst
echo %CYAN%正在安装：%RESET%%PINK%%args1%%RESET%

if not exist ".\tmp" mkdir ".\tmp"

if "%args2%"=="important" goto important
if "%args2%"=="nostreaming" call adbdevice adb && adb install -r -t -d --no-streaming "%args1%" > ".\tmp\instapptmp.txt"
if "%args2%"=="install" call adbdevice adb && adb install -r -t -d "%args1%" > ".\tmp\instapptmp.txt"
if "%args2%"=="data" goto data
if "%args2%"=="create" goto create
if "%args2%"=="3install" goto 3install
call adbdevice adb
adb install -r -t -d "%args1%" > ".\tmp\instapptmp.txt"
:instfind

if not exist ".\tmp\instapptmp.txt" %ERROR%发生错误，没有任何安装命令被调用，请检查语法是否正确 & goto error
find /i "Success" "%cd%\tmp\instapptmp.txt" >nul
if !errorlevel! equ 0 (
    echo %GREEN% 安装成功！%RESET%
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    endlocal
    set /a SUCCESS+=1
    exit /b
) else goto error

:data
echo %INFO% 使用 data/app 安装方式...%RESET%

for %%A in ("%args1%") do set APK_NAME=%%~nxA


if not exist ".\tmp" mkdir ".\tmp"
adb root | find "restarting" 1>nul 2>nul && goto data-root
adb shell "su -c magisk -v" && goto data-su
echo %error% 设备未获得root权限%RESET%
goto error

:data-su
echo %GREEN% 设备已获得su权限%RESET%


set "RANDOM_DIR=copydata-!RANDOM!!RANDOM!"
echo %INFO% 创建应用目录：/data/app/!RANDOM_DIR!%RESET%


adb shell su -c "mkdir -p /data/app/!RANDOM_DIR!" > ".\tmp\instapptmp.txt" 2>&1
if !errorlevel! neq 0 (
    echo %ERROR% 创建应用目录失败%RESET%
    type ".\tmp\instapptmp.txt" 2>nul
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)


echo %INFO% 推送APK文件到应用目录...%RESET%
call adbdevice adb
adb push "!args1!" /data/local/tmp/!APK_NAME! > ".\tmp\instapptmp.txt" 2>&1
if !errorlevel! neq 0 (
    echo %ERROR% 推送APK到临时目录失败%RESET%
    type ".\tmp\instapptmp.txt" 2>nul
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)


echo %INFO% 移动APK到应用目录...%RESET%
adb shell su -c "mv /data/local/tmp/!APK_NAME! /data/app/!RANDOM_DIR!/base.apk" > ".\tmp\instapptmp.txt" 2>&1
if !errorlevel! neq 0 (
    echo %ERROR% 移动APK文件失败%RESET%
    type ".\tmp\instapptmp.txt" 2>nul
    adb shell su -c "rm -rf /data/app/!RANDOM_DIR!" >nul 2>&1
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)


echo %INFO% 设置文件权限...%RESET%
adb shell su -c "chmod 755 /data/app/!RANDOM_DIR!" >nul 2>&1
adb shell su -c "chmod 644 /data/app/!RANDOM_DIR!/base.apk" >nul 2>&1


echo %INFO% 设置文件所有者...%RESET%
adb shell su -c "chown system:system /data/app/!RANDOM_DIR!/" >nul 2>&1
adb shell su -c "chown system:system /data/app/!RANDOM_DIR!/base.apk" >nul 2>&1

echo %GREEN% APK已复制到/data/app/!RANDOM_DIR!/base.apk%RESET%

echo.
echo %YELLOW% data/app安装方式可能需要重启才能生效%RESET%

adb shell su -c "rm -f /data/local/tmp/!APK_NAME!" >nul 2>&1
echo %GREEN% data/app安装完成！%RESET%
echo %CYAN%应用路径：/data/app/!RANDOM_DIR!/base.apk%RESET%
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
endlocal
set /a SUCCESS+=1
exit /b

:data-root
echo %GREEN% 设备已获得root权限%RESET%

set "RANDOM_DIR=copydata-!RANDOM!!RANDOM!"
echo %INFO% 创建应用目录：/data/app/!RANDOM_DIR!%RESET%

adb shell mkdir -p /data/app/!RANDOM_DIR! > ".\tmp\instapptmp.txt" 2>&1
if !errorlevel! neq 0 (
    echo %ERROR% 创建应用目录失败%RESET%
    type ".\tmp\instapptmp.txt" 2>nul
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)


echo %INFO% 推送APK文件到应用目录...%RESET%
call adbdevice adb
adb push "!args1!" /data/local/tmp/!APK_NAME! > ".\tmp\instapptmp.txt" 2>&1
if !errorlevel! neq 0 (
    echo %ERROR% 推送APK到临时目录失败%RESET%
    type ".\tmp\instapptmp.txt" 2>nul
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)


echo %INFO% 移动APK到应用目录...%RESET%
adb shell mv /data/local/tmp/!APK_NAME! /data/app/!RANDOM_DIR!/base.apk > ".\tmp\instapptmp.txt" 2>&1
if !errorlevel! neq 0 (
    echo %ERROR% 移动APK文件失败%RESET%
    type ".\tmp\instapptmp.txt" 2>nul
    adb shell rm -rf /data/app/!RANDOM_DIR! >nul 2>&1
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)


echo %INFO% 设置文件权限...%RESET%
adb shell chmod 755 /data/app/!RANDOM_DIR! >nul 2>&1
adb shell chmod 644 /data/app/!RANDOM_DIR!/base.apk >nul 2>&1


echo %INFO% 设置文件所有者...%RESET%
adb shell chown system:system /data/app/!RANDOM_DIR!/ >nul 2>&1
adb shell chown system:system /data/app/!RANDOM_DIR!/base.apk >nul 2>&1

echo %GREEN% APK已复制到/data/app/!RANDOM_DIR!/base.apk%RESET%


echo.
echo %YELLOW% data/app安装方式可能需要重启才能生效%RESET%

adb shell rm -f /data/local/tmp/!APK_NAME! >nul 2>&1
echo %GREEN% data/app安装完成！%RESET%
echo %CYAN%应用路径：/data/app/!RANDOM_DIR!/base.apk%RESET%
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
endlocal
set /a SUCCESS+=1
exit /b

:create
for %%A in ("%args1%") do set APK_SIZE=%%~zA
for %%A in ("%args1%") do set APK_NAME=%%~nxA

echo %INFO% 使用 pm install-create 安装...%RESET%

if not exist ".\tmp" mkdir ".\tmp"

set "SESSION_ID="
for /f "tokens=2 delims=[]" %%i in ('adb shell pm install-create -r -t -S !APK_SIZE!') do (
    set "SESSION_ID=%%i"
)

if "!SESSION_ID!"=="" (
    echo %ERROR% 创建安装会话失败%RESET%
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    goto error
)

echo %INFO% 会话创建成功: [!SESSION_ID!]%RESET%


echo %INFO% 推送APK文件到设备...%RESET%
call adbdevice adb
adb push "!args1!" /data/local/tmp/!APK_NAME!


echo %INFO% 写入安装会话...%RESET%
adb shell pm install-write !SESSION_ID! base.apk /data/local/tmp/!APK_NAME!


echo %INFO% 提交安装...%RESET%
adb shell pm install-commit !SESSION_ID! > ".\tmp\instapptmp.txt" 2>&1
adb shell rm -f /data/local/tmp/!APK_NAME!
goto instfind

:3install

echo %INFO% 使用 第三方安装器 安装...%RESET%


if not exist ".\tmp" mkdir ".\tmp"


echo %INFO% 推送APK文件到设备...%RESET%
call adbdevice adb
adb push "!args1!" /sdcard/tmp.apk

echo %INFO% 开始调用安装器安装...%RESET%
adb shell am start -a android.intent.action.VIEW -d file:///sdcard/tmp.apk -t application/vnd.android.package-archive > ".\tmp\instapptmp.txt" 2>&1
echo %INFO% 请在设备上进行安装后
pause.exe
echo %GREEN% 安装完成！%RESET%
call adbdevice adb
adb shell rm /sdcard/tmp.apk
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
endlocal
set /a SUCCESS+=1
exit /b

:error
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
set /p yesno=%ERROR% 安装失败！按任意键重试...[输入no跳过]%RESET%
if "%yesno%"=="no" endlocal&&set /a FAILED+=1&&exit /b
goto callinst

:important
set /a retry=0
call adbdevice adb
adb install -r -t -d "%args1%" > ".\tmp\instapptmp.txt"
find /i "Success" "%cd%\tmp\instapptmp.txt" >nul
if !errorlevel! equ 0 (
    echo %GREEN% 安装成功！%RESET%
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    endlocal
    exit /b
) else goto importanterror

:importanterror
set /a retry+=1
if !retry! lss 3 (
    echo %error%安装失败，10秒后重试
    busybox sleep 10
    goto important
) else goto error