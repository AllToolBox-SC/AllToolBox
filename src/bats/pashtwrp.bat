:twrp-re
CLS
call logo
echo %ORANGE%请选择型号%YELLOW%
ECHO.════════════════════════════════
ECHO.1.Z2
ECHO.2.Z3
ECHO.3.Z5A
ECHO.4.Z5Q
ECHO.5.Z5PRO
ECHO.6.Z6
ECHO.7.Z6巅峰版[包含文件]
ECHO.8.Z7[包含文件]
ECHO.9.Z7A
ECHO.10.Z7S[包含文件]
ECHO.11.Z8(或少年版)[包含文件]
ECHO.12.Z8A[包含文件]
ECHO.13.Z9(或少年版)[包含文件]
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
if "%MENU%"=="9" set innermodel=I25C&&goto otherpash
if "%MENU%"=="10" set innermodel=I25D&&goto v3pash
if "%MENU%"=="11" set innermodel=I32&&goto v3pash
if "%MENU%"=="12" set innermodel=ND07&&goto v3pash
if "%MENU%"=="13" set innermodel=ND01&&goto v3pash
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto twrp-re

:otherpash
ECHO 你的机型没有包含支持的文件，请前往云盘下载[不一定可用]
ECHO 按任意键打开下载链接
pause >nul
start https://www.123865.com/s/Q5JfTd-udbWH
ECHO 请确保你已经下载对应机型的TWRP文件
ECHO 按任意键去选择文件
pause >nul
call sel file s .. [img]
copy "%sel__file_path%" ".\EDL\rooting\recovery.img"
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\%innermodel%.zip .\EDL\rooting\root.zip
ECHO %INFO%解压所需文件%RESET%
7z x EDL\rooting\root.zip -o.\EDL\rooting\ -aoa >nul 2>&1
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
QSaharaServer.exe -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\msm8909w.mbn
ECHO %INFO%开始刷入recovery%RESET%
call edlport
fh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\recovery.xml --noprompt
ECHO %INFO%执行重启%RESET%
call edlport
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%刷入完成，按任意键返回%RESET%
pause >nul
exit /b

:v3pash
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\%innermodel%.zip .\EDL\rooting\root.zip
ECHO %INFO%解压所需文件%RESET%
7z x EDL\rooting\root.zip -o.\EDL\rooting\ -aoa >nul 2>&1
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
QSaharaServer.exe -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\msm8937.mbn
ECHO %INFO%开始刷入aboat,recovery%RESET%
call edlport
fh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\rawprogram0.xml --noprompt
ECHO %INFO%执行重启%RESET%
call edlport
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%刷入完成，按任意键返回%RESET%
pause >nul
exit /b