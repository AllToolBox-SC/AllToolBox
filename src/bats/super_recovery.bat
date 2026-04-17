%userdebug%
CLS
echo %info%请手动下载并解压固件包，或者下载并安装超级恢复，然后选择您解压到的目录，或者选择超级恢复目录下的data文件夹
pause.exe
call sel folder s ..
if /i not "%sel__folder_name%"=="data" (
    echo %WARN%选择的文件夹名称不是data，请确认是固件包
    pause.exe 继续并忽略
)

dir /b "%sel__folder_path%\*.img" 2>nul >nul
if not %errorlevel% equ 0 (
    echo %error%选择的目录中没有*.img文件
    pause.exe 返回
    exit /b
)

dir /b "%sel__folder_path%\*.xml" 2>nul >nul
if not %errorlevel% equ 0 (
    echo %error%选择的目录中没有*.xml文件
    pause.exe 返回
    exit /b
)

set "QSaharaServer="

if exist "%sel__folder_path%\prog_firehose_ddr.elf" (
    set QSaharaServer=prog_firehose_ddr.elf
)

dir /b "%sel__folder_path%\*8937*" 2>nul >nul
if %errorlevel% equ 0 (
    set QSaharaServer=msm8937.mbn
)

dir /b "%sel__folder_path%\*8909*" 2>nul >nul
if %errorlevel% equ 0 (
    set QSaharaServer=msm8909w.mbn
)

if "%QSaharaServer%" == "" (
    echo %error%选择的目录没有引导文件
    pause.exe 返回
    exit /b
)

set "check_files=rawprogram1.xml rawprogram2.xml patch.xml"

for %%f in (%check_files%) do (
    if not exist "%sel__folder_path%\%%f" (
        goto rec_1
    )
)
if not exist "%sel__folder_path%\rawprogram0.xml" (
    echo %error%选择的目录没有可刷录入的xml
    pause.exe 返回
    exit /b
)
goto rec_0
:rec_1
ECHO.%INFO%准备开始...
device_check.exe qcom_edl&&ECHO.

ECHO.%INFO%获取端口并发送引导
call edlport
call QSaharaServer.bat -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\%QSaharaServer%
busybox sleep 2

call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=%sel__folder_path%\ --sendxml=%sel__folder_path%\rawprogram0.xml --noprompt" 130 100
if exist "%cd%\fh_error.txt" (
    echo %error%超级恢复失败!刷入rawprogram0时出错!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
echo.%SUCCESS%刷入rawprogram0成功
call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=%sel__folder_path%\ --sendxml=%sel__folder_path%\rawprogram1.xml --noprompt" 120 100
if exist "%cd%\fh_error.txt" (
    echo %error%超级恢复失败!刷入rawprogram1时出错!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
echo.%SUCCESS%刷入rawprogram1成功
call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=%sel__folder_path%\ --sendxml=%sel__folder_path%\rawprogram2.xml --noprompt" 120 100
if exist "%cd%\fh_error.txt" (
    echo %error%超级恢复失败!刷入rawprogram2时出错!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
echo.%SUCCESS%刷入rawprogram2成功
call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=%sel__folder_path%\ --sendxml=%sel__folder_path%\patch0.xml --noprompt" 5 100
if exist "%cd%\fh_error.txt" (
    echo %error%超级恢复失败!刷入patch0时出错!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
echo.%SUCCESS%刷入patch0成功
ECHO.%Yellow%是否需要重启？
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\yesno.json
set /p reboot=<menutmp.txt
if /i "%reboot%"=="y" (
ECHO.%INFO%重启手表
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt
)
echo.%SUCCESS%超级恢复完成!
pause.exe 返回
goto :eof

:rec_0
ECHO.%INFO%准备开始...
device_check.exe qcom_edl&&ECHO.

ECHO.%INFO%获取端口并发送引导
call edlport
call QSaharaServer.bat -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\%QSaharaServer%
busybox sleep 2

call progress.bat "call P_fh_loader.bat --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=%sel__folder_path%\ --sendxml=%sel__folder_path%\rawprogram0.xml --noprompt" 130 100
if exist "%cd%\fh_error.txt" (
    echo %error%超级恢复失败!刷入失败!
    type FHtmp.txt
    pause.exe 返回
    exit /b
)
ECHO.%Yellow%是否需要重启？
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\yesno.json
set /p reboot=<menutmp.txt
if /i "%reboot%"=="y" (
ECHO.%INFO%重启手表
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt
)
echo.%SUCCESS%超级恢复完成!
pause.exe 返回
goto :eof