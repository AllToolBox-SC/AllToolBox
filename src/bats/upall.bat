%userdebug%
goto %1 1>nul 2>nul
:run
set /p whoyou=<whoyou.txt
if not "%whoyou%"=="3" goto check
echo %INFO%恭喜你成功完成更新
call uplog
exit /b
:check
del /Q /F .\versiontmp.txt 1>nul 2>nul
call link versiontmp url
call curltool.bat %url% 2>nul >nul
if %errorlevel% neq 0 (
   echo %ERROR%检查更新时出错，错误值:%errorlevel%
   exit /b
)

find /i "NO" "%cd%\versiontmp.txt" 2>nul 1>nul
if %errorlevel% equ 0 (
    CLS
    ECHO.%ERROR%运行失败%RESET%
    ECHO.%ERROR%运行失败%RESET%
    ECHO.%ERROR%运行失败%RESET%
    ECHO.%ERROR%运行失败%RESET%
    ECHO.%ERROR%运行失败%RESET%
    busybox sleep 5
    exit
)

set /p num1=<versiontmp.txt
set /p num2=<settings\versioncode.txt
if %num1% GTR %num2% (
    cls
    ECHO.%GREEN%检查到有新版本%RESET%
    call link versionnotice url
    call curltool.bat !url! 2>nul >nul
    type versionnotice.txt & ECHO.
    goto up
)

ECHO.%INFO%没有检查到新版本%RESET%
del /Q /F .\versiontmp.txt 1>nul 2>nul
exit /b
:up
del /Q /F .\versiontmp.txt 1>nul 2>nul
ECHO.%YELLOW%是否要更新？
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\yesno.json
set /p upall=<menutmp.txt
if not "%upall%"=="y" exit /b
adb kill-server >nul 2>nul
taskkill /F /IM adb.exe >nul 2>nul
call runupall