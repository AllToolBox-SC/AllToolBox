%userdebug%
setlocal enabledelayedexpansion
set "command_to_run=exit /b"
set T=1
set L=100

REM 要执行的命令（参数1）
set "command_to_run=%~1"
REM 进度条预计总时长（秒，参数2）
set T=%~2
REM 进度条字符长度（参数3）
set L=%~3
REM 退格符数量（进度条总长度+余量）
set /a BSBS = L + 10

for /f %%a in ('"prompt $H&for %%b in (1) do rem"') do set "BS=%%a"

set "flagfile=progress_flag_%random%.tmp"
echo . > "%flagfile%"

start /b "" cmd /c "%command_to_run% & del /q /f %flagfile% 2>nul" >nul 2>nul

call :get_centiseconds start_cs
set /a T_cs = T * 100
set /a max_filled_before_end = L - 1

set /a filled=0
call :display_progress !filled!

:loop
    if not exist "%flagfile%" (
        set filled=%L%
        call :display_progress !filled!
        goto :end
    )

    call :get_centiseconds cur_cs
    set /a elapsed_cs = cur_cs - start_cs
    if %elapsed_cs% lss 0 set /a elapsed_cs += 24*3600*100

    set /a filled = (elapsed_cs * L) / T_cs
    if !filled! geq %L% set filled=%max_filled_before_end%

    call :display_progress !filled!

    busybox sleep 0.1 >nul 2>&1
    goto :loop

:end
echo.
exit /b

:display_progress
setlocal
set filled=%1
set "bar="
for /l %%i in (1,1,%L%) do (
    if %%i leq %filled% (set "bar=!bar!=") else set "bar=!bar! "
)
set /a percent = (filled * 100) / L

set "p=   %percent%"
set "p=!p:~-3!%%"

set "display=[!bar!] !p!"

set "backspaces="
for /l %%i in (1,1,%BSBS%) do set "backspaces=!backspaces!%BS%"

set /p="!backspaces!!display!"<nul
endlocal & goto :eof

:get_centiseconds
setlocal
set "t=%time%"
if "%t:~0,1%"==" " set "t=0%t:~1%"
set /a hour=1%t:~0,2% - 100
set /a minute=1%t:~3,2% - 100
set /a second=1%t:~6,2% - 100
set /a cent=1%t:~9,2% - 100
set /a total_centiseconds = (hour*3600 + minute*60 + second)*100 + cent
endlocal & set %1=%total_centiseconds%
goto :eof
