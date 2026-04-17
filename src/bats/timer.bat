::  call timer start           开始计时
::  call timer end [变量名]    结束计时，输出 HH:MM:SS.mmm 

if /i "%1"=="start" goto do_start
if /i "%1"=="end"   goto do_end
goto :eof

:do_start
setlocal
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "_hour=100%%a %% 100, _min=100%%b %% 100, _sec=100%%c %% 100, _cs=100%%d %% 100"
    set /a "TIMER_START_MS=((_hour*3600 + _min*60 + _sec)*1000 + _cs*10)"
)
endlocal & set TIMER_START_MS=%TIMER_START_MS%
goto :eof

:do_end
setlocal enabledelayedexpansion
if not defined TIMER_START_MS endlocal & exit /b 1

for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "_hour=100%%a %% 100, _min=100%%b %% 100, _sec=100%%c %% 100, _cs=100%%d %% 100"
    set /a "_END_MS=((_hour*3600 + _min*60 + _sec)*1000 + _cs*10)"
)
set /a "_ELAPSED=_END_MS - TIMER_START_MS"
if !_ELAPSED! lss 0 set /a "_ELAPSED+=24*60*60*1000"

set /a "_H=_ELAPSED / 3600000"
set /a "_M=(_ELAPSED %% 3600000) / 60000"
set /a "_S=(_ELAPSED %% 60000) / 1000"
set /a "_MS=_ELAPSED %% 1000"

if !_H! lss 10 set "_H=0!_H!"
if !_M! lss 10 set "_M=0!_M!"
if !_S! lss 10 set "_S=0!_S!"
if !_MS! lss 100 set "_MS=0!_MS!"
if !_MS! lss 10 set "_MS=0!_MS!"

set "_TIME_STR=!_H!:!_M!:!_S!.!_MS!"

for /f "delims=" %%a in ("!_TIME_STR!") do endlocal & set "%~2=%%a" & set "TIMER_START_MS="
goto :eof