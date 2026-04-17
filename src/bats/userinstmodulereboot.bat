:reboot
ECHO.
set /p quq=%YELLOW%已尝试刷入此模块，是否重启设备以加载模块?[y/n]：
if "%quq%"=="y" (
adb reboot
ECHO.%INFO%操作完成...
exit /b
)
if "%quq%"=="n" (
ECHO.%INFO%操作完成...
exit /b
)
ECHO.%ERROR%请输入y或n！
pause.exe 重新输入
goto yesno
echo.