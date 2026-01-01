if "%1"=="DCIM" goto DCIM




:MAIN_MENU
CLS
call logo.bat
ECHO %ORANGE%%YELLOW%
ECHO ╔══════════════════════════════════════════════════╗
ECHO ║A.返回上级菜单                                    ║
ECHO ║1.备份相册                           ║
ECHO ║2.恢复相册                           ║
ECHO ╚══════════════════════════════════════════════════╝
ECHO.%RESET%
set /p MENU=%YELLOW%请输入序号并按下回车键：%RESET%
if "%MENU%"=="A" exit /b
if "%MENU%"=="a" exit /b
if "%MENU%"=="1" goto DCIM-backup
if "%MENU%"=="2" goto DCIM-recover
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto MAIN_MENU


:DCIM
if "%2"=="recover" goto DCIM-recover
if "%2"=="backup" goto DCIM-backup

:DCIM-recover
if "%3"=="noask" goto DCIM-recover-noask
echo %INFO%你要从哪个文件夹进行恢复？%RESET%
call sel folder s %cd%\backup
echo.%info%正在恢复相册...
adb push "%sel__folder_path%" /sdcard/DCIM/
if %errorlevel%==0 (
    echo.%info%恢复成功
) else (
    echo.%error%恢复失败
)

:DCIM-recover-noask
echo.%info%正在恢复相册...
adb push "backup\%backupname%" /sdcard/DCIM/
if %errorlevel%==0 (
    echo.%info%恢复成功
) else (
    echo.%error%恢复失败
)

:DCIM-backup
if "%3"=="noask" goto DCIM-backup-noask
echo %INFO%你要将相册备份到哪个文件夹内？%RESET%
call sel folder s %cd%\backup
echo.%info%正在备份相册...
adb pull /sdcard/DCIM "%sel__folder_path%"
if %errorlevel%==0 (
    echo.%info%备份成功
) else (
    echo.%error%备份失败
)

:DCIM-backup-noask
echo.%info%正在备份相册...
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.model') do set model=%%i
set backupname=DCIM_%model%_%date%_%time%
mkdir "backup\%backupname%"
adb pull /sdcard/DCIM "backup\%backupname%"
if %errorlevel%==0 (
    echo.%info%备份成功
) else (
    echo.%error%备份失败
)