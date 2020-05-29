@echo off

set FLUTTER_CACHE_DIR=%~1
set BUNDLE_DIR=%~2
set PLUGIN_DIR=%~3
set EXE_NAME=%~4
set BUILD_MODE=%~5

set DATA_DIR=%BUNDLE_DIR%data

if not exist "%DATA_DIR%" call mkdir "%DATA_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Write the executable name to the location expected by the Flutter tool.
echo %EXE_NAME%>"%FLUTTER_CACHE_DIR%exe_filename"

:: Copy the Flutter assets to the data directory.
set FLUTTER_BUILD_DIR=%~dp0..\..\build\
set ASSET_DIR_NAME=flutter_assets
set TARGET_ASSET_DIR=%DATA_DIR%\%ASSET_DIR_NAME%
if exist "%TARGET_ASSET_DIR%" call rmdir /s /q "%TARGET_ASSET_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
call xcopy /s /e /i /q "%FLUTTER_BUILD_DIR%%ASSET_DIR_NAME%" "%TARGET_ASSET_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy the icudtl.dat file from the Flutter tree to the data directory.
call xcopy /y /d /q "%FLUTTER_CACHE_DIR%icudtl.dat" "%DATA_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: For non-debug modes, copy app.so into the data directory.
if not %BUILD_MODE% == "Debug" (
  call xcopy /y /d /q "%FLUTTER_BUILD_DIR%windows\app.so" "%DATA_DIR%"
  if %errorlevel% neq 0 exit /b %errorlevel%
)

:: Copy the Flutter DLL to the target location.
call xcopy /y /d /q "%FLUTTER_CACHE_DIR%flutter_windows.dll" "%BUNDLE_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy any Plugin DLLs to the target location.
if exist "%PLUGIN_DIR%" (
  call xcopy /y /d /q "%PLUGIN_DIR%"*.dll "%BUNDLE_DIR%"
  if %errorlevel% neq 0 exit /b %errorlevel%
)
