@echo off
REM Workaround for machines where MSVC cl.exe has a bogus RUNASADMIN AppCompat shim.
setlocal
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" || exit /b 1
set __COMPAT_LAYER=RunAsInvoker
set PATH=C:\flutter\bin;%PATH%
cd /d "%~dp0.."
flutter build windows %*
