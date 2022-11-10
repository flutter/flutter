:: felt: a command-line utility for Windows for building and testing
:: Flutter web engine.
:: FELT stands for Flutter Engine Local Tester.

@ECHO OFF
SETLOCAL

:: Make sure gclient and ninja exist. Otherwise felt won't work.
FOR /F "tokens=1-2 delims=:" %%a in ('where gclient') DO SET GCLIENT_PATH=%%b
IF %GCLIENT_PATH%==[] (ECHO "ERROR: gclient is not in your PATH")

FOR /F "tokens=1-2 delims=:" %%a in ('where ninja') DO SET NINJA_PATH=%%b
IF %NINJA_PATH%==[] (ECHO "ERROR: ninja is not in your PATH")

:: Starting from this script's path, walk up to engine source directory.
SET SCRIPT_DIR=%~dp0
FOR %%a IN ("%SCRIPT_DIR:~0,-1%") DO SET TMP=%%~dpa
FOR %%a IN ("%TMP:~0,-1%") DO SET TMP=%%~dpa
FOR %%a IN ("%TMP:~0,-1%") DO SET TMP=%%~dpa
FOR %%a IN ("%TMP:~0,-1%") DO SET ENGINE_SRC_DIR=%%~dpa

SET ENGINE_SRC_DIR=%ENGINE_SRC_DIR:~0,-1%
SET OUT_DIR=%ENGINE_SRC_DIR%\out
SET HOST_DEBUG_UNOPT_DIR=%OUT_DIR%\host_debug_unopt
SET FLUTTER_DIR=%ENGINE_SRC_DIR%\flutter
SET WEB_UI_DIR=%FLUTTER_DIR%\lib\web_ui
SET DEV_DIR=%WEB_UI_DIR%\dev
SET FELT_PATH=%DEV_DIR%\felt.dart
SET DART_TOOL_DIR=%WEB_UI_DIR%\.dart_tool
SET SNAPSHOT_PATH=%DART_TOOL_DIR%\felt.snapshot
SET SDK_PREBUILTS_DIR=%FLUTTER_DIR%\prebuilts
SET PREBUILT_TARGET=windows-x64
IF NOT DEFINED DART_SDK_DIR (
  SET DART_SDK_DIR=%SDK_PREBUILTS_DIR%\%PREBUILT_TARGET%\dart-sdk
)
SET DART_BIN=%DART_SDK_DIR%\bin\dart

cd %WEB_UI_DIR%

IF FELT_USE_SNAPSHOT=="0" (
  ECHO Invoking felt.dart without snapshot
  SET FELT_TARGET=%FELT_PATH%
) ELSE (
  IF NOT EXIST "%SNAPSHOT_PATH%" (
    ECHO Precompiling felt snapshot
    CALL %DART_BIN% pub get
    %DART_BIN% --snapshot="%SNAPSHOT_PATH%" --packages="%WEB_UI_DIR%\.dart_tool\package_config.json" %FELT_PATH%
  )
  SET FELT_TARGET=%SNAPSHOT_PATH%
  ECHO Invoking felt snapshot
)

%DART_BIN% --packages="%WEB_UI_DIR%\.dart_tool\package_config.json" "%FELT_TARGET%" %*

EXIT /B %ERRORLEVEL%
