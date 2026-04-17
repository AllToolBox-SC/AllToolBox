%userdebug%
set "pause=pause.exe 返回"
if "%1"=="reboot" set "pause="&&goto rebootP-reboot
if "%1"=="fastboot" set "pause="&&goto rebootP-bl
if "%1"=="bootloader" set "pause="&&goto rebootP-bl
if "%1"=="recovery" set "pause="&&goto rebootP-re
if "%1"=="edl" set "pause="&&goto rebootP-edl
if "%1"=="qmmi" set "pause="&&call :flash_device "%1" "%2" "%3"&&exit /b
if "%1"=="ffbm" set "pause="&&call :flash_device "%1" "%2" "%3"&&exit /b
if "%1"=="wipe" set "pause="&&call :flash_device "%1" "%2" "%3"&&exit /b
:rebootP
CLS
call logo.bat
ECHO %ORANGE%高级重启%YELLOW%
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\rebootpro.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="a" exit /b
if "%MENU%"=="1" goto rebootP-reboot
if "%MENU%"=="2" goto rebootP-bl
if "%MENU%"=="3" goto rebootP-re
if "%MENU%"=="4" goto rebootP-edl
if "%MENU%"=="5" goto rebootP-twrp
if "%MENU%"=="6" set "mode=qmmi" & goto show_menu
if "%MENU%"=="7" set "mode=ffbm" & goto show_menu
if "%MENU%"=="8" set "mode=wipe" & goto show_menu
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto rebootP

::------------------------------------------------------------------------

:rebootP-reboot
ECHO %INFO%请插入adb,9008,fastboot设备%RESET%
device_check.exe adb qcom_edl fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="qcom_edl" goto rebootP-reboot-edl
if "%devicestatus%"=="adb" adb reboot
if "%devicestatus%"=="fastboot" fastboot reboot
ECHO %INFO%完成！%RESET%
%pause%
goto rebootP

:rebootP-reboot-edl
CLS
call logo.bat
ECHO %ORANGE%选择该如何引导?%YELLOW%
menu.exe .\menu\rebootpro_edl.json
set /p mbnMENU=<menutmp.txt
if "%mbnMENU%"=="A" goto rebootP
if "%mbnMENU%"=="1" set "whatmbn=msm8937.mbn" & goto rebootP-reboot-edl-run
if "%mbnMENU%"=="2" set "whatmbn=msm8909w.mbn" & goto rebootP-reboot-edl-run
if "%mbnMENU%"=="3" set "whatmbn=prog_firehose_ddr.elf" & goto rebootP-reboot-edl-run
if "%mbnMENU%"=="4" goto rebootP-reboot-edl-noQS
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto rebootP-reboot-edl
:rebootP-reboot-edl-run
call edlport
QSaharaServer.bat -p \\.\COM%chkdev__edl__port% -s 13:%cd%\EDL\%whatmbn%
:rebootP-reboot-edl-noQS
call edlport
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt
ECHO %INFO%完成!%RESET%
%pause%
goto rebootP

::------------------------------------------------------------------------

:rebootP-bl
ECHO %INFO%%YELLOW%请插入adb,fastboot设备%RESET%
device_check.exe adb fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="adb" adb reboot bootloader
if "%devicestatus%"=="fastboot" fastboot reboot bootloader
ECHO %INFO%%YELLOW%完成！%RESET%
%pause%
goto rebootP

::------------------------------------------------------------------------

:rebootP-re
ECHO %INFO%%YELLOW%请插入adb,fastboot设备%RESET%
device_check.exe adb fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="adb" adb reboot recovery
if "%devicestatus%"=="fastboot" goto rebootP-re-bl
ECHO %INFO%%YELLOW%完成！%RESET%
%pause%
goto rebootP

:rebootP-re-bl
CLS
if not exist .\EDL\twrp call cloud twrp
call logo
echo %ORANGE%请选择型号%YELLOW%
menu.exe .\menu\pashtwrp.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="1" set "innermodel=I12"
if "%MENU%"=="2" set "innermodel=IB"
if "%MENU%"=="3" set "innermodel=I13C"
if "%MENU%"=="4" set "innermodel=I13"
if "%MENU%"=="5" set "innermodel=I19"
if "%MENU%"=="6" set "innermodel=I18"
if "%MENU%"=="7" set "innermodel=I20"
if "%MENU%"=="8" set "innermodel=I25"
if "%MENU%"=="9" set "innermodel=I25C"
if "%MENU%"=="10" set "innermodel=I25D"
if "%MENU%"=="11" set "innermodel=I32"
if "%MENU%"=="12" set "innermodel=ND07"
if "%MENU%"=="13" set "innermodel=ND01"
::if "%MENU%"=="14" set "innermodel=ND03"
::if "%MENU%"=="15" set "innermodel=ND08"

