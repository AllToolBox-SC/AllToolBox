if "%1"=="" goto rebootP-qmmi
goto %1
:rebootP-qmmi
CLS
call logo
echo %ORANGE%请选择型号[全部自带文件]%YELLOW%
ECHO.════════════════════════════════
ECHO.1.Z2
ECHO.2.Z3
ECHO.3.Z5A
ECHO.4.Z5Q
ECHO.5.Z5PRO
ECHO.6.Z6
ECHO.7.Z6巅峰版
ECHO.8.Z7
ECHO.9.Z7A
ECHO.10.Z7S
ECHO.11.Z8(或少年版)
ECHO.12.Z8A
ECHO.13.Z9(或少年版)
ECHO.14.Z10(或少年版)
ECHO.════════════════════════════════
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="1" set innermodel=I12&&goto otherpash
if "%MENU%"=="2" set innermodel=IB&&goto otherpash
if "%MENU%"=="3" set innermodel=I13C&&goto otherpash
if "%MENU%"=="4" set innermodel=I13&&goto otherpash
if "%MENU%"=="5" set innermodel=I19&&goto otherpash
if "%MENU%"=="6" set innermodel=I18&&goto otherpash
if "%MENU%"=="7" set innermodel=I20&&goto v3pash
if "%MENU%"=="8" set innermodel=I25&&goto v3pash
if "%MENU%"=="9" set innermodel=I25C&&goto v3pash
if "%MENU%"=="10" set innermodel=I25D&&goto v3pash
if "%MENU%"=="11" set innermodel=I32&&goto v3pash
if "%MENU%"=="12" set innermodel=ND07&&goto v3pash
if "%MENU%"=="13" set innermodel=ND01&&goto v3pash
if "%MENU%"=="14" set innermodel=ND03&&goto z10
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto rebootP-qmmi

:v3pash
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\misc\misc_%innermodel%.xml .\EDL\rooting\misc.xml
copy /Y .\EDL\misc\misc.img .\EDL\rooting\misc.img
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
ECHO %INFO%如果长时间卡死在这里，可能是已经引导了
ECHO %INFO%请尝试按下ctrl+c，随后输入n，跳过该命令
QSaharaServer.bat -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\msm8937.mbn >nul
ECHO %INFO%开始刷入misc%RESET%
fh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt >nul
ECHO %INFO%执行重启%RESET%
qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%已进入QMMI%RESET%
exit /b

:otherpash
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\%innermodel%.zip .\EDL\rooting\root.zip
ECHO %INFO%解压所需文件%RESET%
7z x EDL\rooting\root.zip -o.\EDL\rooting\ -aoa >nul 2>&1
copy /Y .\EDL\misc\misc.mbn .\EDL\rooting\misc.mbn
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
ECHO %INFO%如果长时间卡死在这里，可能是已经引导了
ECHO %INFO%请尝试按下ctrl+c，随后输入n，跳过该命令
QSaharaServer.bat -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\msm8909w.mbn >nul
ECHO %INFO%开始刷入misc%RESET%
fh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt >nul
ECHO %INFO%执行重启%RESET%
qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%已进入QMMI%RESET%
exit /b

:z10
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\misc\misc_ND03.xml .\EDL\rooting\misc.xml
copy /Y .\EDL\misc\misc.img .\EDL\rooting\misc.img
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
ECHO %INFO%如果长时间卡死在这里，可能是已经引导了
ECHO %INFO%请尝试按下ctrl+c，随后输入n，跳过该命令
QSaharaServer.bat -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\prog_firehose_ddr.elf
ECHO %INFO%开始刷入misc%RESET%
fh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt
ECHO %INFO%执行重启%RESET%
qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%已进入QMMI%RESET%
exit /b
