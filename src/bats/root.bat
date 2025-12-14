if "%1"=="" goto ROOT
set nouserdata=1
ECHO.%INFO%你选择了不刷userdata，这可能导致设备出现问题
pause
:ROOT
SETLOCAL disabledelayedexpansion
CLS
echo %YELLOW%════════════════════════%RESET%
echo %GREEN_2%一键%ORANGE%ROOT%RESET%
echo %YELLOW%════════════════════════%RESET%
echo %WARN%本功能是easy root重制版%RESET%
echo %WARN%重构了原来的代码%RESET%
echo %GREEN_2%本工具支持小天才Q1y,Q1S,Q2,Z1,Z1S,Z2,Z3,Z5q,Z5A,Z5Pro,Z6,Z6_DFB,Z7,Z7A,Z7S,Z8,Z8A,Z9手表root%RESET%
echo %GREEN_2%z10,z11手表不会在此功能更新,可能会以扩展包的形式制作%RESET%
echo %INFO%本功能可以完全离线运行%RESET%
pause
echo %ORANGE%免责声明：  
echo %WARN%在使用本工具对小天才电话手表系列进行ROOT、刷机、解除安装限制、安装非官方应用等操作[统称"刷机"]前，您必须仔细阅读并完全理解本声明。一旦您实施或完成刷机行为，即视为您已充分知晓、同意并自愿承担本声明所述的全部风险及责任。  
echo %WARN%本工具仅供学习，交流使用，并非"破解"小天才电话手表系列产品。严禁用于任何形式非法用途。
echo %WARN%本工具不能用于解绑手表，如您通过不正当手段获取的手表请联系公安机关归还手表！
echo.
echo %WARN%1. 设备功能与服务失效风险  
echo %WARN%刷机后您的设备将脱离官方原厂固件，可能导致以下后果：  
echo %WARN%1.1 无法使用广东小天才科技有限公司（以下简称“小天才”）提供的各项官方服务，包括但不限于系统更新、应用商店、家长端管理、定位、通话、支付、安全功能及云服务等；  
echo %WARN%1.2 设备可能出现系统不稳定、功能异常、性能下降、兼容性问题、数据丢失或硬件损坏等风险；  
echo %WARN%1.3 设备自进入9008模式起即刻丧失官方保修资格，小天才无义务恢复因刷机行为所导致的任何功能或服务损失。
echo %WARN%2. 相关用户协议条款援引  
echo %WARN%根据小天才《用户协议》（用户于手表开机时点击确认按钮即视为同意）的约定，以下行为属于明确禁止的范畴，用户须严格遵守：
echo %WARN%【禁止行为】  
echo %WARN%您可在本协议约定的范围内使用小天才产品和服务，不得从事包括但不限于以下行为：
echo.
echo %WARN%（1）复制、变更、反向工程、反汇编、反编译、拆装、企图导出其源代码、解码、其他对修改小天才产品和服务的源代码、构造、构思等进行解析或者复制的行为；  
echo %WARN%（2）删除小天才产品和服务上关于著作权的信息；  
echo %WARN%（3）对小天才产品和服务拥有知识产权的内容进行使用、出租、出借、复制、修改、链接、转载、汇编、发表、出版、建立镜像站点、录屏、剪接等；  
echo %WARN%（4）赠与、借用、租用、转让、售卖、再分发、其他再许可小天才产品和服务软件的相关行为；  
echo %WARN%（5）利用小天才产品和服务发表、传送、传播、储存危害国家安全、国家统一、社会稳定的内容，或侮辱诽谤、色情、暴力、引起他人不安及任何违反国家法律法规政策的内容或者设置含有上述内容的网名、角色名，发布、传送、传播含有上述内容的广告信息、营销信息及垃圾信息等的行为；  
echo %WARN%（6）利用小天才产品和服务侵害他人知识产权、肖像权、隐私权、名誉权等合法权利或权益的行为；  
echo %WARN%（7）恶意虚构事实、隐瞒真相以误导、欺诈他人的行为；  
echo %WARN%（8）进行任何危害计算机网络安全的行为，包括但不限于：进入未经许可访问的服务器/账号/硬件系统存储器或其他小天才和小天才用户存储数据的软硬件；没有访问权限而未经允许进入小天才和小天才用户的计算机网络、计算机系统和存储数据的系统存储器等软硬件设施；未经许可查询、删除、修改、增加存储、下载、使用小天才服务器或用户软硬件设备上的数据；未经许可，企图探查、扫描、测试小天才产品和服务或网络的弱点或其它实施破坏网络安全的行为；企图干涉、破坏小天才产品和服务或网络的正常运行，故意传播恶意程序或病毒以及其他破坏干扰正常网络信息服务的行为；伪造TCP/IP数据包名称或部分名称；利用伪造的IP地址访问小天才服务器等；  
echo %WARN%（9）进行任何破坏小天才提供服务公平性或者其他影响应用正常运行秩序的行为，如主动或被动刷积分，使用外挂或者其他的非法软件、利用BUG（又叫“漏洞”或者“缺陷”）来从小天才产品和服务中获得不正当的利益，或者利用互联网或其他方式将外挂、非法软件提供给他人或公之于众等行为；  
echo %WARN%（10）进行任何诸如发布广告、销售商品的商业行为，或者进行任何非法的侵害小天才利益的行为；  
echo %WARN%（11）从事其他法律法规、政策及公序良俗、社会公德禁止的行为以及侵犯其他个人、公司、社会团体、组织的合法权益的行为。
echo.
echo %WARN%【行为限制】  
echo %WARN%如您违反本协议约定，小天才有权依照业务规则及您的行为性质，采取包括但不限于删除您发布的信息内容、暂停账号使用、终止服务、限制使用、回收小天才账号、追究法律责任等措施。对恶意注册小天才账号或利用小天才账号进行违法活动、捣乱、骚扰、欺骗其他用户以及其他违反本协议的行为，小天才有权回收其账号。以上后果可能对您造成损失，该损失应由您自行承担，小天才不承担任何责任。小天才有权对部分违规行为进行限制。
echo %WARN%2. 功能异常与数据安全  
echo %WARN%刷机可能导致家长端功能异常、设备功能失效、数据错误或丢失。我们对此不承担责任。您需自行完成数据备份并承担全部后果。  
echo.
echo %WARN%3. 使用行为与监护人责任  
echo %WARN%设备经修改后可能具备安装非官方应用或增强网络访问的能力，您须合法合规使用。若因沉迷网络、不当使用应用、接触不良信息导致身心健康受损、财产损失或其他后果，我们不承担任何责任。若设备使用者为未成年人，其监护人须承担完全的监督与管理义务。您应在刷机后48小时内恢复小天才官方系统。  
echo.
echo %WARN%4. 操作自愿性  
echo %WARN%刷机属于您个人自愿行为。我们仅提供技术信息与文件资源，从未主动要求、诱导或强制用户进行任何刷机操作。您须对自身操作及后果负全部责任。  
echo.
echo %WARN%5. 设备所有权与非法解绑  
echo %WARN%5.1 我们严禁且不提供任何形式的“手表强制解绑”服务或技术支持；  
echo %WARN%5.2 您须确认自身为设备合法所有者或已获所有者明确授权。如拾获他人设备，须依法联系公安机关（110）或通过官方途径归还失主；  
echo %WARN%5.3 对非本人所有或未授权设备进行刷机、解除挂失锁、解绑等操作属违法行为，可能构成犯罪。我们严厉谴责此类行为，行为人须自行承担民事赔偿、行政处罚及刑事责任，我们不承担任何关联责任。  
echo.
echo %WARN%6. 责任范围限定  
echo %WARN%我们作为技术爱好者，仅提供技术交流与文件资源（限研究学习目的）。您因使用本平台资源刷机导致的直接或间接损失（包括设备损坏、数据丢失、功能异常、保修失效、第三方索赔等），我们不承担责任。  
echo.
echo %WARN%7. 操作禁令  
echo %WARN%严禁代刷、强迫或教唆他人刷入非官方系统。任何此类行为均违背本声明原则，相关责任由行为人独立承担。  
echo.
echo %WARN%8. 恶意行为责任  
echo %WARN%您承诺不利用修改后的设备实施以下行为：  
echo %WARN%8.1 恶意破坏设备或数据（无论归属）；  
echo %WARN%8.2 未授权访问、窃取、滥用他人个人信息或账户；  
echo %WARN%8.3 实施欺诈、盗窃、网络攻击等违法犯罪；  
echo %WARN%8.4 未授权操作他人账号。  
echo %WARN%因上述行为导致他人财产损失、隐私泄露等后果，行为人须承担全部法律责任及赔偿。我们保留追究其法律责任的权利。  
echo.
echo %WARN%9. 隐私保护禁令  
echo %WARN%获取小天才用户信息属违法行为，请立即卸载非法抓包工具（如HttpCanary）。我们严禁任何侵犯隐私行为，违者将依法承担法律责任。  
echo.
ECHO %INFO%请在阅读完毕《免责声明》，并同意自行承担一切后果后按任意键继续%RESET%
pause >nul
echo %WARN%请确认你的手表已经拔出sim卡%RESET%
pause
echo %INFO%你可以用以下两种方案你把你的设备连接到电脑%RESET%
echo %BLUE%[提示]%WHITE%1.手表打开拨号盘输入*#0769651#*打开ADB开关,随后用数据线连接电脑%RESET%
echo %BLUE%[提示]%WHITE%2.打开手表卡槽,用金属物品短接触点,随后用数据线连接电脑%RESET%
echo %YELLOW%════════════════════════════════════════════════%RESET%
ECHO.%WARN%如果提示未授权、离线等请重新连接
echo %YELLOW%════════════════════════════════════════════════%RESET%
device_check.exe adb qcom_edl&&ECHO.
timeout /t 2 /nobreak >nul
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if "%devicestatus%"=="qcom_edl" (
call qmmi
)

