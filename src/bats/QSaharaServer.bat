:run
QSaharaServer.exe %1 %2 %3 %4 %5 %6 %7 %8 %9 >QStmp.txt || goto error

:error
IF NOT EXIST ".\Errorlog" (
	md ".\Errorlog"
)
set date_tmp=%date:~0,10%
set datetime=%date_tmp:/=%%time:~0,2%%time:~3,2%%time:~6,2%
copy /Y .\QStmp.txt .\Errorlog\QSerror_%datetime%.txt
set /p QStmp=%error%引导失败！[输入"l"输出日志]按任意键重新尝试...
if "QStmp"=="l" type QStmp.txt & echo.按任意键重试... & pause >nul
goto run