
if "%1"=="1" goto INSTALL_SINGLE_SEL
if "%1"=="2" goto INSTALL_MULTI_SEL
if "%1"=="3" goto INSTALL_FOLDER_SEL

:INSTALL_SINGLE_SEL
setlocal enabledelayedexpansion
echo.
echo %INFO% 正在打开文件选择对话框...%RESET%
call sel file s . [zip]

echo.
echo %INFO%即将刷入：%sel__file_fullname%%RESET%
ECHO.请接入ADB设备...
device_check.exe adb&&ECHO.
ECHO.

for /f "delims=" %%i in ('adb shell getprop ro.product.innermodel') do set innermodel=%%i
ECHO.%INFO%您的设备innermodel为:%innermodel%
for /f "delims=" %%i in ('adb shell getprop ro.build.version.release') do set androidversion=%%i
ECHO.%INFO%您的设备安卓版本为:%androidversion%
echo %INFO% 正在刷入模块...%RESET%
if "%androidversion%"=="7.1.1" (call instmodule2.bat %sel__file_path%) else if "%androidversion%"=="4.4.4" (call instmodule2.bat %sel__file_path%) else (call instmodule.bat %sel__file_path%)
echo %GREEN%刷入完成！%RESET%
call userinstmodulereboot.bat

pause.exe 返回菜单
endlocal
goto MAIN_MENU

:INSTALL_MULTI_SEL
setlocal enabledelayedexpansion
echo.
echo %INFO% 正在打开文件选择对话框(多选)...%RESET%
call sel file m . [zip]

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
for /f "delims=" %%i in ('adb shell getprop ro.product.innermodel') do set innermodel=%%i
ECHO.%INFO%您的设备innermodel为:%innermodel%
for /f "delims=" %%i in ('adb shell getprop ro.build.version.release') do set androidversion=%%i
ECHO.%INFO%您的设备安卓版本为:%androidversion%
echo %INFO% 开始批量刷入...%RESET%

for %%i in (%sel__files:/= %) do (
    echo.
    echo %CYAN%正在刷入: %%~nxi%RESET%
    for %%A in ("%%i") do set SIZE_BYTES=%%~zA
    if "%androidversion%"=="7.1.1" (call instmodule2.bat %%i) else if "%androidversion%"=="4.4.4" (call instmodule2.bat %%i) else (call instmodule.bat %%i)
)

echo.
echo %GREEN%批量刷入完成！%RESET%
echo %CYAN%总计：%RESET%%WHITE%!COUNT!%RESET% %CYAN%个模块%RESET%
call userinstmodulereboot.bat

pause.exe 返回菜单
endlocal
goto MAIN_MENU

:INSTALL_FOLDER_SEL
setlocal enabledelayedexpansion
echo.
echo %INFO% 正在打开文件夹选择对话框...%RESET%
call sel folder s .

echo %INFO% 选择的文件夹：%RESET%%PINK%%sel__folder_path%%RESET%

echo.
echo %INFO% 扫描zip文件...%RESET%
set COUNT=0
for %%i in ("%sel__folder_path%\*.zip") do (
    set /a COUNT+=1
    set "FILE_!COUNT!=%%i"
    echo %CYAN%!COUNT!.%RESET% %WHITE%%%i%RESET%
)

if !COUNT! equ 0 (
    echo %ERROR% 在指定文件夹中未找到zip文件%RESET%
    pause.exe
    goto MAIN_MENU
)
ECHO.请接入ADB设备...
device_check.exe adb&&ECHO.
echo.
for /f "delims=" %%i in ('adb shell getprop ro.product.innermodel') do set innermodel=%%i
ECHO.%INFO%您的设备innermodel为:%innermodel%
for /f "delims=" %%i in ('adb shell getprop ro.build.version.release') do set androidversion=%%i
ECHO.%INFO%您的设备安卓版本为:%androidversion%
echo %INFO% 开始批量刷入...%RESET%

for /l %%n in (1,1,!COUNT!) do (
    set "file=!FILE_%%n!"
    for %%A in ("!file!") do (
        set "filename=%%~nxA"
        set SIZE_BYTES=%%~zA
    )
    echo.
    echo %CYAN%正在刷入: !filename!%RESET%
    if "%androidversion%"=="7.1.1" (call instmodule2.bat !file!) else if "%androidversion%"=="4.4.4" (call instmodule2.bat !file!) else (call instmodule.bat !file!)
)

echo.
echo %GREEN%批量刷入完成！%RESET%
echo %CYAN%总计：%RESET%%WHITE%!COUNT!%RESET% %CYAN%个模块%RESET%

pause.exe 返回菜单
endlocal
goto MAIN_MENU