for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.innermodel') do set innermodel=%%i
echo %INFO%您的设备innermodel为:%innermodel%
if "%innermodel%"=="I25C" (
   set smodel=1
   echo %WARN%此型号ROOT可能存在不稳定性问题，是否继续？
   pause
)
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.model') do set model=%%i
echo %INFO%手表型号:%model%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.build.version.release') do set androidversion=%%i
echo %INFO%安卓版本:%androidversion%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.build.version.sdk') do set sdkversion=%%i
echo %INFO%SDK版本号:%sdkversion%
for /f "delims=" %%i in ('adb wait-for-device shell getprop ro.product.current.softversion') do set version=%%i
echo %INFO%版本号:%version%
call isv3
del /Q /F tmp.txt >nul 2>nul
del /Q /F .\*.img >nul 2>nul
del /Q /F .\tmp\boot.img >nul 2>nul
del /Q /F .\header >nul 2>nul
del /Q /F .\kernel_dtb >nul 2>nul
del /Q /F .\kernel >nul 2>nul
del /Q /F .\ramdisk.cpio >nul 2>nul
del /Q /F .\port_trace.txt >nul 2>nul
del /Q /F .\EDL\rooting\*.* >nul 2>nul
rd /Q /S .\EDL\rooting\xtcpatch >nul 2>nul
rd /Q /S .\EDL\rooting\magiskfile >nul 2>nul
md .\EDL\rooting 1>nul 2>>nul
ECHO %INFO%正在为您从本地拷贝文件
ECHO %INFO%文件更新时间：
type "%cd%\EDL\time.txt"
if %errorlevel% neq 0 (
   ECHO %WARN%未下载过root文件，正常没有影响
)
copy /Y "%cd%\EDL\%innermodel%.zip" "%cd%\EDL\rooting\root.zip"
ECHO %INFO%开始解压文件
7z x EDL\rooting\root.zip -o.\EDL\rooting -aoa >nul 2>&1
if %errorlevel% neq 0 (
   ECHO %ERROR%解压文件时出现错误，错误值:%errorlevel%
   ECHO %INFO%按任意键退出
   pause >nul
   ENDLOCAL
   exit /b
)
if "%sdkversion%"=="19" (
goto ROOT-SDK19
)
if "%sdkversion%"=="25" (
goto ROOT-SDK25
)
if "%sdkversion%"=="27" (
goto ROOT-SDK27
)
if "%androidversion%"=="11" (
ECHO %INFO%触发彩蛋：安卓11！
ECHO.%ERROR%出错了
pause
ENDLOCAL
exit /b
)

