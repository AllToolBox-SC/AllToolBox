:: encoding: gbk
:: 若要强制忽略路径中的空格问题和跳过系统检查，请设置环境变量 ATB_IGNORE_SPACE_IN_PATH=1 ATB_SKIP_PLATFORM_CHECK=1
:: 或将本文件拷贝至工具箱根目录，以管理员身份运行
@echo off
setlocal enabledelayedexpansion
set ATB_IGNORE_SPACE_IN_PATH=1
set ATB_SKIP_PLATFORM_CHECK=1
cd bin
call main.exe
