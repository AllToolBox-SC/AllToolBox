:menu
CLS
call logo
echo %ORANGE%请选择需要root的型号%YELLOW%
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
if "%MENU%"=="1" set innermodel=I12&&call qmmi otherpash&&exit /b
if "%MENU%"=="2" set innermodel=IB&&call qmmi otherpash&&exit /b
if "%MENU%"=="3" set innermodel=I13C&&call qmmi otherpash&&exit /b
if "%MENU%"=="4" set innermodel=I13&&call qmmi otherpash&&exit /b
if "%MENU%"=="5" set innermodel=I19&&call qmmi otherpash&&exit /b
if "%MENU%"=="6" set innermodel=I18&&call qmmi otherpash&&exit /b
if "%MENU%"=="7" set innermodel=I20&&call qmmi v3pash&&exit /b
if "%MENU%"=="8" set innermodel=I25&&call qmmi v3pash&&exit /b
if "%MENU%"=="9" set innermodel=I25C&&call qmmi v3pash&&exit /b
if "%MENU%"=="10" set innermodel=I25D&&call qmmi v3pash&&exit /b
if "%MENU%"=="11" set innermodel=I32&&call qmmi v3pash&&exit /b
if "%MENU%"=="12" set innermodel=ND07&&call qmmi v3pash&&exit /b
if "%MENU%"=="13" set innermodel=ND01&&call qmmi v3pash&&exit /b
if "%MENU%"=="14" set innermodel=ND03&&goto nd03
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto menu

