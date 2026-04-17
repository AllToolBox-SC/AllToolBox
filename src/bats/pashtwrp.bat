
CLS
if not exist .\EDL\twrp call cloud twrp
call logo
echo %ORANGE%请选择型号%YELLOW%
menu.exe .\menu\pashtwrp.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="1" set innermodel=I12&&set QSaharaServer=msm8909w.mbn
if "%MENU%"=="2" set innermodel=IB&&set QSaharaServer=msm8909w.mbn
if "%MENU%"=="3" set innermodel=I13C&&set QSaharaServer=msm8909w.mbn
if "%MENU%"=="4" set innermodel=I13&&set QSaharaServer=msm8909w.mbn
if "%MENU%"=="5" set innermodel=I19&&set QSaharaServer=msm8909w.mbn
if "%MENU%"=="6" set innermodel=I18&&set QSaharaServer=msm8909w.mbn
if "%MENU%"=="7" set innermodel=I20&&set QSaharaServer=msm8937.mbn
if "%MENU%"=="8" set innermodel=I25&&set QSaharaServer=msm8937.mbn
if "%MENU%"=="9" set innermodel=I25C&&set QSaharaServer=msm8937.mbn
if "%MENU%"=="10" set innermodel=I25D&&set QSaharaServer=msm8937.mbn
if "%MENU%"=="11" set innermodel=I32&&set QSaharaServer=msm8937.mbn
if "%MENU%"=="12" set innermodel=ND07&&set QSaharaServer=msm8937.mbn
if "%MENU%"=="13" set innermodel=ND01&&set QSaharaServer=msm8937.mbn
::if "%MENU%"=="14" set innermodel=ND03&&set QSaharaServer=prog_firehose_ddr.elf
::if "%MENU%"=="15" set innermodel=ND08&&set QSaharaServer=prog_firehose_ddr.elf


ECHO %INFO%请接入需要刷写的9008设备%RESET%
busybox timeout 10 cmd /c adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\twrp\%innermodel%.xml .\EDL\rooting\recovery.xml
copy /Y .\EDL\twrp\%innermodel%.img .\EDL\rooting\recovery.img
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
call QSaharaServer.bat -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\%QSaharaServer%
ECHO %INFO%开始刷入recovery%RESET%
call edlport >nul
call fh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\recovery.xml --noprompt
ECHO %INFO%执行重启%RESET%
call edlport >nul
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%刷入完成!%RESET%
pause.exe 返回
exit /b

ECHO %INFO%请接入需要导入刷写TWRP脚本的adb设备%RESET%

device_check.exe adb&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\%innermodel%.zip .\EDL\rooting\root.zip
ECHO %INFO%解压所需文件%RESET%
7z x EDL\rooting\root.zip -o.\EDL\rooting\ -aoa >nul 2>&1
copy "%sel__file_path%" ".\EDL\rooting\recovery.img"
ECHO %INFO%开始导入脚本%RESET%
adb push .\EDL\rooting\recovery.img /sdcard/
adb push rec.sh /sdcard/
adb shell "su -c cp /sdcard/recovery.img /data/rec.img"
adb shell "su -c cp /sdcard/rec.sh /data/adb/service.d/rec.sh"
adb shell "chmod 755 -R /data/adb/service.d/rec.sh"
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%刷入完成!%RESET%
pause.exe 返回
exit /b