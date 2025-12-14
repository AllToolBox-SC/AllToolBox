@echo off
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('选择"是"继续运行解除安装限制，选择"否"将引导手表进入QMMI', '你的手表是否已经进入QMMI', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); exit [int]($result -eq 'Yes')"
set result=%errorlevel%

if %result% equ 1 (
    goto openinst
) else (
    goto qmmi
)
exit /b

:openinst
ECHO %INFO%请接入需要解除限制的adb设备%RESET%
device_check.exe adb&&ECHO.
ECHO %INFO%推送驱动文件%RESET%
adb push .\switch.db /sdcard/
ECHO %INFO%提权root权限%RESET%
adb root | find "restarting" 1>nul 2>nul || ECHO %ERROR%获取root权限时出错，可能没有降级或者不在QMMI%RESET%&& pause&& exit /b
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

:qmmi
ECHO %INFO%请接入需要刷写的9008设备%RESET%
adb reboot edl 2>nul 1>nul
device_check.exe qcom_edl&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\misc\misc_ND03.xml .\EDL\rooting\misc.xml
copy /Y .\EDL\misc\misc.img .\EDL\rooting\misc.img
ECHO %INFO%获取9008端口并执行引导%RESET%
call edlport
QSaharaServer.exe -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\prog_firehose_ddr.elf
ECHO %INFO%开始刷入misc%RESET%
call edlport
fh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%刷入完成，按任意键返回%RESET%
pause >nul
exit /b