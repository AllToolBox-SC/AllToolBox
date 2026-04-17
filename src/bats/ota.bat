CLS
ECHO %INFO%本模式需要未ROOT且已进入QMMI%RESET%
ECHO %INFO%下载OTA包请访问https://www.123865.com/s/Q5JfTd-HEbWH%RESET%
pause.exe
ECHO %INFO%请选择OTA包...%RESET%& call sel file s .. [zip]
device_check.exe adb&&ECHO.
for /f "delims=" %%i in ('adb shell getprop ro.product.innermodel') do set innermodel=%%i
echo %INFO%您的设备innermodel为:%innermodel%
for /f "delims=" %%i in ('adb shell getprop ro.product.model') do set model=%%i
echo %INFO%手表型号:%model%
for /f "delims=" %%i in ('adb shell getprop ro.product.current.softversion') do set version=%%i
echo %INFO%版本号:%version%
call isv3
if "%isv3%"=="1" (
echo %ERROR%你的手表可能是V3版本
echo %ERROR%无需离线OTA，也无法离线OTA
pause.exe
exit /b
)
:root
adb root | find "restarting" 1>nul 2>nul || ECHO %ERROR%当前不是QMMI状态下！%RESET%&& pause.exe&& goto root
adb shell "rm -rf /data/ota*"
adb push %sel__file_path% /sdcard/xtc/ota_f_vota.zip
adb shell am start -n com.xtc.setting/.module.secretcode.view.activity.OfflineOtaActivity
start scrcpy-noconsole.vbs
echo %INFO%请在手表上点击离线OTA-开始升级即可%RESET%
pause.exe 返回
exit /b