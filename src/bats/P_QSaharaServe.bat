del /q /f qs_error.txt >nul 2>nul
:run
QSaharaServer.exe %* >QStmp.txt || goto error
exit /b
:error
copy /Y .\QStmp.txt .\logs\QSerror_%RANDOM%%RANDOM%.txt >nul
echo. > qs_error.txt
exit /b 1
