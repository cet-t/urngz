@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

set "BUILD_CMD=zig build dll -Doptimize=ReleaseFast %*"
echo %* | findstr /I /C:"-Doptimize=" >nul
if not errorlevel 1 set "BUILD_CMD=zig build dll %*"

echo Building DLL with command:
echo   %BUILD_CMD%
%BUILD_CMD%
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" goto :fail

call "%SCRIPT_DIR%build_csbindgen.bat"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" goto :fail

echo.
echo Built DLL:
echo   %SCRIPT_DIR%zig-out\bin\urngz_cabi.dll
echo Import library:
echo   %SCRIPT_DIR%zig-out\lib\urngz_cabi.lib
echo C header:
echo   %SCRIPT_DIR%zig-out\include\urngz_cabi.h
echo C# bindings:
echo   %SCRIPT_DIR%bindings\csharp\Urngz.NativeMethods.g.cs

popd >nul
exit /b 0

:fail
popd >nul
exit /b %EXIT_CODE%