device_check.exe fastboot&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\twrp\%innermodel%.img .\EDL\rooting\recovery.img
ECHO %INFO%进入twrp%RESET%
fastboot boot EDL\rooting\recovery.img
ECHO %INFO%执行命令%RESET%
call adbdevice.bat adb
adb reboot recovery
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%完成!%RESET%
%pause%
goto rebootP


::------------------------------------------------------------------------

:rebootP-edl
ECHO %INFO%%YELLOW%请插入adb,fastboot设备%RESET%
device_check.exe adb fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="adb" adb reboot edl
if "%devicestatus%"=="fastboot" goto rebootP-edl-bl
ECHO %INFO%%YELLOW%完成！%RESET%
%pause%
goto rebootP

:rebootP-edl-bl
CLS
if not exist .\EDL\twrp call cloud twrp
call logo
echo %ORANGE%请选择型号%YELLOW%
menu.exe .\menu\pashtwrp.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="1" set "innermodel=I12"
if "%MENU%"=="2" set "innermodel=IB"
if "%MENU%"=="3" set "innermodel=I13C"
if "%MENU%"=="4" set "innermodel=I13"
if "%MENU%"=="5" set "innermodel=I19"
if "%MENU%"=="6" set "innermodel=I18"
if "%MENU%"=="7" set "innermodel=I20"
if "%MENU%"=="8" set "innermodel=I25"
if "%MENU%"=="9" set "innermodel=I25C"
if "%MENU%"=="10" set "innermodel=I25D"
if "%MENU%"=="11" set "innermodel=I32"
if "%MENU%"=="12" set "innermodel=ND07"
if "%MENU%"=="13" set "innermodel=ND01"
::if "%MENU%"=="14" set "innermodel=ND03"
::if "%MENU%"=="15" set "innermodel=ND08"

device_check.exe fastboot&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\twrp\%innermodel%.img .\EDL\rooting\recovery.img
ECHO %INFO%进入twrp%RESET%
fastboot boot EDL\rooting\recovery.img
ECHO %INFO%执行命令%RESET%
call adbdevice.bat adb
adb reboot edl
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%完成!%RESET%
%pause%
goto rebootP

::------------------------------------------------------------------------

:rebootP-twrp
ECHO %INFO%%YELLOW%请插入adb,fastboot设备%RESET%
device_check.exe adb fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="adb" adb reboot bootloader & goto rebootP-twrp-bl
if "%devicestatus%"=="fastboot" goto rebootP-twrp-bl
ECHO %INFO%%YELLOW%完成！%RESET%
%pause%
goto rebootP

:rebootP-twrp-bl
CLS
if not exist .\EDL\twrp call cloud twrp
call logo
echo %ORANGE%请选择型号%YELLOW%
menu.exe .\menu\pashtwrp.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="1" set "innermodel=I12"
if "%MENU%"=="2" set "innermodel=IB"
if "%MENU%"=="3" set "innermodel=I13C"
if "%MENU%"=="4" set "innermodel=I13"
if "%MENU%"=="5" set "innermodel=I19"
if "%MENU%"=="6" set "innermodel=I18"
if "%MENU%"=="7" set "innermodel=I20"
if "%MENU%"=="8" set "innermodel=I25"
if "%MENU%"=="9" set "innermodel=I25C"
if "%MENU%"=="10" set "innermodel=I25D"
if "%MENU%"=="11" set "innermodel=I32"
if "%MENU%"=="12" set "innermodel=ND07"
if "%MENU%"=="13" set "innermodel=ND01"
::if "%MENU%"=="14" set "innermodel=ND03"
::if "%MENU%"=="15" set "innermodel=ND08"

