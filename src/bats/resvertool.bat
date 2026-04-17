%userdebug%
setlocal enabledelayedexpansion
call link resversion url
call curltool.bat %url% 2>nul >nul
if %errorlevel% neq 0 (
   echo %ERROR%检查资源更新时出错，错误值:%errorlevel%
   pause.exe 返回
   exit /b
)
set "version=0"
set "target=%~1"
for /f "usebackq tokens=1,2 delims==" %%a in ("settings\resversion.txt") do (
    if "%%a"=="%target%" set "version=%%b"
)
for /f "usebackq tokens=1,2 delims==" %%a in ("resversion.txt") do (
    if "%%a"=="%target%" set "versiontmp=%%b"
)

if %versiontmp% GTR %version% (
    endlocal
    exit /b 1
) else (
    endlocal
    exit /b 0
)