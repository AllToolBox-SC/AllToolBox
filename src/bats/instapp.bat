@echo off
setlocal enabledelayedexpansion
if "%1"=="" goto MAIN_MENU
set sel__file_path=%1
goto callinst
:MAIN_MENU
CLS
call logo.bat
ECHO %ORANGE%安装应用菜单%YELLOW%
ECHO ╔══════════════════════════════════════════════════╗
ECHO ║A.返回上级菜单                                    ║
ECHO ║1.选择并安装单个APK文件                           ║
ECHO ║2.选择并安装多个APK文件                           ║
ECHO ║3.选择一个文件夹并安装其中的所有APK文件           ║
ECHO ║4.检查adb设备连接                                 ║
ECHO ╚══════════════════════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" (
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    exit /b
)
if "%MENU%"=="a" (
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    exit /b
)
if "%MENU%"=="1" goto INSTALL_SINGLE_SEL
if "%MENU%"=="2" goto INSTALL_MULTI_SEL
if "%MENU%"=="3" goto INSTALL_FOLDER_SEL
if "%MENU%"=="4" goto CHECK_DEVICE
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto MAIN_MENU

:INSTALL_SINGLE_SEL
setlocal enabledelayedexpansion
echo.
echo %INFO% 正在打开文件选择对话框...%RESET%
call sel file s . [apk]

echo.
echo %INFO% 安装信息：%RESET%
echo %CYAN%文件：%RESET%%PINK%%sel__file_path%%RESET%
echo %CYAN%名称：%RESET%%WHITE%%sel__file_fullname%%RESET%
for %%A in ("%sel__file_path%") do (
    set SIZE_BYTES=%%~zA
    set /a SIZE_MB=%%~zA/1024/1024
)
echo %CYAN%大小：%RESET%%WHITE%!SIZE_BYTES! 字节 (!SIZE_MB! MB)%RESET%
ECHO.请接入ADB设备...
device_check.exe adb&&ECHO.
ECHO.

echo %INFO% 正在安装应用...%RESET%

REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"
REM 执行安装并将输出重定向到临时文件
adb install -r -t -d  "%sel__file_path%" > ".\tmp\instapptmp.txt"

REM 检查输出中是否包含Success
find /i "Success" "%cd%\tmp\instapptmp.txt" >nul
if !errorlevel! equ 0 (
    echo %GREEN% 安装成功！%RESET%
) else (
    echo %ERROR% 安装失败！正在尝试备用方案[pm install-create]%RESET%
    call :ALTERNATIVE_INSTALL "%sel__file_path%" "!SIZE_BYTES!"
    if !errorlevel! equ 0 (
        echo %GREEN% 备用方案安装成功！%RESET%
    ) else (
        echo %ERROR% 备用方案也失败了！%RESET%
    )
)

REM 删除临时文件
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
if not "%1"=="" exit /b
echo.
echo.按任意键返回菜单
pause >nul
endlocal
goto MAIN_MENU

:INSTALL_MULTI_SEL
setlocal enabledelayedexpansion
echo.
echo %INFO% 正在打开文件选择对话框(多选)...%RESET%
call sel file m . [apk]

echo.
echo %INFO% 选择的文件列表：%RESET%
set COUNT=0
for %%f in (%sel__files:/= %) do (
    set /a COUNT+=1
    echo %CYAN%!COUNT!.%RESET% %WHITE%%%f%RESET%
    if defined FILE_LIST (
        set "FILE_LIST=!FILE_LIST! "%%f""
    ) else (
        set "FILE_LIST="%%f""
    )
)
ECHO.请接入ADB设备...
device_check.exe adb&&ECHO.
echo.
echo %INFO% 开始批量安装...%RESET%
set SUCCESS=0
set FAILED=0

REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"

for %%i in (%sel__files:/= %) do (
    echo.
    echo %CYAN%正在安装: %%~nxi%RESET%
    for %%A in ("%%i") do set SIZE_BYTES=%%~zA
    
    REM 执行安装并将输出重定向到临时文件
    adb install -r -t -d "%%i" > ".\tmp\instapptmp.txt" 2>&1
    
    REM 检查输出中是否包含Success
    find /i "Success" ".\tmp\instapptmp.txt" >nul
    if !errorlevel! equ 0 (
        echo %GREEN% 成功%RESET%
        set /a SUCCESS+=1
    ) else (
        echo %ERROR% 失败，尝试备用方案%RESET%
        call :ALTERNATIVE_INSTALL "%%i" "!SIZE_BYTES!"
        if !errorlevel! equ 0 (
            echo %GREEN% 备用方案成功%RESET%
            set /a SUCCESS+=1
        ) else (
            echo %ERROR% 备用方案失败%RESET%
            set /a FAILED+=1
        )
    )
    
    REM 删除临时文件
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
)

