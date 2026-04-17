@echo off
setlocal enabledelayedexpansion
set TEMP_DIR=%cd%\Temp
set SYSTEM_DIR=%cd%\System
set LOCAL_VER=%SYSTEM_DIR%\versionpro.txt
set "REMOTE_VER_URL=https://ghproxy.net/https://raw.githubusercontent.com/wusannewcrack/AllToolBox1.2.7ultra/main/versionpro.txt"
set "NOTICE_URL=https://ghproxy.net/https://raw.githubusercontent.com/wusannewcrack/AllToolBox1.2.7ultra/main/versionnotice.txt"
set "DOWNLOAD_LINK_URL=https://ghproxy.net/https://raw.githubusercontent.com/wusannewcrack/AllToolBox1.2.7ultra/main/Downloadlink.txt"
set DL_FILE=%TEMP_DIR%\Downloadlink.txt
set UPDATE_ZIP=%TEMP_DIR%\update.zip
set EXTRACT_DIR=%TEMP_DIR%\update
if not exist "%SYSTEM_DIR%" mkdir "%SYSTEM_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
del /f /q "%TEMP_DIR%\*" 1>nul 2>nul
if not exist "%LOCAL_VER%" (
echo %ERROR%当前版本不存在
pause
exit /b 1
)
set /p LOCAL_VER_TEXT=<"%LOCAL_VER%"
echo %INFO%当前版本: %LOCAL_VER_TEXT%
echo %INFO%正在检查更新...
curl -k -L -s -f --connect-timeout 10 "%REMOTE_VER_URL%" -o "%TEMP_DIR%\remote_ver.txt" 1>nul 2>nul
if not exist "%TEMP_DIR%\remote_ver.txt" (
echo %ERROR%获取版本失败
pause
exit /b 1
)
set /p REMOTE_VER_TEXT=<"%TEMP_DIR%\remote_ver.txt"
echo %INFO%最新版本: %REMOTE_VER_TEXT%
if "%LOCAL_VER_TEXT%"=="%REMOTE_VER_TEXT%" (
echo %INFO%当前已是最新版本
exit /b 0
)
if /i "%REMOTE_VER_TEXT%" LSS "%LOCAL_VER_TEXT%" (
echo %INFO%当前为预览版
exit /b 0
)
echo %INFO%发现新版本
curl -k -L -s -f "%NOTICE_URL%" -o "%TEMP_DIR%\notice.tmp" 1>nul 2>nul
echo.
set yes=
set /p yes=是否要更新?[y/n]:
if /i not "!yes!"=="y" (
echo %INFO%已取消更新
exit /b 0
)
echo %INFO%关闭adb...
adb kill-server 1>nul 2>nul
taskkill /f /im adb.exe 1>nul 2>nul
echo %INFO%获取下载链接...
curl -k -L -s -f "%DOWNLOAD_LINK_URL%" -o "%DL_FILE%" 1>nul 2>nul
if not exist "%DL_FILE%" (
echo %ERROR%下载链接失败
pause
exit /b 1
)
set /p REAL_URL=<"%DL_FILE%"
echo %INFO%开始下载...
curl -# -k -L "%REAL_URL%" -o "%UPDATE_ZIP%"
if not exist "%UPDATE_ZIP%" (
echo %ERROR%下载失败
pause
exit /b 1
)
echo %INFO%解压中...
if exist "%EXTRACT_DIR%" rd /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%"
powershell -Command "Expand-Archive -Path '%UPDATE_ZIP%' -DestinationPath '%EXTRACT_DIR%' -Force" 1>nul 2>nul
set "UPD_TYPE="
if exist "%EXTRACT_DIR%\update.txt" (
set /p UPD_TYPE=<"%EXTRACT_DIR%\update.txt"
)
if /i "!UPD_TYPE!"=="full_update" (
echo %ERROR%暂不支持全量包更新
pause
exit /b 1
)
if /i "!UPD_TYPE!" neq "Incremental_update" (
echo %ERROR%未知更新包
set cont=
set /p cont=是否要继续更新[y/n]:
if /i not "!cont!"=="y" (
echo %INFO%已取消更新
exit /b 0
)
)
echo %INFO%安装更新...
xcopy "%EXTRACT_DIR%\*" "%cd%\" /e /h /r /y /q /c 1>nul 2>nul
copy /y "%EXTRACT_DIR%\versionpro.txt" "%SYSTEM_DIR%\versionpro.txt" 1>nul 2>nul
echo %INFO%更新完成
echo.
set clear=
set /p clear=是否清空Temp内文件[y/n]:
if /i "!clear!"=="y" (
del /f /q "%TEMP_DIR%\*" 1>nul 2>nul
for /d %%a in ("%TEMP_DIR%\*") do rd /s /q "%%a" 1>nul 2>nul
)
exit /b 0