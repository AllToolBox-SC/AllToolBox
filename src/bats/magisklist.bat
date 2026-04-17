@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
if not exist "Temp" md Temp >nul 2>&1

call color
cls
echo %INFO%等待adb连接...
device_check.exe adb
echo.

:id
echo %INFO%所有模块ID:
adb shell "su -c ls /data/adb/modules 2>/dev/null" 2>nul
set /p "id=请输入模块ID: "
echo.
adb shell "su -c [ -d /data/adb/modules/%id% ] 2>/dev/null && echo 模块存在 || echo 模块不存在" 2>nul

if %errorlevel% equ 0 goto exist
goto notexist

:notexist
按任意键返回
pause >nul
goto id

:exist
echo 模块ID=%id%

adb shell "su -c sed -n 's/^name=//p' /data/adb/modules/%id%/module.prop 2>/dev/null" 2>nul > Temp\name.csv
set /p name=<Temp\name.csv

adb shell "su -c sed -n 's/^version=//p' /data/adb/modules/%id%/module.prop 2>/dev/null" 2>nul > Temp\version.csv
set /p version=<Temp\version.csv

adb shell "su -c sed -n 's/^versionCode=//p' /data/adb/modules/%id%/module.prop 2>/dev/null" 2>nul > Temp\versionCode.csv
set /p versionCode=<Temp\versionCode.csv

adb shell "su -c sed -n 's/^author=//p' /data/adb/modules/%id%/module.prop 2>/dev/null" 2>nul > Temp\author.csv
set /p author=<Temp\author.csv

adb shell "su -c sed -n 's/^description=//p' /data/adb/modules/%id%/module.prop 2>/dev/null" 2>nul > Temp\description.csv
set /p description=<Temp\description.csv

adb shell "su -c [ -f /data/adb/modules/%id%/disable ] && echo 禁用 || echo 启用" 2>nul > Temp\status.csv
set /p status=<Temp\status.csv

adb shell "su -c echo 无" 2>nul > Temp\update.csv
set /p update=<Temp\update.csv

adb shell "su -c echo /data/adb/modules/%id%" 2>nul > Temp\path.csv
set /p MODULE_PATH=<Temp\path.csv

goto quanbu


:quanbu
echo ==============================================
echo %INFO%模块名称: %name%
echo %INFO%模块 ID: %id%
echo %INFO%版本名称: %version%
echo %INFO%版本代码: %versionCode%
echo %INFO%作者: %author%
echo %INFO%描述 : %description%
echo %INFO%启用状态: %status%
echo %INFO%可更新状态: %update%
echo %INFO%模块路径: %MODULE_PATH%
echo ==============================================
echo.


REM del /Q /F .\Temp\*.* >nul 2>nul
echo 模块信息读取完成,按任意返回
pause >nul
exit /b