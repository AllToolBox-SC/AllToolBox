# Batch 脚本开发指南

本文档面向在本仓库中编写、调试和发布 Windows batch 文件（.bat）的开发者，包含约定、模板、调试与 CI/发布建议，以及常见示例。适用范围：`src/bats/` 下的工具脚本、仓库根目录的便捷脚本与 `tools/` 中的辅助脚本。

**仓库示例（参考）**
- 根脚本示例：[ezbuild.bat](ezbuild.bat#L1)、[clean.bat](clean.bat#L1)
- 批量工具目录：主要脚本位于 [src/bats/](src/bats/backup.bat#L1)（示例：`backup.bat`、`listbuild.bat`、`adbdevice.bat`）
- 辅助脚本：[tools/bg_writer.bat](tools/bg_writer.bat#L1)
- 打包流程：见 [build.py](build.py)

**目标与原则**
- 清晰：每个脚本顶部注释用途、使用示例与参数说明。
- 可复用：把复杂逻辑写在可复用脚本/函数（标签 + `call`）中。
- 安全：使用 `setlocal`/`endlocal`，避免影响全局环境。
- 可测试：脚本应该在无用户交互下可由 CI 或手动运行并输出机器可读日志。

**推荐脚本模板**
```bat
@echo off
rem MyScript.bat - 简短描述
setlocal EnableExtensions EnableDelayedExpansion
pushd %~dp0

rem Usage: MyScript.bat [--help] [args]
if "%~1"=="--help" (
  echo Usage: MyScript.bat [options]
  echo   --help   Show this help
  popd
  endlocal
  exit /b 0
)

rem 参数解析示例
:parse_args
if "%~1"=="" goto :main
if "%~1"=="--flag" (
  set FLAG=1
  shift
  goto :parse_args
)
shift
goto :parse_args

:main
rem 主逻辑在此
if defined FLAG echo Flag enabled

endlocal
popd
exit /b 0
```

要点说明：
- 使用 `%~dp0` 获得脚本所在目录（便于调用同目录下的其他工具）。
- 在脚本内用 `%%i`（双百分号）作为 `for` 循环变量；交互命令行中用单 `%i`。
- 延迟展开：在需要在循环或条件中修改并读取变量时使用 `setlocal EnableDelayedExpansion` 并用 `!VAR!` 访问。
- 退出码：使用 `exit /b %ERRORLEVEL%` 或 `exit /b N` 明确返回给调用者。

**参数与输出约定**
- 支持 `--help` 输出使用帮助并返回 `0`。
- 对错误返回非零（避免只 `echo` 错误而返回 0）。
- 所有长期运行或关键操作写入日志：
```bat
call "%~dp0\tool.exe" %* >> "%~dp0\logs\tool.log" 2>>&1
if errorlevel 1 exit /b %errorlevel%
```

**调试与本地测试**
- 临时开启回显：`@echo on` 或在命令行中运行 `cmd /V:ON /E:ON /C "path\to\script.bat"` 以启用延迟展开并观察行为。 
- 用 `echo` 打印关键变量和路径，或在关键位置插入 `pause` 暂停以人工检查。
- 将输出重定向到文件以便回溯和 CI 比对：
```powershell
# PowerShell / CI 环境下运行示例
cmd /c "src\bats\listbuild.bat --list" > build-list.log 2>&1
```

**常见陷阱与建议**
- 不要在脚本中假设当前工作目录，始终使用 `%~dp0` 切到脚本目录（`pushd %~dp0`）。
- 小心 `%`、`!` 与 `^` 的转义规则；在需要嵌套变量时优先使用延迟展开。
- 使用 `goto :eof` 或 `exit /b` 来结束函数/脚本，避免 fall-through 导致意外执行。
- 对于危险命令（例如 `del /s /q`）先在日志中显示将要删除的文件列表，再执行删除；最好提供 `--dry-run`。

**CI / 打包与发布**
- 本仓库使用 Python 打包脚本（见 [build.py](build.py)）将若干入口脚本打包为可执行文件（exe）；在改动入口脚本前请参照打包映射与测试打包产物。 
- 受保护分支策略（签名提交、禁止强推等）可能存在：在提交大量改写或历史变更前先创建分支并通过 PR 流程合并。

**提交与分支建议**
- 文档/脚本变更建议在独立分支完成并发起 PR：
```powershell
git checkout -b docs/batch-dev-YYYYMMDD
git add docs/batch-development.md
git commit -m "docs: add batch development guide"
git push -u origin docs/batch-dev-YYYYMMDD
```

**速查（Cheat sheet）**
- `%~dp0` — 脚本目录
- `%~nx0` — 脚本名（带扩展）
- `%%i` — `for` 循环变量（脚本内）
- `!VAR!` — 延迟展开变量（需 `EnableDelayedExpansion`）
- `call` — 调用另一个批处理并返回
- `goto :label` / `:label` — 标签跳转

---

如需，我可以：
- 把本文档提交到新分支并创建 PR（我将以当前时间戳命名分支）；
- 将仓库中更具体的脚本片段加入示例（请指定要引用的脚本）。
