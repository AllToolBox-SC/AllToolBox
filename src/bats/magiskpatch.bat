::call magiskpatch

:MAGISKPATCH
SETLOCAL
copy /Y .\busybox.exe .\magiskpatch\busybox.exe
set bootpath=%cd%\tmp\boot.img
set outputpath=%cd%\boot.img
::检查是否存在
if not exist %bootpath% goto FATAL
if not exist %zippath% goto FATAL
::设置修补选项
::- 保留AVB2.0, dm-verity (27006-17000) 建议默认true
set KEEPVERITY=true
::- 保留强制加密 (27006-17000) 建议默认true
set KEEPFORCEENCRYPT=true
::- 修补vbmeta标志 (27006-24000) 默认false
set PATCHVBMETAFLAG=false
::- 安装到Recovery (27006-19100) 默认false (注: 在23000及更低的版本, 当boot解压出现recovery_dtbo文件时, 此项将被强制设为true)
set RECOVERYMODE=false
::- 处理器架构 (arm和x86系列中, 27006-19000支持64位, 18100-17000不区分或不支持64位. 27006-27005支持riscv_64) 建议默认arm64
::  arm_64   arm_32   x86_64   x86_32   riscv_64
set arch=arm_32

:MAGISKPATCH-21200
::检查Magisk组件
if not exist %cd%\magiskpatch\magiskinit goto FATAL
::解包boot
cd magiskpatch 1>nul 2>nul
magiskboot.exe unpack -h %bootpath% 1>nul 2>&1
cd .. 1>nul 2>nul
::检查recovery_dtbo
if exist %cd%\magiskpatch\recovery_dtbo set RECOVERYMODE=true
::测试ramdisk
if not exist %cd%\magiskpatch\ramdisk.cpio (
    set STATUS=0& goto MAGISKPATCH-21200-MODE0)

cd magiskpatch 1>nul 2>nul
magiskboot.exe cpio %cd%\magiskpatch\ramdisk.cpio test 1>nul 2>&1
cd .. 1>nul 2>nul

set STATUS=%errorlevel%
if "%STATUS%"=="0" goto MAGISKPATCH-21200-MODE0
if "%STATUS%"=="1" goto MAGISKPATCH-21200-MODE1
pause>nul & goto MAGISKPATCH-21200
::模式0-Stock boot image detected
:MAGISKPATCH-21200-MODE0
set SHA1=
for /f %%a in ('magiskboot sha1 %bootpath% 2^>^>nul') do set SHA1=%%a
if exist %cd%\magiskpatch\ramdisk.cpio (
    copy /Y %cd%\magiskpatch\ramdisk.cpio %cd%\magiskpatch\ramdisk.cpio.orig 1>nul 2>&1)
goto MAGISKPATCH-21200-2
::模式1-Magisk patched boot image detected
:MAGISKPATCH-21200-MODE1
set SHA1=
for /f %%a in ('magiskboot cpio ramdisk.cpio sha1 2^>^>nul') do set SHA1=%%a
cd magiskpatch 1>nul 2>nul
magiskboot.exe cpio ramdisk.cpio restore 1>nul 2>&1
cd .. 1>nul 2>nul
copy /Y %cd%\magiskpatch\ramdisk.cpio %cd%\magiskpatch\ramdisk.cpio.orig 1>nul 2>&1
goto MAGISKPATCH-21200-2
:MAGISKPATCH-21200-2
::修补ramdisk.cpio
cd magiskpatch 1>nul 2>nul
echo.KEEPVERITY=%KEEPVERITY%>config& echo.KEEPFORCEENCRYPT=%KEEPFORCEENCRYPT%>>config& echo.RECOVERYMODE=%RECOVERYMODE%>>config
if not "%SHA1%"=="" echo.SHA1=%SHA1%|find "SHA1" 1>>config
busybox.exe sed -i "s/\r//g;s/^M//g" config
type config>nul
magiskboot.exe cpio ramdisk.cpio "add 750 init magiskinit" "patch" "backup ramdisk.cpio.orig" "mkdir 000 .backup" "add 000 .backup/.magisk config" 1>nul 2>&1
cd .. 1>nul 2>nul
:MAGISKPATCH-21200-3
::尝试修补dtb
set dtbname=
if exist %cd%\magiskpatch\dtb set dtbname=dtb
if exist %cd%\magiskpatch\kernel_dtb set dtbname=kernel_dtb
if exist %cd%\magiskpatch\extra set dtbname=extra
if exist %cd%\magiskpatch\recovery_dtbo set dtbname=recovery_dtbo
if "%dtbname%"=="" (
    goto MAGISKPATCH-21200-4)
cd magiskpatch 1>nul 2>nul
magiskboot.exe dtb %dtbname% patch 1>nul 2>&1
cd .. 1>nul 2>nul
:MAGISKPATCH-21200-4
::尝试修补kernel
cd magiskpatch 1>nul 2>nul
if "%vivo_suu_patch%"=="y" (
    magiskboot.exe hexpatch kernel 0092CFC2C9CDDDDA00 0092CFC2C9CEC0DB00 1>nul 2>&1)
magiskboot.exe hexpatch kernel 49010054011440B93FA00F71E9000054010840B93FA00F7189000054001840B91FA00F7188010054 A1020054011440B93FA00F7140020054010840B93FA00F71E0010054001840B91FA00F7181010054 1>nul 2>&1
magiskboot.exe hexpatch kernel 821B8012 E2FF8F12 1>nul 2>&1
magiskboot.exe hexpatch kernel 77616E745F696E697472616D667300 736B69705F696E697472616D667300 1>nul 2>&1
cd .. 1>nul 2>nul


::打包boot
cd magiskpatch 1>nul 2>nul
magiskboot.exe repack %bootpath% boot_new.img 1>nul 2>&1
cd .. 1>nul 2>nul
::和原boot比较大小
set origbootsize=
for /f "tokens=2 delims= " %%a in ('busybox.exe stat -t %bootpath%') do set origbootsize=%%a
if "%origbootsize%"=="" goto FATAL
set patchedbootsize=
for /f "tokens=2 delims= " %%a in ('busybox.exe stat -t %cd%\magiskpatch\boot_new.img') do set patchedbootsize=%%a
if "%patchedbootsize%"=="" goto FATAL
::移动成品到指定目录
move /Y %cd%\magiskpatch\boot_new.img %outputpath% 1>nul 2>&1
del /Q /F .\magiskpatch\busybox.exe
ENDLOCAL
goto :eof

:FATAL
set errorlevel=1
