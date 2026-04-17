%userdebug%
setlocal enabledelayedexpansion


:run

call boot_completed.bat

set /a ELAPSED=0
set PREV_BOOT=1

:monitor_loop
set BOOT=0
for /f "tokens=*" %%i in ('adb shell getprop sys.boot_completed 2^>nul') do set BOOT=%%i
if "!BOOT!"=="" set BOOT=0


if "!BOOT!"=="0" (
    if "!PREV_BOOT!"=="1" (
        goto wait_boot
    )
)


set PREV_BOOT=!BOOT!

busybox sleep 2
set /a ELAPSED+=2
if !ELAPSED! geq 50 (
    exit /b
)
goto monitor_loop

:wait_boot
call adbdevice.bat adb
for /f "tokens=*" %%j in ('adb shell getprop sys.boot_completed 2^>nul') do set BOOT2=%%j
if "!BOOT2!"=="1" (
    goto run
)
busybox sleep 2
goto wait_boot