:ROOT-SDK19 
ECHO.%WARN%请注意检查驱动
ECHO.%INFO%正在重启到bootloader模式，你的手表并没有变砖
run_cmd "adb reboot bootloader"
device_check.exe fastboot&&ECHO.
ECHO.%INFO%正在刷入boot
fastboot flash boot EDL\rooting\sboot.img
ECHO.%INFO%重新启动，退出bootloader模式
fastboot reboot
ECHO.%INFO%等待设备连接
device_check.exe adb&&ECHO.
ECHO.%INFO%坐和放宽，让我们等待120秒
busybox sleep 120
ECHO.%INFO%安装管理器
call instapp .\EDL\rooting\manager.apk
ECHO.%INFO%启动管理器
run_cmd "adb shell am start -n com.topjohnwu.magisk/.ui.MainActivity"
ECHO.%INFO%修复运行环境
run_cmd "adb shell ""mkdir -p /sdcard/magisk"""
adb push tmp\magiskfile /sdcard/magisk
run_cmd "adb shell ""su -c rm -rf /data/adb/magisk"""
run_cmd "adb shell ""su -c cp -af /sdcard/magisk/* /data/adb/magisk/"""
run_cmd "adb shell ""su -c chmod -R 755 /data/adb/magisk/"""
ECHO.%INFO%刷入xtcpatch模块
call instmodule2.bat tmp\xtcpatch.zip
ECHO.%INFO%重启手表
adb reboot
ECHO.%INFO%您的手表ROOT完毕
ECHO.%INFO%删除临时文件
del /Q /F .\EDL\rooting\*.*
ECHO.%INFO%5秒后返回主页%RESET%
busybox sleep 5
exit /b

