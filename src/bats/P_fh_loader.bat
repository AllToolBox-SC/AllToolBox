del /q /f fh_error.txt >nul 2>nul
:run
fh_loader.exe %* >FHtmp.txt || goto error
exit /b
:error
copy /Y .\FHtmp.txt .\logs\FHerror_%RANDOM%%RANDOM%.txt >nul
echo. > fh_error.txt
exit /b 1