device_check.exe fastboot&&ECHO.
ECHO %INFO%拷贝文件到临时目录%RESET%
copy /Y .\EDL\twrp\%innermodel%.img .\EDL\rooting\recovery.img
ECHO %INFO%进入twrp%RESET%
fastboot boot EDL\rooting\recovery.img
ECHO %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*"
ECHO %INFO%完成!%RESET%
%pause%
goto rebootP

:show_menu
cls
call logo
echo %ORANGE%请选择型号[全部自带文件]%YELLOW%
menu.exe .\menu\qmmi.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" goto rebootP
if "%MENU%"=="1"  set "innermodel=I12" & set "platform=otherpash"
if "%MENU%"=="2"  set "innermodel=IB" & set "platform=otherpash"
if "%MENU%"=="3"  set "innermodel=I13C" & set "platform=otherpash"
if "%MENU%"=="4"  set "innermodel=I13" & set "platform=otherpash"
if "%MENU%"=="5"  set "innermodel=I19" & set "platform=otherpash"
if "%MENU%"=="6"  set "innermodel=I18" & set "platform=otherpash"
if "%MENU%"=="7"  set "innermodel=I20" & set "platform=v3pash"
if "%MENU%"=="8"  set "innermodel=I25" & set "platform=v3pash"
if "%MENU%"=="9"  set "innermodel=I25C" & set "platform=v3pash"
if "%MENU%"=="10" set "innermodel=I25D" & set "platform=v3pash"
if "%MENU%"=="11" set "innermodel=I32" & set "platform=v3pash"
if "%MENU%"=="12" set "innermodel=ND07" & set "platform=v3pash"
if "%MENU%"=="13" set "innermodel=ND01" & set "platform=v3pash"
if "%MENU%"=="14" set "innermodel=ND03" & set "platform=z10"

call :flash_device "%mode%" "%platform%" "%innermodel%"
goto rebootP


:: =======================================
:flash_device
:: 参数：%1 = 模式 (qmmi / ffbm / wipe) , %2 = 平台 (z10 / otherpash / v3pash) , %3 = 型号 (innermodel)
set "mode=%~1"
set "platform=%~2"
set "innermodel=%~3"


if "%platform%"=="z10" (
    set "loader=prog_firehose_ddr.elf"
    set "misc_xml=misc_%innermodel%.xml"
    set "misc_img=misc.img"
    set "img_ext=img"
) else if "%platform%"=="otherpash" (
    set "loader=msm8909w.mbn"
    set "misc_xml=misc_%innermodel%.xml"
    set "misc_img=misc.mbn"
    set "img_ext=mbn"
) else if "%platform%"=="v3pash" (
    set "loader=msm8937.mbn"
    set "misc_xml=misc_%innermodel%.xml"
    set "misc_img=misc.img"
    set "img_ext=img"
) else (
    echo 未知平台: %platform%
    exit /b 1
)

:: 根据模式选择镜像文件 (misc / ffbm / wipe)
if "%mode%"=="ffbm" (
    set "image_src=ffbm.img"
) else if "%mode%"=="wipe" (
    set "image_src=wipe.img"
) else (
    set "image_src=misc.img"
)

echo %INFO%请接入需要刷写的设备%RESET%
device_check.exe qcom_edl adb&& echo.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="adb" adb reboot edl

echo %INFO%拷贝文件到临时目录%RESET%
copy /Y ".\EDL\misc\%misc_xml%" ".\EDL\rooting\misc.xml" >nul
copy /Y ".\EDL\misc\%image_src%" ".\EDL\rooting\misc.%img_ext%" >nul

echo %INFO%获取9008端口并执行引导%RESET%
call edlport
call QSaharaServer.bat -p \\.\COM%chkdev__edl__port% -s 13:"%cd%\EDL\%loader%"

echo %INFO%开始刷入misc%RESET%
call edlport >nul
call fh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt

echo %INFO%执行重启%RESET%
call qfh_loader.bat --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt


echo %INFO%清理临时数据%RESET%
del /Q /F ".\EDL\rooting\*.*" >nul

if "%mode%"=="ffbm" (
    echo %INFO%已进入ffbm%RESET%
    %pause%
) else if "%mode%"=="wipe" (
    echo %INFO%已执行，恢复出厂设置%RESET%
    %pause%
) else (
    echo %INFO%已进入QMMI%RESET%
    %pause%
)
exit /b