:ROOT-SDK25
echo %YELLOW%════════════════════════════════════════════════%RESET%
ECHO.%ORANGE% 请选择一种方案
ECHO. 1.BOOT方案[如果已经降级请选择此方案]
ECHO. 2.Recovery方案[最新系统可使用此方案]
echo %YELLOW%════════════════════════════════════════════════%RESET%
set /p recorroot=%YELLOW%请输入序号并按下回车键：%RESET%
if "%recorroot%"=="1" goto ROOT-SDK25-1
if "%recorroot%"=="2" goto ROOT-SDK25-2
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto ROOT-SDK25

:ROOT-SDK25-1
ECHO.%INFO%重启您的手表至9008
adb reboot edl
call edlport
ECHO.%INFO%发送引导
QSaharaServer.exe -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\msm8909w.mbn >nul
busybox sleep 2
ECHO.%INFO%读取boot
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --sendxml=%cd%\EDL\rooting\boot.xml --convertprogram2read --noprompt >nul
move /Y .\boot.img .\tmp\boot.img
if %errorlevel% neq 0 (
   echo %ERROR%移动boot.img文件失败
   ECHO %ERROR%这是一个致命问题，可能数据线连接不稳定，没有成功读取boot%RESET%
   pause
   exit /b
)
ECHO.%INFO%开始修补boot
call magiskpatch %cd%\tmp\boot.img %cd%\boot.img 20400.zip noprompt >nul
ECHO.%INFO%解包boot
magiskboot unpack -h boot.img 1>nul 2>nul
ECHO.%INFO%替换adbd
magiskboot.exe cpio ramdisk.cpio "add 0750 sbin/adbd 711_adbd"  1>nul 2>nul
ECHO.%INFO%宽容selinux
patch_boot.exe | find "Suc" 1>nul 2>nul || ECHO %ERROR%patch_boot.exe无法运行,请尝试安装VC运行库合集&&pause&&exit
ECHO.%INFO%打包boot
magiskboot repack boot.img 1>nul 2>nul
ECHO.%INFO%BOOT处理完成!!!
copy /Y new-boot.img EDL\rooting\boot.img > nul
del /Q /F .\tmp\boot.img
ECHO.%INFO%刷入BOOT
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\boot.xml --noprompt >nul
ECHO.%INFO%boot刷入完毕
ECHO.%INFO%重启手表
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
goto ROOT-SDK25-wait

