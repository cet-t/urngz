@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

set "CARGO_TARGET_DIR=%SCRIPT_DIR%.zig-cache\cargo-csbindgen"
cargo run --manifest-path tools\csbindgen\Cargo.toml --quiet -- %*
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" goto :fail

echo.
echo Generated C# bindings:
echo   %SCRIPT_DIR%bindings\csharp\Urngz.NativeMethods.g.cs

popd >nul
exit /b 0

:fail
popd >nul
exit /b %EXIT_CODE%