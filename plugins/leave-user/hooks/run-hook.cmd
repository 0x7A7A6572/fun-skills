: << 'CMDBLOCK'
@echo off
REM 跨平台 polyglot 包装器，用于 hook 脚本。
REM Windows: cmd.exe 执行 batch 部分，查找并调用 bash。
REM Unix: shell 解释为脚本（: 在 bash 中是 no-op）。
REM
REM 用法: run-hook.cmd <script-name> [args...]

if "%~1"=="" (
    echo run-hook.cmd: 缺少脚本名称 >&2
    exit /b 1
)

set "HOOK_DIR=%~dp0"

REM 尝试标准位置的 Git for Windows bash
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM 尝试 PATH 中的 bash（用户安装的 Git Bash、MSYS2、Cygwin）
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM 未找到 bash — 静默退出
exit /b 0
CMDBLOCK

# Unix: 直接运行指定脚本
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
