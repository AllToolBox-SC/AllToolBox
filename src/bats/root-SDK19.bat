
ECHO.%INFO%正在备份相册
del /Q /F .\backupname.txt >nul 2>nul
call backup DCIM backup noask
ECHO.%INFO%正在重启到bootloader模式，你的手表并没有变砖
run_cmd "adb reboot bootloader"
device_check.exe fastboot&&ECHO.
ECHO.%INFO%正在刷入boot
fastboot flash boot EDL\rooting\sboot.img
ECHO.%INFO%重新启动，退出bootloader模式
fastboot reboot
ECHO.%INFO%等待设备连接
device_check.exe adb&&ECHO.
ECHO.%INFO%坐和放宽，让我们等待120秒
busybox sleep 120
ECHO.%INFO%安装管理器
call instapp .\EDL\rooting\manager.apk
ECHO.%INFO%启动管理器
run_cmd "adb shell am start -n com.topjohnwu.magisk/.ui.MainActivity"
ECHO.%INFO%修复运行环境
run_cmd "adb shell ""mkdir -p /sdcard/magisk"""
adb push tmp\magiskfile /sdcard/magisk
run_cmd "adb shell ""su -c rm -rf /data/adb/magisk"""
run_cmd "adb shell ""su -c cp -af /sdcard/magisk/* /data/adb/magisk/"""
run_cmd "adb shell ""su -c chmod -R 755 /data/adb/magisk/"""
ECHO.%INFO%刷入xtcpatch模块
call instmodule2.bat tmp\xtcpatch.zip
ECHO.%INFO%正在恢复相册
if exist .\backupnametxt set /p backupname=<backupnametxt
call backup DCIM recover noask
ECHO.%INFO%重启手表
adb reboot
ECHO.%INFO%您的手表ROOT完毕
ECHO.%INFO%删除临时文件
del /Q /F .\EDL\rooting\*.*
del /Q /F .\roottmp.txt >nul 2>nul
call timer end roottime
ECHO.%INFO%您的手表已ROOT完毕，耗时：%roottime%
pause.exe 返回
exit /b