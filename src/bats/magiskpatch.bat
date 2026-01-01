::call magiskpatch     boot文件完整路径 新boot文件路径   面具apk路径                                   noprompt(可选)

set args1=%1& set args2=%1& set args3=%2& set args4=%3& set args5=%4& set args6=%5& set args7=%6& set args8=%7& set args9=%8

:MAGISKPATCH
SETLOCAL
set framework_workspace=%cd%
set tmpdir=%cd%
set bootpath=%args2%& set outputpath=%args3%& set zippath=%args4%& set mode=%args5%
::检查是否存在
if "%zippath%"=="" goto FATAL
if not exist %bootpath% goto FATAL
if not exist %zippath% goto FATAL
::清理临时文件目录
if exist %tmpdir%\imgkit-magiskpatch rd /s /q %tmpdir%\imgkit-magiskpatch 1>nul 2>nul
md %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
::设置修补选项
::- 保留AVB2.0, dm-verity (27006-17000) 建议默认true
if "%imgkit__magiskpatch__option_KEEPVERITY%"=="false" (set KEEPVERITY=false) else (set KEEPVERITY=true)
::- 保留强制加密 (27006-17000) 建议默认true
if "%imgkit__magiskpatch__option_KEEPFORCEENCRYPT%"=="false" (set KEEPFORCEENCRYPT=false) else (set KEEPFORCEENCRYPT=true)
::- 修补vbmeta标志 (27006-24000) 默认false
if "%imgkit__magiskpatch__option_PATCHVBMETAFLAG%"=="true" (set PATCHVBMETAFLAG=true) else (set PATCHVBMETAFLAG=false)
::- 安装到Recovery (27006-19100) 默认false (注: 在23000及更低的版本, 当boot解压出现recovery_dtbo文件时, 此项将被强制设为true)
if "%imgkit__magiskpatch__option_RECOVERYMODE%"=="true" (set RECOVERYMODE=true) else (set RECOVERYMODE=false)
::- 强开rootfs (27006-26000) 建议默认true
if "%imgkit__magiskpatch__option_LEGACYSAR%"=="false" (set LEGACYSAR=false) else (set LEGACYSAR=true)
set SYSTEM_ROOT=%LEGACYSAR%
::- 处理器架构 (arm和x86系列中, 27006-19000支持64位, 18100-17000不区分或不支持64位. 27006-27005支持riscv_64) 建议默认arm64
::  arm_64   arm_32   x86_64   x86_32   riscv_64
set arch=arm_32
if "%imgkit__magiskpatch__option_arch%"=="arm_64" set arch=arm_64
if "%imgkit__magiskpatch__option_arch%"=="arm_32" set arch=arm_32
if "%imgkit__magiskpatch__option_arch%"=="x86_64" set arch=x86_64
if "%imgkit__magiskpatch__option_arch%"=="x86_32" set arch=x86_32
if "%imgkit__magiskpatch__option_arch%"=="riscv_64" set arch=riscv_64
if "%arch%"=="" set arch=arm_64
::记录最终选项
:MAGISKPATCH-1
::准备Magisk组件
if "%arch%"=="arm_64" (
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\armeabi-v7a\libmagiskinit.so                                  -ir!lib\armeabi-v7a\libmagisk32.so -ir!lib\armeabi-v7a\libmagisk64.so -ir!arm\magiskinit                                     %zippath% 1>>nul 2>&1
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\arm64-v8a\libmagiskinit.so   -ir!lib\arm64-v8a\libmagisk.so                                      -ir!lib\arm64-v8a\libmagisk64.so   -ir!arm\magiskinit64 -ir!lib\arm64-v8a\libinit-ld.so   %zippath% 1>>nul 2>&1)
if "%arch%"=="arm_32" (
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\armeabi-v7a\libmagiskinit.so -ir!lib\armeabi-v7a\libmagisk.so -ir!lib\armeabi-v7a\libmagisk32.so                                    -ir!arm\magiskinit   -ir!lib\armeabi-v7a\libinit-ld.so %zippath% 1>>nul 2>&1)
if "%arch%"=="x86_64" (
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\x86\libmagiskinit.so                                          -ir!lib\x86\libmagisk32.so         -ir!lib\x86\libmagisk64.so         -ir!x86\magiskinit                                     %zippath% 1>>nul 2>&1
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\x86_64\libmagiskinit.so      -ir!lib\x86_64\libmagisk.so                                         -ir!lib\x86_64\libmagisk64.so      -ir!x86\magiskinit64 -ir!lib\x86_64\libinit-ld.so      %zippath% 1>>nul 2>&1)
if "%arch%"=="x86_32" (
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\x86\libmagiskinit.so         -ir!lib\x86\libmagisk.so         -ir!lib\x86\libmagisk32.so                                            -ir!x86\magiskinit   -ir!lib\x86\libinit-ld.so         %zippath% 1>>nul 2>&1)
if "%arch%"=="riscv_64" (
    7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!lib\riscv64\libmagiskinit.so     -ir!lib\riscv64\libmagisk.so                                                                                                -ir!lib\riscv64\libinit-ld.so     %zippath% 1>>nul 2>&1)
