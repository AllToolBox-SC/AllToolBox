@echo off
chcp 65001
python -m pip install -r requirements.txt
python build.py
pause
