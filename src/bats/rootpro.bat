device_check.exe adb&&ECHO.
call boot_completed.bat
ECHO.%INFO%开始执行优化...
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.innermodel') do set innermodel=%%i
echo %INFO%您的设备innermodel为:%innermodel%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.model') do set model=%%i
echo %INFO%手表型号:%model%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.build.version.release') do set androidversion=%%i
echo %INFO%安卓版本:%androidversion%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.build.version.sdk') do set sdkversion=%%i
echo %INFO%SDK版本号:%sdkversion%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.current.softversion') do set version=%%i
echo %INFO%版本号:%version%
if not "%sdkversion%"=="27" (
echo %error%你的安卓版本不是8.1，该功能不支持你的手表
pause
exit /b
)
call isv3
adb shell pm path com.android.systemui > nul 2> nul
if %errorlevel%==0 (
    set havesystemui=1
    set /p="1" <nul > havesystemui.txt
    ECHO %GREEN%系统存在SystemUI
) else (
    set havesystemui=0
    set /p="0" <nul > havesystemui.txt
    ECHO %GREEN%系统不存在SystemUI
)
device_check.exe adb&&ECHO.
call boot_completed.bat
ECHO.%INFO%开始安装应用,共计6个
call instapp.bat .\rootproapks\LocalSend.apk
call instapp.bat .\rootproapks\Via.apk
call instapp.bat .\rootproapks\Xposed_Edge_Pro.apk
call instapp.bat .\rootproapks\MTfile.apk
call instapp.bat .\rootproapks\xtcinputpro.apk
call instapp.bat .\rootproapks\sogouwearpro.apk
ECHO.%INFO%安装完成
ECHO.%INFO%你是否需要安装禁用模式切换的桌面？
set /p i13yesorno=%YELLOW%输入y进行安装，按任意键跳过%RESET% 
if not "%i13yesorno%"=="y" goto rootpro-noi13
if "%isv3%"=="1" (
    if "%havesystemui%"=="1" (
        call instapp.bat .\rootproapks\130510_D.apk
    ) else (
        call instapp.bat .\rootproapks\121750_D.apk
    )
) else (
    call instapp.bat .\rootproapks\116100_D.apk
)
:rootpro-noi13
ECHO.%INFO%你是否要刷入原生修复？
set /p setyesorno=%YELLOW%输入y进行刷入，按任意键跳过%RESET%
if not "%setyesorno%"=="y" goto noset
ECHO.%INFO%原生修复依赖systemplus付费功能-SystemUl,DocumentsUl和原生设置适配
set /p sethookyesorno=%YELLOW%输入y刷入破解模块，输入n打开解锁界面%RESET%
if "%sethookyesorno%"=="y" call :hooksyspwcp
if "%sethookyesorno%"=="n" run_cmd "adb shell ""su -c am start -n com.huanli233.systemplus/.UnlockActivity"""
ECHO.%INFO%请确保已经打开'SystemUl,DocumentsUl和原生设置适配'功能
pause
ECHO.%INFO%再次确认已经打开该功能，如果不打开该功能会导致变砖
pause
call instmodule.bat .\magiskmod\xtcrootultra.zip
ECHO.%INFO%重启手表
run_cmd "adb reboot"
ECHO.%INFO%你是否正常启动进入了系统？
set /p rmyesorno=%YELLOW%如果变砖了输入y快速救砖，按任意键跳过%RESET%
if "%rmyesorno%"=="y" run_cmd "adb shell ""su -c rm -rf /data/adb/modules/xtc_root_ultra"""
if "%havesystemui%"=="0" (
ECHO.%INFO%你是否要刷入小天才systemui并安装130510桌面？
ECHO.%INFO%！与多任务和导航栏冲突！
set /p sysuiyesorno=%YELLOW%输入y进行刷入，按任意键跳过%RESET%
if "%sysuiyesorno%"=="y" call instmodule.bat .\magiskmod\xtcsystemui.zip & call instapp.bat .\apks\130510.apk
if "%i13yesorno%"=="y" call instapp.bat .\rootproapks\130510_D.apk
)
:noset

ECHO.%INFO%你是否要刷入录制器？
set /p Rcyesorno=%YELLOW%输入y进行刷入，按任意键跳过%RESET%
if "%Rcyesorno%"=="y" call instmodule.bat .\magiskmod\Recorder.zip

ECHO.%INFO%你是否要刷入破解SystemPlus和WeichatPro2模块？
set /p syswcpyesorno=%YELLOW%输入y进行刷入，按任意键跳过%RESET%
if "%syswcpyesorno%"=="y" call :hooksyspwcp
ECHO.%INFO%优化全部完成
ECHO.%INFO%按任意键返回上一页...
pause >nul
exit /b

:hooksyspwcp
call instmodule.bat .\magiskmod\hooksyspwcp2.zip
ECHO.%INFO%正在自动激活，请稍后
busybox.exe sleep 10
run_cmd "adb shell input keyevent 4"
device_check.exe adb&&ECHO.
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input tap 200 150
adb shell input tap 200 200
adb shell input swipe 160 60 160 300 100
adb shell input swipe 160 60 160 300 100
adb shell input tap 200 150
adb shell input tap 200 200
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input tap 200 100
adb shell input tap 200 150
goto xposed-check
:ROOT-Xposed
ECHO.%INFO%正在启动投屏！如手表端不方便操作，可在电脑端进行操作
ECHO.%INFO%提示：如果手表息屏，在投屏窗口单击右键即可
start scrcpy-noconsole.vbs
run_cmd "adb shell ""su -c am start -n com.huanli233.systemplus/.ActiveSelfActivity"""
ECHO.%INFO%请往下滑，找到自激活，然后点击激活SystemPlus与激活核心破解，然后按任意键继续
pause
:xposed-check
run_cmd "adb push systemplus.sh /sdcard/systemplus.sh"
ECHO.%INFO%开始检查SystemPlus激活状态...
for /f "delims=" %%i in ('adb wait-for-device shell sh /sdcard/systemplus.sh') do set systemplus=%%i
if "%systemplus%"=="1" (
    ECHO.%ERROR%未激活
    ECHO.%ERROR%没有激活SystemPlus！按任意键重回上一步
    pause
    goto ROOT-Xposed
)
ECHO.%INFO%已激活
ECHO.%INFO%重启手表
run_cmd "adb reboot"
exit /b