@echo off
:EDL
set rechk=y
set rechk_wait=1
:EDL-1
ECHO %INFO%%RESET%%BLUE%正在查找9008端口%RESET%
:EDL-set
set try_times=1
:EDL-2
if %try_times% GTR 30 goto EDL-set
set /a try_times+=1
for /f %%a in ('devcon.exe find usb* ^| find /c "Qualcomm HS-USB QDLoader 9008"') do (if %%a GTR 1 ECHO %ERROR%有多个edl设备连接! 请断开其他设备.%RESET% & devcon.exe find usb* | find /c "Qualcomm HS-USB QDLoader 9008" & ECHO %YELLOW%按任意键重新检查...%RESET% & pause>nul & goto EDL-1)
for /f %%a in ('devcon.exe find usb* ^| find /c "Qualcomm HS-USB QDLoader 9008"') do (if %%a LSS 1 TIMEOUT /T 1 /NOBREAK>nul & goto EDL-2)
::目标设备已经检测到
if "%rechk%"=="y" (
set rechk=n
ECHO %INFO%%RESET%%BLUE%%rechk_wait%秒后将再次检查%RESET%
TIMEOUT /T %rechk_wait% /NOBREAK>nul
goto EDL-set
)
devcon.exe find usb* | find "Qualcomm HS-USB QDLoader 9008" 1>tmp\output.txt
set num=2
:EDL-3
set var=
for /f "tokens=%num% delims=()" %%a in (tmp\output.txt) do set var=%%a
if not "%var%"=="" set /a num+=1& goto EDL-3
set /a num+=-1
for /f "tokens=%num% delims=()" %%a in (tmp\output.txt) do set var=%%a
set port=%var:~3,999%
ECHO %INFO%发现9008端口！端口号为...COM%port%%RESET%
ENDLOCAL & set chkdev__edl_port=%port%& set chkdev__edl__port=%port%
del /Q /F .\tmp\output.txt
exit /b