ECHO.%INFO%正在更新...%RESET%

if exist ".\tmp\userdata.img" (
    call resversion userdata.img
    if !errorlevel! neq 0 call cloud userdata
)

if exist ".\apks" (
    call resversion apks.zip
    if !errorlevel! neq 0 call cloud apks
)

if exist ".\tmp\systemui.zip" (
    call resversion systemui.zip
    if !errorlevel! neq 0 call cloud systemui
)

if exist ".\tmp\xtcpatch.zip" (
    call resversion xtcpatch.zip
    if !errorlevel! neq 0 call cloud xtcpatch
)

if exist ".\EDL\twrp" (
    call resversion twrp.zip
    if !errorlevel! neq 0 call cloud twrp
)

if exist ".\tmp\xposed.zip" (
    call resversion xp.zip
    if !errorlevel! neq 0 call cloud xp
)

if exist ".\rootproapks" (
    call resversion rootproapks.zip
    if !errorlevel! neq 0 call cloud rootproapks
)

if exist ".\drivers" (
    call resversion drivers.zip
    if !errorlevel! neq 0 call cloud drivers
)

if exist ".\EDL\I17D.zip" (
    call resversion I17D.zip
    if !errorlevel! neq 0 call cloud Q1S
)

if exist ".\EDL\DI01.zip" (
    call resversion DI01.zip
    if !errorlevel! neq 0 call cloud Q1Y
)

if exist ".\EDL\DI02.zip" (
    call resversion DI02.zip
    if !errorlevel! neq 0 call cloud Q2
)

if exist ".\EDL\I16.zip" (
    call resversion I16.zip
    if !errorlevel! neq 0 call cloud Z1
)

if exist ".\EDL\I17.zip" (
    call resversion I17.zip
    if !errorlevel! neq 0 call cloud Z1S
)

if exist ".\EDL\I12.zip" (
    call resversion I12.zip
    if !errorlevel! neq 0 call cloud Z2
)

if exist ".\EDL\IB.zip" (
    call resversion IB.zip
    if !errorlevel! neq 0 call cloud Z3
)

if exist ".\EDL\I13.zip" (
    call resversion I13.zip
    if !errorlevel! neq 0 call cloud Z5
)

if exist ".\EDL\I13C.zip" (
    call resversion I13C.zip
    if !errorlevel! neq 0 call cloud Z5A
)

if exist ".\EDL\I19.zip" (
    call resversion I19.zip
    if !errorlevel! neq 0 call cloud Z5Pro
)

if exist ".\EDL\I18.zip" (
    call resversion I18.zip
    if !errorlevel! neq 0 call cloud Z6
)

if exist ".\EDL\I20.zip" (
    call resversion I20.zip
    if !errorlevel! neq 0 call cloud Z6dfb
)

if exist ".\EDL\I25.zip" (
    call resversion I25.zip
    if !errorlevel! neq 0 call cloud Z7
)

if exist ".\EDL\I25C.zip" (
    call resversion I25C.zip
    if !errorlevel! neq 0 call cloud Z7A
)

if exist ".\EDL\I25D.zip" (
    call resversion I25D.zip
    if !errorlevel! neq 0 call cloud Z7S
)

if exist ".\EDL\I32.zip" (
    call resversion I32.zip
    if !errorlevel! neq 0 call cloud Z8
)

if exist ".\EDL\ND07.zip" (
    call resversion ND07.zip
    if !errorlevel! neq 0 call cloud Z8A
)

if exist ".\EDL\ND01.zip" (
    call resversion ND01.zip
    if !errorlevel! neq 0 call cloud Z9
)

if exist ".\EDL\ND03.zip" (
    call resversion ND03.zip
    if !errorlevel! neq 0 call cloud Z10
)

call cloud bin
ECHO.%green%更新完成，重新启动...%RESET%
busybox sleep 2
cls
cmd /c call start.bat