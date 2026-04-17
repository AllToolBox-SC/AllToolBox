:run
qfh_loader.exe %* >qfhtmp.txt || goto error
exit /b
:error
copy /Y .\qfhtmp.txt .\logs\qfherror_%RANDOM%%RANDOM%.txt >nul

echo %error%9008重启失败！已跳过，可能需要手动按10秒电源键重启

