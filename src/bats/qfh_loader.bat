:run
qfh_loader.exe %1 %2 %3 %4 %5 %6 %7 %8 %9 >FHtmp.txt || goto error

:error
copy /Y .\FHtmp.txt .\Errorlog\FHerror_%date%_%time%.txt
set /p FHtmp=%error%读取或刷入失败！[输入"l"输出日志]按任意键重新尝试...
if "FHtmp"=="l" type FHtmp.txt & echo.按任意键重试... & pause >nul
goto run