@echo off
:rebootP-qmmi
CLS
call logo
echo %ORANGE%请选择型号[全部自带文件]%YELLOW%
ECHO.════════════════════════════════
ECHO.1.Z6巅峰版
ECHO.2.Z7
ECHO.3.Z7A
ECHO.4.Z7S
ECHO.5.Z8(或少年版)
ECHO.6.Z8A
ECHO.7.Z9(或少年版)
ECHO.════════════════════════════════
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="1" set innermodel=I20&&goto v3pash
if "%MENU%"=="2" set innermodel=I25&&goto v3pash
if "%MENU%"=="3" set innermodel=I25C&&goto v3pash
if "%MENU%"=="4" set innermodel=I25D&&goto v3pash
if "%MENU%"=="5" set innermodel=I32&&goto v3pash
if "%MENU%"=="6" set innermodel=ND07&&goto v3pash
if "%MENU%"=="7" set innermodel=ND01&&goto v3pash
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto rebootP-qmmi

:v3pash
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\misc\misc_%innermodel%.xml .\EDL\rooting\misc.xml
copy /Y .\wipe.img .\EDL\rooting\misc.img
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
ECHO %INFO%如果长时间卡死在这里，可能是已经引导了，请尝试用qfil手刷
QSaharaServer.exe -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\msm8937.mbn >nul
ECHO %INFO%开始刷入misc%RESET%
call edlport
fh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt >nul
ECHO %INFO%执行重启%RESET%
call edlport
fh_loader.exe --port=COM%chkdev__edl__port% --reset --noprompt >nul && ECHO.
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%刷入完成，按任意键返回%RESET%
pause >nul
exit /b
