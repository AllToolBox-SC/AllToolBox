set /p whoyou=<whoyou.txt
if not "%whoyou%"=="1" (
    exit /b
)

ECHO [警告]你可能是第一次运行该脚本
set /p no=%YELLOW%按任意键开始初始化环境[提示：如果已经安装过工具箱输入no可跳过]%RESET%
if "%no%"=="no" goto no
ECHO [信息]配置允许cmd颜色参数...
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f
ECHO [信息]下载安装驱动，请手动点击下一步直至完成
ECHO [信息]安装进度 1/3
.\drivers\ADB.exe
ECHO [信息]安装进度 2/3
.\drivers\9008.exe
ECHO [信息]安装进度 3/3
.\drivers\vc.exe
:no
call uplog