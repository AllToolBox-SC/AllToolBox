%userdebug%
:menu
CLS
call logo
ECHO %ORANGE%模块商店%RESET%
del /Q /F .\menutmp.txt >nul 2>nul
menu.exe .\menu\modulestore.json
set /p MENU=<menutmp.txt
if "%MENU%"=="A" exit /b
if "%MENU%"=="a" exit /b
if "%MENU%"=="1" goto allmodules
if "%MENU%"=="2" goto modulecategories
ECHO %ERROR%输入错误，请重新输入！%RESET%
timeout /t 2 >nul
goto menu

:allmodules
CLS
call logo
echo %INFO%敬请期待%RESET%
echo 按任意键返回
pause>nul
goto menu

:modulecategories
CLS
call logo
echo %INFO%敬请期待%RESET%
echo 按任意键返回
pause>nul
goto menu