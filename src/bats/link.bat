%userdebug%
setlocal enabledelayedexpansion

set "shortname=%~1"
set "varname=%~2"

set "head1=https://pan.xgj.qzz.io/d/123pan/atbCloud/"
set "head2=https://pan.xgj.qzz.io/d/aha123/atbCloud/"
set "head3=https://pan.xgj.qzz.io/d/Baidu/atbCloud/"
set "head4=https://pan.xgj.qzz.io/d/tianyi/atbCloud/"
set "head5=http://files.corexwear.com:1314/file/atb/"
set "apks=apks.zip"
set "Q1Y=DI01.zip"
set "Q2=DI02.zip"
set "Z2=I12.zip"
set "Z5=I13.zip"
set "Z5A=I13C.zip"
set "Z1=I16.zip"
set "Z1S=I17.zip"
set "Q1S=I17D.zip"
set "Z6=I18.zip"
set "Z5Pro=I19.zip"
set "Z6dfb=I20.zip"
set "Z7=I25.zip"
set "Z7A=I25C.zip"
set "Z7S=I25D.zip"
set "Z8=I32.zip"
set "Z3=IB.zip"
set "Z9=ND01.zip"
set "Z10=ND03.zip"
set "Z8A=ND07.zip"
set "Z11=ND08.zip"
set "drivers=drivers.zip"
set "rootproapks=rootproapks.zip"
set "systemui=systemui.zip"
set "twrp=twrp.zip"
set "userdata=userdata.img"
set "xp=xp.zip"
set "xtcpatch=xtcpatch.zip"
set "bin=bin.zip"
set "versiontmp=versiontmp.txt"
set "versionnotice=versionnotice.txt"
set "notice=notice.txt"
set "resversion=resversion.txt"
set "head=%head5%"
if "%~1"=="head" endlocal & set "%varname%=%head%" & exit /b
set "filename=!%shortname%!"
if not defined filename (
    echo %error%¥ÌŒÛ£∫"%shortname%" Œ¥∂®“Â
    endlocal
    exit /b 1
)

set "full_url=%head%%filename%"
endlocal & set "%varname%=%full_url%" & set "head=%head%"