echo.
echo %GREEN%批量安装完成！%RESET%
echo %CYAN%总计：%RESET%%WHITE%!COUNT!%RESET% %CYAN%个应用%RESET%
echo %GREEN%成功：%RESET%%WHITE%!SUCCESS!%RESET% %CYAN%个%RESET%
echo %RED%失败：%RESET%%WHITE%!FAILED!%RESET% %CYAN%个%RESET%
echo.按任意键返回菜单
pause >nul
endlocal
goto MAIN_MENU

:INSTALL_FOLDER_SEL
setlocal enabledelayedexpansion
echo.
echo %INFO% 正在打开文件夹选择对话框...%RESET%
call sel folder s .

echo %INFO% 选择的文件夹：%RESET%%PINK%%sel__folder_path%%RESET%

echo.
echo %INFO% 扫描APK文件...%RESET%
set COUNT=0
for %%i in ("%sel__folder_path%\*.apk") do (
    set /a COUNT+=1
    set "FILE_!COUNT!=%%i"
    echo %CYAN%!COUNT!.%RESET% %WHITE%%%i%RESET%
)

if !COUNT! equ 0 (
    echo %ERROR% 在指定文件夹中未找到APK文件%RESET%
    pause
    goto MAIN_MENU
)
ECHO.请接入ADB设备...
device_check.exe adb&&ECHO.
echo.
echo %INFO% 开始批量安装...%RESET%
set SUCCESS=0
set FAILED=0

REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"

for /l %%n in (1,1,!COUNT!) do (
    set "file=!FILE_%%n!"
    for %%A in ("!file!") do (
        set "filename=%%~nxA"
        set SIZE_BYTES=%%~zA
    )
    echo.
    echo %CYAN%正在安装: !filename!%RESET%
    
    REM 执行安装并将输出重定向到临时文件
    adb install -r -t -d "!file!" > ".\tmp\instapptmp.txt" 2>&1
    
    REM 检查输出中是否包含Success
    find /i "Success" ".\tmp\instapptmp.txt" >nul
    if !errorlevel! equ 0 (
        echo %GREEN% 成功%RESET%
        set /a SUCCESS+=1
    ) else (
        echo %ERROR% 失败，尝试备用方案%RESET%
        call :ALTERNATIVE_INSTALL "!file!" "!SIZE_BYTES!"
        if !errorlevel! equ 0 (
            echo %GREEN% 备用方案成功%RESET%
            set /a SUCCESS+=1
        ) else (
            echo %ERROR% 备用方案失败%RESET%
            set /a FAILED+=1
        )
    )
    
    REM 删除临时文件
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
)

echo.
echo %GREEN%批量安装完成！%RESET%
echo %CYAN%总计：%RESET%%WHITE%!COUNT!%RESET% %CYAN%个应用%RESET%
echo %GREEN%成功：%RESET%%WHITE%!SUCCESS!%RESET% %CYAN%个%RESET%
echo %RED%失败：%RESET%%WHITE%!FAILED!%RESET% %CYAN%个%RESET%
echo.按任意键返回菜单
pause >nul
endlocal
goto MAIN_MENU

:CHECK_DEVICE
setlocal enabledelayedexpansion
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
) else (
    echo %CYAN%ADB设备列表：%RESET%
    type ".\tmp\instapptmp.txt"
    echo.
    echo %GREEN%找到 !DEVICE_COUNT! 个设备%RESET%
)

REM 删除临时文件
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1

echo.
echo.按任意键返回菜单
pause >nul
endlocal
goto MAIN_MENU

:ALTERNATIVE_INSTALL
ECHO.请接入ADB设备...
device_check.exe adb&&ECHO.

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
adb push "!APK_PATH!" /data/local/tmp/!APK_NAME!

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

:callinst
echo %CYAN%正在安装：%RESET%%PINK%%sel__file_path%%RESET%
REM 创建临时目录
if not exist ".\tmp" mkdir ".\tmp"
REM 执行安装并将输出重定向到临时文件
adb install -r -t -d  "%sel__file_path%" > ".\tmp\instapptmp.txt"

REM 检查输出中是否包含Success
find /i "Success" "%cd%\tmp\instapptmp.txt" >nul
if !errorlevel! equ 0 (
    echo %GREEN% 安装成功！%RESET%
) else (
    echo %ERROR% 安装失败！按任意键重试...%RESET%
    if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1
    pause >nul
    goto callinst
)

REM 删除临时文件
if exist ".\tmp\instapptmp.txt" del ".\tmp\instapptmp.txt" >nul 2>&1

endlocal
exit /b


