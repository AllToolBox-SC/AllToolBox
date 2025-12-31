:run
QSaharaServer.exe %1 %2 %3 %4 %5 %6 %7 %8 %9 >QStmp.txt || goto error

:error
copy /Y .\QStmp.txt .\Errorlog\QSerror_%date%_%time%.txt
set /p QStmp=%error%引导失败！[输入"l"输出日志]按任意键重新尝试...
if "QStmp"=="l" type QStmp.txt & echo.按任意键重试... & pause >nul
goto run