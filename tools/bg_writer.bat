@echo off
set OUTFILE=%USERPROFILE%\AllToolBox\cmd_bg_output.txt




goto looptimeout /t 1 /nobreak >nulecho %time% >> "%OUTFILE%":loop