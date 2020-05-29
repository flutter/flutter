@echo off

:: Run flutter tool backend.
set BUILD_MODE=%~1
"%FLUTTER_ROOT%\packages\flutter_tools\bin\tool_backend" windows-x64 %BUILD_MODE%
