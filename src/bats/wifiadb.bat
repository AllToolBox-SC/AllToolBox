:MENU
CLS
call logo.bat
ECHO %ORANGE%无线调试菜单%YELLOW%
menu.exe .\menu\wifiadb.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="1" goto manual_connect
if "%MENU%"=="2" goto pair_wireless
if "%MENU%"=="3" goto usbtowifi
if "%MENU%"=="4" goto close_wireless
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto MENU


:manual_connect
setlocal
ECHO %INFO%%RESET%请确保设备已通过 USB 开启 TCP/IP 模式，或已知设备 IP 地址。
ECHO %INFO%%RESET%请输入设备 IP 地址（格式：192.168.1.100）
set /p ip_addr="IP 地址: "
ECHO %INFO%%RESET%请输入打开的端口号（默认5555）
set /p port_addr="端口号: "
if "%ip_addr%"=="" (
    ECHO %ERROR%IP 地址不能为空！%RESET%
    pause.exe 返回
    endlocal
    goto MENU
)
if "%ip_addr%"=="" set "port_addr=5555"
ECHO %INFO%%RESET%%BLUE%正在连接 %ip_addr%:%port_addr% ...%RESET%
adb connect %ip_addr%:%port_addr%
if errorlevel 1 (
    ECHO %ERROR%连接失败，请检查 IP 和 端口号 及设备状态%RESET%
) else (
    ECHO %SUCCESS%已成功连接到 %ip_addr%:%port_addr% %RESET%
)
pause.exe 返回
endlocal
goto MENU

:pair_wireless
setlocal
ECHO %INFO%%RESET%配对无线调试适用于 Android 11 及以上版本。
ECHO %INFO%%RESET%请在手机上进入「开发者选项」->「无线调试」->「使用配对码配对设备」获取 IP、端口和配对码。
ECHO.
set /p pair_ip="请输入配对 IP 地址: "
set /p pair_port="请输入配对端口号: "
set /p pair_code="请输入 6 位配对码: "

ECHO %INFO%%RESET%%BLUE%正在配对 %pair_ip%:%pair_port% ...%RESET%
adb pair %pair_ip%:%pair_port% %pair_code%
if errorlevel 1 (
    ECHO %ERROR%配对失败，请检查 IP、端口和配对码是否正确。%RESET%
) else (
    ECHO %SUCCESS%配对成功！%RESET%
    ECHO %INFO%%RESET%现在可以使用「手动连接」输入设备 IP:端口 进行连接
)
pause.exe 返回
endlocal
goto MENU

:close_wireless
setlocal
ECHO %INFO%%RESET%即将断开所有无线 ADB 连接并关闭设备的 TCP/IP 调试端口（需 USB 连接）。
ECHO %WARNING%注意：若设备未通过 USB 连接，则只能断开本机连接，无法关闭远程端口。
ECHO.
adb disconnect >nul 2>&1
ECHO %SUCCESS%已断开所有无线连接。%RESET%

adb devices | find "device" >nul
if not errorlevel 1 (
    ECHO %INFO%%RESET%%BLUE%检测到 USB 设备，正在恢复为 USB 调试模式...%RESET%
    adb usb >nul 2>&1
    if errorlevel 1 (
        ECHO %ERROR%恢复 USB 模式失败，请手动关闭无线调试。%RESET%
    ) else (
        ECHO %SUCCESS%已关闭无线调试，恢复为 USB 调试模式。%RESET%
    )
) else (
    ECHO %WARNING%未检测到 USB 设备，无法远程关闭无线调试端口。%RESET%
    ECHO %INFO%%RESET%请手动关闭「无线调试」开关。%RESET%
)
pause.exe 返回
endlocal
goto MENU

:usbtowifi
setlocal
ECHO %INFO%%RESET%请确保在同一局域网下并已用数据线连接%RESET%
device_check.exe adb&&ECHO.
ECHO %INFO%%RESET%%BLUE%正在开启调试端口5555%RESET%
adb usb 1>nul 2>nul
device_check.exe adb 1>nul 2>nul
adb tcpip 5555 1>nul || echo %error%开启调试端口失败 && pause.exe && exit /b
ECHO %INFO%%RESET%%BLUE%正在获取IP地址%RESET%
device_check.exe adb 1>nul 2>nul
for /f "tokens=*" %%a in ('adb shell ip route') do (set "iproute=%%a")
set num=1
:run
if "%num%"=="20" echo %error%查找IP地址失败%RESET% && pause.exe && exit /b
set /a num+=1
for /f "tokens=%num%" %%a in ("%iproute%") do set "ip=%%a"
echo %ip% | find "." 1>nul 2>nul || goto run
ECHO %INFO%%RESET%%BLUE%查找到IP地址：%ip%%RESET%
ECHO %INFO%%RESET%%BLUE%与设备建立连接%RESET%
adb connect %ip%:5555 1>nul  || echo %error%连接失败 && pause.exe && exit /b
ECHO %INFO%%RESET%%BLUE%已启动无线调试%RESET%
ECHO %INFO%%RESET%%BLUE%请拔掉数据线即可正常使用%RESET%
ENDLOCAL
pause.exe 返回
goto MENU