7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!assets\stub.apk %zippath% 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\magiskinit64 move /Y %tmpdir%\imgkit-magiskpatch\magiskinit64 %tmpdir%\imgkit-magiskpatch\magiskinit 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\libmagiskinit.so move /Y %tmpdir%\imgkit-magiskpatch\libmagiskinit.so %tmpdir%\imgkit-magiskpatch\magiskinit 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\libmagisk.so     magiskboot.exe compress=xz %tmpdir%\imgkit-magiskpatch\libmagisk.so %tmpdir%\imgkit-magiskpatch\magisk.xz 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\libmagisk32.so   magiskboot.exe compress=xz %tmpdir%\imgkit-magiskpatch\libmagisk32.so %tmpdir%\imgkit-magiskpatch\magisk32.xz 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\libmagisk64.so   magiskboot.exe compress=xz %tmpdir%\imgkit-magiskpatch\libmagisk64.so %tmpdir%\imgkit-magiskpatch\magisk64.xz 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\stub.apk         magiskboot.exe compress=xz %tmpdir%\imgkit-magiskpatch\stub.apk %tmpdir%\imgkit-magiskpatch\stub.xz 1>>nul 2>&1
if exist %tmpdir%\imgkit-magiskpatch\libinit-ld.so    magiskboot.exe compress=xz %tmpdir%\imgkit-magiskpatch\libinit-ld.so %tmpdir%\imgkit-magiskpatch\init-ld.xz 1>>nul 2>&1
::读取Magisk版本和修补脚本md5

7z.exe e -aoa -o%tmpdir%\imgkit-magiskpatch -slp -y -ir!assets\util_functions.sh -ir!common\util_functions.sh -ir!assets\boot_patch.sh -ir!common\boot_patch.sh %zippath% 1>>nul 2>&1

set magiskver=
for /f "tokens=2 delims== " %%a in ('type %tmpdir%\imgkit-magiskpatch\util_functions.sh ^| find "MAGISK_VER_CODE="') do set magiskver=%%a
for /f "tokens=2 delims== " %%a in ('type %tmpdir%\imgkit-magiskpatch\util_functions.sh ^| find "MAGISK_VER="') do set var=%%a
set magiskver_show=%var:~1,-1%
set bootpatchmd5=
for /f "tokens=1 delims= " %%a in ('busybox.exe md5sum %tmpdir%\imgkit-magiskpatch\boot_patch.sh 2^>^>nul') do set bootpatchmd5=%%a
if "%bootpatchmd5%"=="" goto FATAL
::确定修补方案
set vivo_suu_patch=n
set bootpatchplan=
if "%bootpatchmd5%"=="bf6ef4d02c48875ae3929d26899a868d" set bootpatchplan=25200
if "%bootpatchmd5%"=="c48a22c8ed43cd20fe406acccc600308" set bootpatchplan=25200
if "%bootpatchmd5%"=="b8256416216461c247c2b82d60e8dca0" set bootpatchplan=21200
if "%bootpatchmd5%"=="ac3d1448b7481d7e70d2558d4c733fee" set bootpatchplan=21200
if "%bootpatchmd5%"=="69ebab4d9513484988a48a38560c6032" set bootpatchplan=21200
if "%bootpatchmd5%"=="232aaecb0fae34baa5a13211fccde93c" set bootpatchplan=21200
if "%bootpatchmd5%"=="cafa4ed2bfe5e45c85864a9ccf52502f" set bootpatchplan=21200
if "%bootpatchmd5%"=="b4a4a2be5fa2a38db5149f3c752a1104" set bootpatchplan=25200& set vivo_suu_patch=y
if "%bootpatchplan%"=="" goto FATAL
goto MAGISKPATCH-%bootpatchplan%

:MAGISKPATCH-25200
::检查Magisk组件
if not exist %tmpdir%\imgkit-magiskpatch\magiskinit goto FATAL
if not exist %tmpdir%\imgkit-magiskpatch\magisk32.xz goto FATAL
if "%arch:~-2,2%"=="64" (if not exist %tmpdir%\imgkit-magiskpatch\magisk64.xz goto FATAL)
::解包boot
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
magiskboot.exe unpack -h %bootpath% 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
::测试ramdisk
if not exist %tmpdir%\imgkit-magiskpatch\ramdisk.cpio (
    set STATUS=0& goto MAGISKPATCH-25200-MODE0)
