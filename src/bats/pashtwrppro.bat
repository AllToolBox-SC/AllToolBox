
CLS
if not exist .\EDL\twrp call cloud twrp
call logo
echo %ORANGE%请选择型号%YELLOW%
menu.exe .\menu\pashtwrp.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="1" set innermodel=I12
if "%MENU%"=="2" set innermodel=IB
if "%MENU%"=="3" set innermodel=I13C
if "%MENU%"=="4" set innermodel=I13
if "%MENU%"=="5" set innermodel=I19
if "%MENU%"=="6" set innermodel=I18
if "%MENU%"=="7" set innermodel=I20
if "%MENU%"=="8" set innermodel=I25
if "%MENU%"=="9" set innermodel=I25C
if "%MENU%"=="10" set innermodel=I25D
if "%MENU%"=="11" set innermodel=I32
if "%MENU%"=="12" set innermodel=ND07
if "%MENU%"=="13" set innermodel=ND01
::if "%MENU%"=="14" set innermodel=ND03
::if "%MENU%"=="15" set innermodel=ND08

ECHO %INFO%请接入需要导入刷写TWRP脚本的adb设备%RESET%
device_check.exe adb&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\twrp\%innermodel%.img .\EDL\rooting\recovery.img
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