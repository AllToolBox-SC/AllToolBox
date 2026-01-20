@echo off
chcp 65001
set PYTHONUTF8=1

set PYTHON=python
if exist .\.venv312\Scripts\python.exe set PYTHON=.\.venv312\Scripts\python.exe
if exist .\.venv\Scripts\python.exe set PYTHON=.\.venv\Scripts\python.exe

"%PYTHON%" -m pip install -r requirements.txt
"%PYTHON%" build.py %*
pause