:ROOT-SDK25-2
ECHO.%INFO%重启您的手表至9008
adb reboot edl
call edlport
ECHO.%INFO%发送引导
QSaharaServer.exe -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\msm8909w.mbn >nul
busybox sleep 2
ECHO.%INFO%读取boot
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --sendxml=%cd%\EDL\rooting\boot.xml --convertprogram2read --noprompt >nul
move /Y .\boot.img .\tmp\boot.img
if %errorlevel% neq 0 (
   echo %ERROR%移动boot.img文件失败
   ECHO %ERROR%这是一个致命问题，可能数据线连接不稳定，没有成功读取boot%RESET%
   pause
   exit /b
)
ECHO.%INFO%开始修补boot
call magiskpatch %cd%\tmp\boot.img %cd%\boot.img 20400.zip noprompt >nul
ECHO.%INFO%解包boot
magiskboot unpack -h boot.img 1>nul 2>nul
ECHO.%INFO%替换adbd
magiskboot.exe cpio ramdisk.cpio "add 0750 sbin/adbd 711_adbd"  1>nul 2>nul
ECHO.%INFO%宽容selinux
patch_boot.exe | find "Suc" 1>nul 2>nul || ECHO %ERROR%patch_boot.exe无法运行,请尝试安装VC运行库合集&&pause&&exit
ECHO.%INFO%打包boot
magiskboot repack boot.img 1>nul 2>nul
ECHO.%INFO%BOOT处理完成!!!
copy /Y new-boot.img EDL\rooting\recovery.img > nul
del /Q /F .\tmp\boot.img
ECHO.%INFO%刷入BOOT至Recovery分区
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\recovery.xml --noprompt >nul
ECHO.%INFO%刷入misc
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt >nul
ECHO.%INFO%重启手表
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间

:ROOT-SDK25-wait
call boot_completed.bat
ECHO.%INFO%安装管理器
call instapp .\EDL\rooting\manager.apk
ECHO.%INFO%启动管理器[等待五秒]
busybox sleep 5
ECHO.
run_cmd "adb shell am start com.topjohnwu.magisk/a.c"
run_cmd "adb wait-for-device push EDL\rooting\xtcpatch /sdcard/"
run_cmd "adb wait-for-device push EDL\rooting\magiskfile /sdcard/"
ECHO.%INFO%复制运行环境及刷入模块
run_cmd "adb push 2100.sh /sdcard/"
run_cmd "adb shell ""su -c sh /sdcard/2100.sh"""
call instmodule2.bat tmp\xtcpatch.zip
ECHO.%INFO%安装Notice
call instapp.bat .\apks\notice.apk
ECHO.%INFO%安装第三方应用商店
call instapp.bat .\apks\appstore.apk
call instapp.bat .\apks\appstore2.apk
ECHO.%INFO%安装第三方安装器
call instapp.bat .\apks\MoyeInstaller.apk
run_cmd "adb shell am start -a android.intent.action.VIEW -d file:///sdcard/1.apk -t application/vnd.android.package-archive"
ECHO.%INFO%请在手表端选择弦-安装器，点击始终，然后按任意键继续
pause
if "%recorroot%"=="1" goto ROOT-SDK25-F
ECHO.%INFO%重启您的手表至9008
adb wait-for-device reboot edl
call edlport
ECHO.%INFO%发送引导
QSaharaServer.exe -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\msm8909w.mbn >nul
ECHO.%INFO%刷入BOOT至Recovery分区
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\recovery.xml --noprompt >nul
ECHO.%INFO%刷入misc
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\misc.xml --noprompt >nul
ECHO.%INFO%重启手表
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
:ROOT-SDK25-F
device_check.exe adb qcom_edl&&ECHO.
call boot_completed.bat
adb shell magisk -v | find "MAGISK" 1>nul 2>nul || ECHO %ERROR%ROOT失败！发生错误，错误root-sdk25-F，请尝试换方案再次root&&ECHO.%INFO%按任意键返回&&pause&&ENDLOCAL&&exit /b
ECHO.%INFO%您的手表已ROOT完毕
ECHO.%INFO%按任意键返回
pause
ENDLOCAL
exit /b