magiskboot.exe cpio %tmpdir%\imgkit-magiskpatch\ramdisk.cpio test 1>>nul 2>&1
set STATUS=%errorlevel%
if "%STATUS%"=="0" goto MAGISKPATCH-25200-MODE0
if "%STATUS%"=="1" goto MAGISKPATCH-25200-MODE1
pause>nul & goto MAGISKPATCH-25200
::模式0-Stock boot image detected
:MAGISKPATCH-25200-MODE0
set SHA1=
for /f %%a in ('magiskboot sha1 %bootpath% 2^>^>nul') do set SHA1=%%a
if exist %tmpdir%\imgkit-magiskpatch\ramdisk.cpio (
    copy /Y %tmpdir%\imgkit-magiskpatch\ramdisk.cpio %tmpdir%\imgkit-magiskpatch\ramdisk.cpio.orig 1>>nul 2>&1)
goto MAGISKPATCH-25200-2
::模式1-Magisk patched boot image detected
:MAGISKPATCH-25200-MODE1
set SHA1=
for /f %%a in ('magiskboot cpio ramdisk.cpio sha1 2^>^>nul') do set SHA1=%%a
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
magiskboot.exe cpio ramdisk.cpio restore 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
copy /Y %tmpdir%\imgkit-magiskpatch\ramdisk.cpio %tmpdir%\imgkit-magiskpatch\ramdisk.cpio.orig 1>>nul 2>&1
goto MAGISKPATCH-25200-2
:MAGISKPATCH-25200-2
::修补ramdisk.cpio
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
echo.KEEPVERITY=%KEEPVERITY%>config& echo.KEEPFORCEENCRYPT=%KEEPFORCEENCRYPT%>>config& echo.PATCHVBMETAFLAG=%PATCHVBMETAFLAG%>>config& echo.RECOVERYMODE=%RECOVERYMODE%>>config
if not "%SHA1%"=="" echo.SHA1=%SHA1%|find "SHA1" 1>>config
busybox.exe sed -i "s/\r//g;s/^M//g" config
type config>>nul
if "%arch:~-2,2%"=="64" (set var=) else (set var=#)
magiskboot.exe cpio ramdisk.cpio "add 0750 init magiskinit" "mkdir 0750 overlay.d" "mkdir 0750 overlay.d/sbin" "add 0644 overlay.d/sbin/magisk32.xz magisk32.xz" "%var% add 0644 overlay.d/sbin/magisk64.xz magisk64.xz" "patch" "backup ramdisk.cpio.orig" "mkdir 000 .backup" "add 000 .backup/.magisk config" 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
:MAGISKPATCH-25200-3
::测试和修补dtb
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
set dtbname=
set result=y
if exist dtb set dtbname=dtb& call :magiskpatch-25200-dtb
if "%result%"=="n" cd %framework_workspace% && goto MAGISKPATCH-25200-3
if exist kernel_dtb set dtbname=kernel_dtb& call :magiskpatch-25200-dtb
if "%result%"=="n" cd %framework_workspace% && goto MAGISKPATCH-25200-3
if exist extra set dtbname=extra& call :magiskpatch-25200-dtb
if "%result%"=="n" cd %framework_workspace% && goto MAGISKPATCH-25200-3
cd %framework_workspace% 1>nul 2>>nul
goto MAGISKPATCH-25200-4
:magiskpatch-25200-dtb
magiskboot.exe dtb %dtbname% test 1>>nul 2>&1
magiskboot.exe dtb %dtbname% patch 1>>nul 2>&1
goto :eof
:MAGISKPATCH-25200-4
::尝试修补kernel
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
if "%vivo_suu_patch%"=="y" (
    magiskboot.exe hexpatch kernel 0092CFC2C9CDDDDA00 0092CFC2C9CEC0DB00 1>>nul 2>&1)
magiskboot.exe hexpatch kernel 49010054011440B93FA00F71E9000054010840B93FA00F7189000054001840B91FA00F7188010054 A1020054011440B93FA00F7140020054010840B93FA00F71E0010054001840B91FA00F7181010054 1>>nul 2>&1
magiskboot.exe hexpatch kernel 821B8012 E2FF8F12 1>>nul 2>&1
magiskboot.exe hexpatch kernel 77616E745F696E697472616D667300 736B69705F696E697472616D667300 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
goto MAGISKPATCH-DONE

:MAGISKPATCH-21200
::检查Magisk组件
if not exist %tmpdir%\imgkit-magiskpatch\magiskinit goto FATAL
::解包boot
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
magiskboot.exe unpack -h %bootpath% 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
::检查recovery_dtbo
if exist %tmpdir%\imgkit-magiskpatch\recovery_dtbo set RECOVERYMODE=true
::测试ramdisk
if not exist %tmpdir%\imgkit-magiskpatch\ramdisk.cpio (
    set STATUS=0& goto MAGISKPATCH-21200-MODE0)
magiskboot.exe cpio %tmpdir%\imgkit-magiskpatch\ramdisk.cpio test 1>>nul 2>&1
set STATUS=%errorlevel%
if "%STATUS%"=="0" goto MAGISKPATCH-21200-MODE0
if "%STATUS%"=="1" goto MAGISKPATCH-21200-MODE1
pause>nul & goto MAGISKPATCH-21200
::模式0-Stock boot image detected
:MAGISKPATCH-21200-MODE0
set SHA1=
for /f %%a in ('magiskboot sha1 %bootpath% 2^>^>nul') do set SHA1=%%a
if exist %tmpdir%\imgkit-magiskpatch\ramdisk.cpio (
    copy /Y %tmpdir%\imgkit-magiskpatch\ramdisk.cpio %tmpdir%\imgkit-magiskpatch\ramdisk.cpio.orig 1>>nul 2>&1)
goto MAGISKPATCH-21200-2
::模式1-Magisk patched boot image detected
:MAGISKPATCH-21200-MODE1
set SHA1=
for /f %%a in ('magiskboot cpio ramdisk.cpio sha1 2^>^>nul') do set SHA1=%%a
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
magiskboot.exe cpio ramdisk.cpio restore 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
copy /Y %tmpdir%\imgkit-magiskpatch\ramdisk.cpio %tmpdir%\imgkit-magiskpatch\ramdisk.cpio.orig 1>>nul 2>&1
goto MAGISKPATCH-21200-2
:MAGISKPATCH-21200-2
::修补ramdisk.cpio
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
echo.KEEPVERITY=%KEEPVERITY%>config& echo.KEEPFORCEENCRYPT=%KEEPFORCEENCRYPT%>>config& echo.RECOVERYMODE=%RECOVERYMODE%>>config
if not "%SHA1%"=="" echo.SHA1=%SHA1%|find "SHA1" 1>>config
busybox.exe sed -i "s/\r//g;s/^M//g" config
type config>>nul
magiskboot.exe cpio ramdisk.cpio "add 750 init magiskinit" "patch" "backup ramdisk.cpio.orig" "mkdir 000 .backup" "add 000 .backup/.magisk config" 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
:MAGISKPATCH-21200-3
::尝试修补dtb
set dtbname=
if exist %tmpdir%\imgkit-magiskpatch\dtb set dtbname=dtb
if exist %tmpdir%\imgkit-magiskpatch\kernel_dtb set dtbname=kernel_dtb
if exist %tmpdir%\imgkit-magiskpatch\extra set dtbname=extra
if exist %tmpdir%\imgkit-magiskpatch\recovery_dtbo set dtbname=recovery_dtbo
if "%dtbname%"=="" (
    goto MAGISKPATCH-21200-4)
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
magiskboot.exe dtb %dtbname% patch 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
:MAGISKPATCH-21200-4
::尝试修补kernel
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
if "%vivo_suu_patch%"=="y" (
    magiskboot.exe hexpatch kernel 0092CFC2C9CDDDDA00 0092CFC2C9CEC0DB00 1>>nul 2>&1)
magiskboot.exe hexpatch kernel 49010054011440B93FA00F71E9000054010840B93FA00F7189000054001840B91FA00F7188010054 A1020054011440B93FA00F7140020054010840B93FA00F71E0010054001840B91FA00F7181010054 1>>nul 2>&1
magiskboot.exe hexpatch kernel 821B8012 E2FF8F12 1>>nul 2>&1
magiskboot.exe hexpatch kernel 77616E745F696E697472616D667300 736B69705F696E697472616D667300 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
goto MAGISKPATCH-DONE

:MAGISKPATCH-DONE
::打包boot
cd %tmpdir%\imgkit-magiskpatch 1>nul 2>>nul
magiskboot.exe repack %bootpath% boot_new.img 1>>nul 2>&1
cd %framework_workspace% 1>nul 2>>nul
::和原boot比较大小
set origbootsize=
for /f "tokens=2 delims= " %%a in ('busybox.exe stat -t %bootpath%') do set origbootsize=%%a
if "%origbootsize%"=="" goto FATAL
set patchedbootsize=
for /f "tokens=2 delims= " %%a in ('busybox.exe stat -t %tmpdir%\imgkit-magiskpatch\boot_new.img') do set patchedbootsize=%%a
if "%patchedbootsize%"=="" goto FATAL
::移动成品到指定目录
move /Y %tmpdir%\imgkit-magiskpatch\boot_new.img %outputpath% 1>>nul 2>&1
cd %framwork_workspace%
ENDLOCAL & set imgkit__magiskpatch__vername=%magiskver_show%& set imgkit__magiskpatch__ver=%magiskver%
goto :eof

:FATAL
ECHO. & ECHO.脚本出现致命错误，按任意键退出...& pause>nul & EXIT