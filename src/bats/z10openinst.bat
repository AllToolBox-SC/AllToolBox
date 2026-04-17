%userdebug%
:menu
ECHO %INFO%你的手表是否已经进入QMMI
ECHO.%YELLOW%════════════════════════════════════════════════%RESET%
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\yesno.json
set /p yesno=<menutmp.txt
if "%yesno%"=="y" goto openinst
if "%yesno%"=="n" call rebootpro qmmi z10
goto menu
:openinst
ECHO %INFO%请接入需要解除限制的adb设备%RESET%
device_check.exe adb&&ECHO.
ECHO %INFO%推送驱动文件%RESET%
adb push .\switch.db /sdcard/
ECHO %INFO%提权root权限%RESET%
adb root | find "restarting" 1>nul 2>nul || ECHO %ERROR%获取root权限时出错，可能没有降级或者不在QMMI%RESET%&& pause.exe&& exit /b
timeout /T 3 /NOBREAK >nul
ECHO %INFO%写入prop解除限制%RESET%
adb shell setprop persist.sys.xtc.adb_port 1
adb shell setprop persist.sys.adb.install 1
ECHO %INFO%将驱动写入桌面%RESET%
adb shell cp -R /sdcard/switch.db /data/data/com.xtc.i3launcher/databases/switch.db
ECHO %INFO%重启zygote进程[软重启]%RESET%
adb shell setprop ctl.restart zygote
ECHO %INFO%安装必备应用:抬腕文件[喜马拉雅少儿框架]，第三方应用启动器[海洋世界框架]%RESET%
adb install -r -t -d .\apks\z10apk.Apk
adb install -r -t -d .\apks\z10apk1.Apk
exit /b