:ROOT-SDK27
ECHO.%INFO%重启您的手表至9008
adb reboot edl
call edlport

:ROOT-SDK27-Patch
ECHO.%INFO%发送引导
QSaharaServer.exe -p \\.\COM%chkdev__edl_port% -s 13:%cd%\EDL\msm8937.mbn >nul
busybox sleep 2
ECHO.%INFO%读取boot
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --sendxml=%cd%\EDL\rooting\boot.xml --convertprogram2read --noprompt >nul
move /Y .\boot.img .\tmp\boot.img 1>nul 2>nul
if %errorlevel% neq 0 (
   echo %ERROR%移动boot.img文件失败
   ECHO %ERROR%这是一个致命问题，可能数据线连接不稳定，没有成功读取boot%RESET%
   pause
   exit /b
)
busybox sleep 1
ECHO.%INFO%开始修补boot
call magiskpatch %cd%\tmp\boot.img %cd%\boot.img magisk.apk noprompt
ECHO.%INFO%解包boot
magiskboot unpack -h boot.img 1>nul 2>nul
ECHO.%INFO%替换adbd
magiskboot.exe cpio ramdisk.cpio "add 0750 sbin/adbd 810_adbd"  1>nul 2>nul
magiskboot.exe cpio ramdisk.cpio "add 0750 overlay.d/xse.rc xse.rc"  1>nul 2>nul
ECHO.%INFO%宽容selinux
patch_boot.exe | find "Suc" 1>nul 2>nul || ECHO %ERROR%patch_boot.exe无法运行,请尝试安装VC运行库合集&&pause&&exit
ECHO.%INFO%打包boot
magiskboot repack boot.img 1>nul 2>nul
ECHO.%INFO%BOOT处理完成!!!
copy /Y new-boot.img EDL\rooting\sboot.img > nul
del /Q /F .\tmp\boot.img

if "%smodel%"=="1" (
ECHO.%INFO%刷入recovery
copy EDL\rooting\sboot.img EDL\rooting\recovery.img > nul
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\recovery.xml --noprompt >nul
ECHO.%INFO%刷入boot，aboot，userdata，misc
) else (
ECHO.%INFO%刷入recovery，aboot
)
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=EDL\rooting --sendxml=EDL\rooting\rawprogram0.xml --noprompt >nul
if "%nouserdata%"=="1" (
ECHO.%INFO%重启手表
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO.%INFO%你选择了不刷userdata，不再继续
ECHO.按任意键返回...
pause >nul
ENDLOCAL
exit /b
)
if "%smodel%"=="1" (
ECHO.%INFO%重启手表
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
goto ROOT-SDK27-WAIT
)
ECHO.%INFO%擦除boot
copy /Y tmp\eboot.img tmp\boot.img > nul
fh_loader.exe --port=\\.\COM%chkdev__edl_port% --memoryname=EMMC --search_path=tmp --sendxml=EDL\rooting\boot.xml --noprompt >nul
ECHO.%INFO%重启手表
qfh_loader.exe --port=\\.\COM%chkdev__edl__port% --memoryname=EMMC --search_path=EDL\ --sendxml=reboot.xml --noprompt >nul
ECHO.%INFO%等待开机
device_check.exe fastboot&&ECHO.
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%你的手表没有变砖!
ECHO.%WARN%不是进入fastboot就是变砖！
ECHO.%INFO%刷入boot
run_cmd "fastboot flash boot new-boot.img"
ECHO.%INFO%刷入userdata
run_cmd "fastboot flash userdata tmp\userdata.img"
echo ffbm-02 > misc.bin
run_cmd "fastboot flash misc misc.bin"
run_cmd "fastboot reboot"
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
device_check.exe adb qcom_edl&&ECHO.
ECHO.%INFO%稍等片刻，即将开始
call boot_completed.bat
ECHO.%WARN%工具未做出提示不要在手表上点任何内容！！
ECHO.%WARN%请 不要 点击重启-重启并进入正常启动模式
ECHO.%WARN%请 不要 点击重启-重启并进入正常启动模式

