echo.%info%免责声明：
echo.%info%^<没有声明可用版本就是全版本通刷^>
echo.%info%Root后版本均为2.8.1，没有录屏等功能
echo.%info%Root文件为网络搜集而来
echo.%info%正在为你准备开始
del /Q /F tmp.txt >nul 2>nul
del /Q /F .\*.img >nul 2>nul
del /Q /F .\tmp\boot.img >nul 2>nul
del /Q /F .\header >nul 2>nul
del /Q /F .\kernel_dtb >nul 2>nul
del /Q /F .\kernel >nul 2>nul
del /Q /F .\ramdisk.cpio >nul 2>nul
del /Q /F .\port_trace.txt >nul 2>nul
del /Q /F .\EDL\rooting\*.* >nul 2>nul
rd /Q /S .\EDL\rooting\xtcpatch >nul 2>nul
rd /Q /S .\EDL\rooting\magiskfile >nul 2>nul
md .\EDL\rooting 1>nul 2>>nul

ECHO %INFO%开始准备文件
if not exist .\EDL\ND03.zip call cloud z10
call progress.bat "7z x EDL\ND03.zip -o.\EDL\rooting -aoa >nul 2>&1" 225 100
echo.%GREEN_2%════════════════════════
ECHO %INFO%准备完成，即将开始root
echo.%info%等待9008设备连接...
device_check.exe qcom_edl&&ECHO.
ECHO.%INFO%获取9008端口
call edlport
ECHO.%INFO%发送引导
call QSaharaServer.bat -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\prog_firehose_ddr.elf
busybox sleep 2
ECHO.%INFO%刷入281恢复固件
call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting\281\ --sendxml=EDL\rooting\281\rawprogram0.xml --noprompt" 130 100
if exist "%cd%\fh_error.txt" (
    echo %error%恢复281失败!刷入失败!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
call fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting\281\ --sendxml=EDL\rooting\281\patch0.xml --noprompt
ECHO.%INFO%刷入root固件
call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting\ --sendxml=EDL\rooting\rawprogram0.xml --noprompt" 125 100
copy /Y "%cd%\tmp\eboot.img" "%cd%\EDL\rooting\eboot.img"
if exist "%cd%\fh_error.txt" (
    echo %error%root失败!刷入失败!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
ECHO.%INFO%清除boot
call fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\eboot.xml --noprompt
ECHO.%INFO%重启手表
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%不是进入fastboot就是变砖！
ECHO.%INFO%等待fastboot连接...
device_check.exe fastboot&&ECHO.
::ECHO.%INFO%格式化userdata
::run_cmd "fastboot erase userdata"
ECHO.%INFO%刷入boot
run_cmd "fastboot flash boot EDL\rooting\boot.img"
ECHO.%INFO%重启并进入recovery
run_cmd "fastboot boot EDL\rooting\recovery.img"
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
ECHO.%INFO%进入sideload
call adbdevice.bat sideload
ECHO.%INFO%正在刷dm，请等待20秒...
busybox timeout 20 cmd /c adb sideload .\EDL\rooting\Dm.zip
ECHO.
call adbdevice.bat noadb
ECHO.═══════════════════════
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%不是进入fastboot就是变砖！
ECHO.%INFO%等待fastboot连接...
device_check.exe fastboot&&ECHO.
ECHO.%INFO%刷入misc并重启
echo ffbm-02 > misc.bin
run_cmd "fastboot flash misc misc.bin"
run_cmd "fastboot reboot"
ECHO.%INFO%让我们等待DM进行重启三次操作
busybox timeout 300 cmd /c call dm_success
busybox sleep 5
run_cmd "adb shell wm density 288"
run_cmd "adb shell settings put system screen_off_timeout 2147483647"
ECHO.%INFO%正在自动打开自动响应，请稍后
busybox sleep 5
run_cmd "adb shell am start -n com.xtc.b/com.topjohnwu.magisk.ui.MainActivity"
busybox sleep 2
run_cmd "adb shell am start -n com.xtc.b/com.topjohnwu.magisk.ui.MainActivity"
device_check.exe adb&&ECHO.
busybox sleep 5
adb shell input tap 376 51
busybox sleep 0.5
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
adb shell input swipe 200 400 200 100
busybox sleep 0.5
adb shell input tap 200 330
busybox sleep 0.5
adb shell input tap 200 180
busybox sleep 0.5
adb shell input swipe 200 200 200 300
busybox sleep 0.5
adb shell input tap 200 150
busybox sleep 0.5
adb shell input tap 200 315

adb shell "su -c magisk -v" || echo.%ERROR%自动授予出错及手动授予权限&&goto magisk
goto automagisk

:magisk
run_cmd "adb shell am start -n com.xtc.b/com.topjohnwu.magisk.ui.MainActivity"
device_check.exe adb&&ECHO.
ECHO.%INFO%正在启动投屏！如手表端不方便操作，可在电脑端进行操作
ECHO.%INFO%提示：如果手表息屏，在投屏窗口单击右键即可
start scrcpy-noconsole.vbs
ECHO.%INFO%请打开Magisk右上角设置，往下滑，找到自动响应，修改为允许，然后找到超级用户通知，修改为无
ECHO.%INFO%然后在主页点击超级用户，将所有开关打开
ECHO.%INFO%操作完成后请按任意键继续
pause.exe
adb shell "su -c magisk -v" || echo.%ERROR%授予出错，请重新授予&&goto magisk

:automagisk
ECHO.%ORANGE%--------------------------------------------------------------------
ECHO.%PINK%-把时间交给我们-
device_check.exe adb&&ECHO.
ECHO.%INFO%开始安装XTC Patch模块
adb push tmp\xtcpatch.zip /sdcard/xtcpatch.zip
adb shell "su -c magisk --install-module /sdcard/xtcpatch.zip"
run_cmd "adb shell ""rm -rf /sdcard/xtcpatch.zip"""
ECHO.%INFO%安装XTC Patch模块成功
run_cmd "adb shell pm clear com.android.packageinstaller"
ECHO.%INFO%开始安装核心破解和systemplus
call instapp.bat .\apks\toolkit_4.8.apk important
call instapp.bat .\apks\Z10_SystemPlus.apk important
run_cmd "adb shell ""su -c am start -n org.lsposed.manager/.ui.activity.MainActivity"""
ECHO.%INFO%正在勾选作用域，请稍后
busybox sleep 5
adb shell input tap 115 271
busybox sleep 0.5
adb shell input tap 122 433
busybox sleep 0.5
adb shell input tap 200 173
busybox sleep 0.5
adb shell input tap 180 200
busybox sleep 0.5
adb shell input tap 25 30
busybox sleep 0.5
adb shell input tap 200 250
busybox sleep 0.5
adb shell input tap 180 200
busybox sleep 0.5
adb shell input tap 25 30
run_cmd "adb reboot"
device_check.exe adb&&ECHO.
call boot_completed.bat
busybox sleep 5
ECHO.%INFO%正在调整systemplus设定
run_cmd "adb shell am start -n com.zcg.systemplus/.ui.activity.GuideActivity"
busybox sleep 5
adb shell input tap 200 400
busybox sleep 0.5
adb shell input tap 200 270
busybox sleep 0.5
adb shell input tap 200 400
run_cmd "adb shell wm density reset"
run_cmd "adb shell settings put system screen_off_timeout 30"
ECHO.%INFO%擦除misc并重启
run_cmd "adb reboot bootloader"
device_check.exe adb fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "!devicestatus!"=="adb" (
    run_cmd "adb reboot bootloader"
)
run_cmd "fastboot erase misc"
run_cmd "fastboot reboot"
device_check.exe adb&&ECHO.
call boot_completed.bat
busybox sleep 5
ECHO.%INFO%开始安装预装应用
call instapp.bat .\apks\wxzf.apk
call instapp.bat .\apks\appsettings-ND03.apk
call instapp.bat .\apks\appmanager.apk
call instapp.bat .\apks\poke.apk
call instapp.bat .\apks\appstore.apk
call instapp.bat .\apks\appstore2.apk
call instapp.bat .\apks\appstore3.apk
call instapp.bat .\apks\appstore4.apk
ECHO.%INFO%预装应用安装完成
:ROOT-noapp
ECHO.%INFO%正在执行提前编译，可能需要一些时间
run_cmd "adb shell cmd package compile -m everything-profile -f com.xtc.i3launcher"
run_cmd "adb shell cmd package compile -m everything-profile -f com.xtc.setting"
ECHO.%GRAY%-跨越山海 终见曙光-
ECHO.%INFO%您的手表已ROOT完毕
pause.exe
exit /b


busybox timeout 90 cmd /c call adbdevice.bat adb
if "%errorlevel%"=="124" (
ECHO.%WARN%!未找到adb!
ECHO.%INFO%请等待DM进行重启三次操作
ECHO.%INFO%随后点开magisk，点击右上角重启，点击重启到bootloader
goto dm-noadb
)

run_cmd "adb reboot bootloader"
:dm-noadb
device_check.exe fastboot&&ECHO.