
aria2c.exe --console-log-level=error --summary-interval=0 --check-certificate=false --max-connection-per-server=8 --split=8 --continue=true --user-agent="pan.baidu.com" %* 2>nul
set "errorcode=%errorlevel%"
exit /b %errorcode%