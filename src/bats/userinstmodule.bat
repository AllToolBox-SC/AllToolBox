device_check.exe adb qcom_edl&&ECHO.
CLS
ECHO.%INFO%请选择要安装的模块... & call sel file s . [zip]
device_check.exe adb&&ECHO.
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.innermodel') do set innermodel=%%i
ECHO.%INFO%您的设备innermodel为:%innermodel%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.build.version.release') do set androidversion=%%i
ECHO.%INFO%您的设备安卓版本为:%androidversion%
if "%androidversion%"=="7.1.1" (
    call instmodule2.bat %sel__file_path%
    goto yesno
)
if "%androidversion%"=="4.4.4" (
    call instmodule2.bat %sel__file_path%
    goto yesno
)

call instmodule.bat %sel__file_path%

:yesno
ECHO.
ECHO.%INFO%已尝试刷入此模块，是否重启设备以加载模块?[y/n]
set /p quq=
if "%quq%"=="y" (
adb reboot
ECHO.%INFO%操作完成...按任意键返回主页面
pause
exit /b
)
if "%quq%"=="n" (
ECHO.%INFO%操作完成...按任意键返回主页面
pause
exit /b
)
ECHO.%ERROR%请输入y或n！按任意键重新输入
pause >nul
goto yesno