:ROOT-SDK27-WAIT
if "%smodel%"=="1" (
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
device_check.exe adb qcom_edl&&ECHO.
ECHO.%INFO%稍等片刻，即将开始
call boot_completed.bat
busybox sleep 15
call instapp .\apks\54850.apk
)
adb reboot
device_check.exe adb qcom_edl fastboot&&ECHO.
for /f "delims=" %%i in ('type tmp.txt') do set devicestatus=%%i
if not "%devicestatus%"=="adb" (
ECHO.%ERROR%您的设备可能触发了Xse限制！请重新进行root
ECHO.%ERROR%按任意键返回...
pause > nul
ENDLOCAL
exit /b
)
call boot_completed.bat
ECHO.%WARN%接下来要在您的手表上完成一些操作，请按照工具提示一步步进行操作，期间禁止联网，重复绑定！
ECHO.%INFO%请在3s后按任意键继续...
timeout /t 3 /nobreak > nul
pause
ECHO.%INFO%正在启动投屏！如手表端不方便操作，可在电脑端进行操作
ECHO.%INFO%提示：如果手表息屏，在投屏窗口单击右键即可
start scrcpy-noconsole.vbs
run_cmd "adb shell setprop persist.sys.charge.usable true"
ECHO.%INFO%充电可用已开启
run_cmd "adb shell dumpsys battery unplug"
ECHO.%INFO%已模拟未充电状态
run_cmd "adb shell svc wifi disable"
run_cmd "adb shell wm density 200"
run_cmd "adb shell am start -n com.topjohnwu.magisk/.ui.MainActivity"
ECHO.%INFO%很好，现在请打开Magisk右上角设置，往下滑，找到自动响应，修改为允许，然后找到超级用户通知，修改为无，然后按任意键继续
pause
ECHO.%INFO%正在自动打开Edxposed Installer，请稍后
device_check.exe adb qcom_edl&&ECHO.
run_cmd "adb shell am start -n com.solohsu.android.edxp.manager/de.robv.android.xposed.installer.WelcomeActivity"
busybox sleep 7
:ROOT-Xposed
run_cmd "adb shell am start -n com.huanli233.systemplus/.ActiveSelfActivity"
ECHO.%INFO%请往下滑，找到自激活，然后点击激活SystemPlus与激活核心破解，然后按任意键继续
pause
run_cmd "adb push systemplus.sh /sdcard/systemplus.sh"
ECHO.%INFO%开始检查SystemPlus激活状态...
for /f "delims=" %%i in ('adb wait-for-device shell sh /sdcard/systemplus.sh') do set systemplus=%%i
if "%systemplus%"=="1" (
ECHO.%ERROR%未激活
ECHO.%ERROR%你没有激活SystemPlus！按任意键重回上一步
pause
goto ROOT-Xposed
)
ECHO.%INFO%已激活
run_cmd "adb push toolkit.sh /sdcard/toolkit.sh"
ECHO.%INFO%开始检查核心破解激活状态...
for /f "delims=" %%i in ('adb wait-for-device shell sh /sdcard/toolkit.sh') do set toolkit=%%i
if "%toolkit%"=="1" (
ECHO.%ERROR%未激活
ECHO.%ERROR%你没有激活核心破解！按任意键重回上一步
pause
goto ROOT-Xposed
)
ECHO.%INFO%已激活
adb wait-for-device shell "dumpsys package com.solohsu.android.edxp.manager | grep userId="
ECHO.%INFO%请输入最后上方显示的最后5位数字
set /p chown=
ECHO.%INFO%正在修改文件/data/user_de/0/com.solohsu.android.edxp.manager/conf/enabled_modules.list的所有者
adb shell "su -c chown %chown% /data/user_de/0/com.solohsu.android.edxp.manager/conf/enabled_modules.list"

