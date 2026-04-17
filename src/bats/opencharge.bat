CLS
device_check.exe adb&&ECHO.
adb shell "su -c setprop persist.sys.charge.usable true"
echo %INFO%充电可用已开启%RESET%
pause.exe 返回