:nd03
echo.%info%你选择了ND03，即将为你开始root
echo.%info%免责声明：
echo.%info%由于ND03无法简单打开adb，无法判断你的机型和版本号，所以请你自行确认，如果机型和版本号不匹配，那么可能会变砖
echo.%info%该root文件并非3.0.2版本，实际版本为2.8.1，没有录屏等功能
echo.%info%该Root文件网络搜集而来，无任何限制
echo.%info%请确保手表是ND03-3.0.2版本
echo.%GREEN_2%════════════════════════
echo.%info%请认真阅读并等待5秒后继续
busybox sleep 5
echo.%info%请确保需要root的手表是ND03-3.0.2版本
pause
echo.%info%再次确认你的手表是3.0.2版本，如果不是请升级到3.0.2版本后继续
pause
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
ECHO %INFO%正在为您从本地拷贝文件
copy /Y "%cd%\EDL\%innermodel%.zip" "%cd%\EDL\rooting\root.zip"
if %errorlevel% neq 0 (
   ECHO %WARN%找不到文件
)
ECHO %INFO%开始解压文件
7z x EDL\rooting\root.zip -o.\EDL\rooting -aoa >nul 2>&1
if %errorlevel% neq 0 (
   ECHO %ERROR%解压文件时出现错误，错误值:%errorlevel%
   ECHO %INFO%按任意键退出
   pause >nul
   exit /b
)
ECHO %INFO%文件准备完成
echo.%info%等待9008设备连接...
device_check.exe qcom_edl&&ECHO.
ECHO.%INFO%获取9008端口
call edlport
ECHO.%INFO%发送引导
call QSaharaServer.bat -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\prog_firehose_ddr.elf
busybox sleep 2
ECHO.%INFO%批量刷入分区misc，super，abl_a，boot_a，vbmeta_a，vbmeta_system_a
call fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\rawprogram0.xml --noprompt
ECHO.%INFO%重启手表
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt
ECHO.%INFO%等待开机...
device_check.exe fastboot&&ECHO.
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%不是进入fastboot就是变砖！
ECHO.%INFO%请先点两下屏幕选择reboot to bootloader，随后按一下电源键确认，重启到bootloader
ECHO.%INFO%等待开机...
device_check.exe fastboot&&ECHO.
echo ffbm-02 > misc.bin
ECHO.%INFO%清除userdata
run_cmd "fastboot erase userdata"
ECHO.%INFO%刷入misc
run_cmd "fastboot flash misc misc.bin"
ECHO.%INFO%重启并进入recovery
run_cmd "fastboot boot EDL\rooting\recovery.img"
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
:twrp
adb shell twrp --version >twrptmp.txt
find /i "version" "%cd%\twrptmp.txt" 1>nul 2>nul || goto twrp
busybox sleep 5
ECHO.%INFO%进入sideload
adb shell twrp sideload
:twrp_dm
adb shell twrp --version >twrptmp.txt
find /i "version" "%cd%\twrptmp.txt" 1>nul 2>nul || goto twrp_dm
ECHO.%INFO%正在刷dm，请等待20秒...
busybox timeout 20 cmd /c adb sideload .\EDL\rooting\Dm.zip >twrplog.txt
find /i "error" "%cd%\twrplog.txt" >nul
if !errorlevel! equ 0 (
    echo.%error%出现严重错误
    echo.%error%无法刷入DM.zip
    echo.%error%这可能会导致你的手表变砖
    echo.%info%请尝试手动刷入DM.zip
    echo.%info%adb shell twrp sideload
    echo.%info%adb sideload .\EDL\rooting\Dm.zip
    echo.%info%如果你从来没有尝试过手刷z10，那么建议询问别人
    pause
)
ECHO.%INFO%坐和放宽，让我们等待您的手表自动重启四次
ECHO.%INFO%如果出现twrp的界面，请手动强制重启
ECHO.%INFO%进入正常系统后短接手表，直到进入9008
ECHO.%INFO%等待9008连接...
device_check.exe qcom_edl&&ECHO.
call qmmi z10
ECHO.%INFO%稍等片刻，即将开始
device_check.exe adb&&ECHO.
call boot_completed.bat
run_cmd "adb shell wm density 280"
run_cmd "adb shell am start -n com.topjohnwu.magisk/.ui.MainActivity"
:magisk
ECHO.%INFO%正在启动投屏！如手表端不方便操作，可在电脑端进行操作
ECHO.%INFO%提示：如果手表息屏，在投屏窗口单击右键即可
start scrcpy-noconsole.vbs
ECHO.%INFO%请打开Magisk右上角设置，往下滑，找到自动响应，修改为允许，然后找到超级用户通知，修改为无
ECHO.%INFO%然后在主页点击超级用户，将所有开关打开
ECHO.%INFO%操作完成后请按任意键继续
pause
adb shell "su -c magisk -v" || echo.%ERROR%授予出错，请重新授予&&goto magisk
ECHO.%ORANGE%--------------------------------------------------------------------
ECHO.%PINK%-把时间交给我们-
device_check.exe adb&&ECHO.
ECHO.%INFO%开始安装XTC Patch模块
adb push tmp\xtcpatch.zip /sdcard/xtcpatch.zip
adb shell "su -c magisk --install-module /sdcard/xtcpatch.zip"
run_cmd "adb shell ""rm -rf /sdcard/xtcpatch.zip"""
ECHO.%INFO%安装XTC Patch模块成功
run_cmd "adb shell wm density reset"
run_cmd "adb shell pm clear com.android.packageinstaller"
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
ECHO.%INFO%开始安装核心破解
call instapp.bat .\apks\toolkit.apk
call instapp.bat .\apks\LSP.apk
ECHO.%INFO%正在启动投屏！如手表端不方便操作，可在电脑端进行操作
ECHO.%INFO%提示：如果手表息屏，在投屏窗口单击右键即可
start scrcpy-noconsole.vbs
run_cmd "adb shell ""su -c am start -n org.lsposed.manager/.ui.activity.MainActivity"""
ECHO.%INFO%请勾选xtcpatch与激活核心破解，然后按任意键继续
pause
ECHO.%INFO%开始安装重要预装应用,共计3个[请勿跳过]
call instapp.bat .\apks\wxzf.apk
call instapp.bat .\rootproapks\MTfile.apk
ECHO.%INFO%开始安装预装应用,共计7个
busybox timeout 10 cmd /c set /p noapp=%YELLOW%如需跳过在10秒内输入no[不推荐]:%RESET%
if "%noapp%"=="no" goto ROOT-noapp
call instapp.bat .\apks\appstore.apk
call instapp.bat .\apks\appstore2.apk
call instapp.bat .\apks\appstore3.apk
call instapp.bat .\apks\vibrator.apk
ECHO.%INFO%预装应用安装完成
:ROOT-noapp
ECHO.%INFO%正在执行提前编译，可能需要一些时间
run_cmd "adb shell cmd package compile -m everything-profile -f com.xtc.i3launcher"
run_cmd "adb shell cmd package compile -m everything-profile -f com.xtc.setting"
ECHO.%GRAY%-跨越山海 终见曙光-
ECHO.%INFO%提示:如果需要在手表上安装应用，请在手表端选择弦-安装器，点击始终
ECHO.%INFO%您的手表已ROOT完毕
del /Q /F .\roottmp.txt >nul
pause
exit /b