ECHO.%INFO%正在修改文件/data/user_de/0/com.solohsu.android.edxp.manager/conf/modules.list的所有者
adb shell "su -c chown %chown% /data/user_de/0/com.solohsu.android.edxp.manager/conf/modules.list"
ECHO.%INFO%稍等片刻，即将开始
CLS
call logo
ECHO.%ORANGE%--------------------------------------------------------------------
ECHO.%PINK%-把时间交给我们-
ECHO.%INFO%开始安装XTC Patch模块
adb shell setprop persist.sys.ez true
adb push tmp\xtcpatch.zip /sdcard/
adb shell setprop persist.sys.rooting true
adb shell "su -c magisk --install-module /sdcard/xtcpatch.zip"
run_cmd "adb shell setprop persist.sys.rooting false"
run_cmd "adb shell ""rm -rf /sdcard/xtcpatch.zip"""
run_cmd "adb shell wm density reset"
run_cmd "adb shell pm clear com.android.packageinstaller"
run_cmd "adb reboot"
ECHO.%INFO%安装XTC Patch模块成功
device_check.exe adb qcom_edl&&ECHO.
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
call boot_completed.bat
if "%smodel%"=="1" (
busybox sleep 5
adb shell "su -c sh /data/adb/modules/XTCPatch/active_module.sh com.huanli233.systemplus"
adb shell "su -c sh /data/adb/modules/XTCPatch/active_module.sh com.zcg.xtcpatch"
adb reboot
device_check.exe adb qcom_edl&&ECHO.
call boot_completed.bat
busybox sleep 5
)
busybox sleep 5
ECHO.%INFO%开始安装一些必备应用,共计11个
call instapp.bat .\apks\notice.apk
call instapp.bat .\apks\wxzf.apk
call instapp.bat .\apks\wcp2.apk
call instapp.bat .\apks\appstore.apk
call instapp.bat .\apks\appstore2.apk
call instapp.bat .\apks\appmanager.apk
call instapp.bat .\apks\personalcenter.apk
call instapp.bat .\apks\MoyeInstaller.apk
call instapp.bat .\apks\weichat.apk
call instapp.bat .\apks\appsettings.apk
call instapp.bat .\apks\vibrator.apk
ECHO.%INFO%必备应用安装完成,重启手表
adb reboot
device_check.exe adb qcom_edl&&ECHO.
ECHO.%INFO%坐和放宽，让我们等待您的手表一段时间
call boot_completed.bat
busybox sleep 5
ECHO.%INFO%开始安装一些系统应用
call instapp.bat .\apks\selftest.apk
call instapp.bat .\apks\settings.apk
if "%isv3%"=="1" (
call instapp.bat .\apks\121750.apk
)
if "%isv3%"=="0" (
call instapp.bat .\apks\116100.apk
)
ECHO.%INFO%系统应用安装完成
if "%smodel%"=="1" (
ECHO.%INFO%重启手表
adb reboot
) else (
ECHO.%INFO%擦除misc并重启
adb reboot bootloader
fastboot erase misc
fastboot reboot
)
device_check.exe adb qcom_edl&&ECHO.
call boot_completed.bat
busybox sleep 5
ECHO.%INFO%使用提示:当手表进入长续航模式、睡眠模式等禁用模式时，可下滑点击手电筒按钮，选择AppManager-仅此一次即可打开第三方应用
ECHO.%INFO%正在执行提前编译，可能需要一些时间
adb shell cmd package compile -m everything-profile -f com.xtc.i3launcher
adb shell cmd package compile -m everything-profile -f com.xtc.setting
ECHO.%WARN%请永远不要卸载SystemPlus和XTCPatch，否则手表无法开机
ECHO.%WARN%请永远不要卸载SystemPlus和XTCPatch，否则手表无法开机
ECHO.%WARN%请永远不要卸载SystemPlus和XTCPatch，否则手表无法开机
ECHO.%GRAY%-跨越山海 终见曙光-
ECHO.%INFO%请确保手表为亮屏并已进入桌面状态，然后按任意键继续
pause
ECHO.%INFO%请确认当前位于表盘页面
pause
run_cmd "adb shell am start -a android.intent.action.VIEW -d file:///sdcard/1.apk -t application/vnd.android.package-archive"
ECHO.%INFO%请在手表端选择弦-安装器，点击始终，然后按任意键继续
ECHO.%INFO%提示安装包解析错误是正常的，我们只是在引导您设置默认安装器
pause
ECHO.%INFO%您的手表已ROOT完毕
ECHO.%INFO%5秒后返回
busybox sleep 5
ENDLOCAL
exit /b