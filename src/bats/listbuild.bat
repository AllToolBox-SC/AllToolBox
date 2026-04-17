ECHO %YELLOW%请插入adb设备%RESET%

device_check.exe adb&&ECHO.

ECHO %INFO%正在读取...%RESET%
ECHO %YELLOW%
ECHO.═════════════════════════════════════════════════════════════
for /f "tokens=1,2 delims==" %%A in ('more +0 ".\build.txt"') do (
    for /f "delims=" %%V in ('adb shell getprop "%%A"') do (
        if not "%%V"=="" echo  %%B %%V
    )
)

ECHO.═════════════════════════════════════════════════════════════
echo.%RESET%
ECHO %INFO%读取全部完成!%RESET%

pause.exe 返回