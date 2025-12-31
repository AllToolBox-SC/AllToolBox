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
if "%havesystemui%"=="1" goto sysui
ECHO.%INFO%你的系统没有systemUI，固然不支持130510版本桌面，是否强制安装高版本桌面，并刷入兼容模块？
set /p sysuiyesno=%YELLOW%输入y进行操作，按任意键跳过%RESET%
if not "%i13yesorno%"=="y" goto sysui
ECHO.%INFO%开始安装130510桌面
call instapp.bat .\rootproapks\130510.apk
ECHO.%INFO%完成
ECHO.%INFO%开始刷入systemui
call instmodule.bat .\magiskmod\xtcsystemui.zip
ECHO.%INFO%完成
set havesystemui=1
:sysui
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
ECHO.%INFO%你是否需要刷入超级优化模块[原生修复]？
ECHO.%WARN%！！！有一定变砖风险！！！
ECHO.%INFO%z8测试可用
ECHO.%WARN%！！！z7测试变砖！！！
set /p ultrayesorno=%YELLOW%输入y进行刷入，按任意键跳过%RESET%
if not "%ultrayesorno%"=="y" goto rootpro-noultra
device_check.exe adb&&ECHO.
call boot_completed.bat
echo %INFO%开始刷入超级优化模块%RESET%
call instmodule.bat .\magiskmod\xtcrootultra.zip
echo %INFO%完成！%RESET%
goto rootpro-systemplus
:rootpro-noultra
device_check.exe adb&&ECHO.
call boot_completed.bat
echo %INFO%开始刷入阉割版[无原生设置]优化模块[无风险]%RESET%
call instmodule.bat .\magiskmod\xtcrootpro.zip
echo %INFO%完成！%RESET%
:rootpro-systemplus
device_check.exe adb&&ECHO.
call boot_completed.bat
ECHO.%INFO%开始重新激活systemplus
ECHO.%INFO%正在自动激活，请稍后
busybox.exe sleep 10
run_cmd "adb shell input keyevent 4"
run_cmd "adb shell am start -n com.huanli233.systemplus/.ActiveSelfActivity"
device_check.exe adb&&ECHO.
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input tap 200 200
adb shell input swipe 160 60 160 300 100
adb shell input swipe 160 60 160 300 100
adb shell input tap 200 200
adb shell input swipe 160 300 160 60 100
adb shell input swipe 160 300 160 60 100
adb shell input tap 200 120
goto xposed-check
:ROOT-Xposed
ECHO.%INFO%正在启动投屏！如手表端不方便操作，可在电脑端进行操作
ECHO.%INFO%提示：如果手表息屏，在投屏窗口单击右键即可
start scrcpy-noconsole.vbs
run_cmd "adb shell am start -n com.huanli233.systemplus/.ActiveSelfActivity"
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
run_cmd "adb push toolkit.sh /sdcard/toolkit.sh"
ECHO.%INFO%开始检查核心破解激活状态...
for /f "delims=" %%i in ('adb wait-for-device shell sh /sdcard/toolkit.sh') do set toolkit=%%i
if "%toolkit%"=="1" (
ECHO.%ERROR%未激活
ECHO.%ERROR%没有激活核心破解！按任意键重回上一步
pause
goto ROOT-Xposed
)
ECHO.%INFO%已激活
echo %INFO%完成!%RESET%

if "%havesystemui%"=="0" （
device_check.exe adb&&ECHO.
call boot_completed.bat
echo %INFO%刷入录制器模块%RESET%
call instmodule.bat .\magiskmod\Recorder.zip
echo %INFO%完成%RESET%
)

echo %INFO%已优化完成%RESET%
ECHO.%INFO%按任意键返回...
pause
exit /b