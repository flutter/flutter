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
SET DART_SDK_DIR=%HOST_DEBUG_UNOPT_DIR%\dart-sdk
SET DART_BIN=%DART_SDK_DIR%\bin\dart
SET PUB_BIN=%DART_SDK_DIR%\bin\pub
SET FLUTTER_DIR=%ENGINE_SRC_DIR%\flutter
SET WEB_UI_DIR=%FLUTTER_DIR%\lib\web_ui
SET DEV_DIR=%WEB_UI_DIR%\dev
SET FELT_PATH=%DEV_DIR%\felt.dart
SET DART_TOOL_DIR=%WEB_UI_DIR%\.dart_tool
SET SNAPSHOT_PATH=%DART_TOOL_DIR%\felt.snapshot

SET needsHostDebugUnoptRebuild=0
for %%x in (%*) do (
  if ["%%~x"]==["--clean"] (
    ECHO Clean rebuild requested
    SET needsHostDebugUnoptRebuild=1
  )
)

IF NOT EXIST %OUT_DIR% (SET needsHostDebugUnoptRebuild=1)
IF NOT EXIST %HOST_DEBUG_UNOPT_DIR% (SET needsHostDebugUnoptRebuild=1)

IF %needsHostDebugUnoptRebuild%==1 (
  ECHO Building host_debug_unopt
  :: Delete old snapshot, if any, because the new Dart SDK may invalidate it.
  IF EXIST "%SNAPSHOT_PATH%" (
    del %SNAPSHOT_PATH%
  )
  CALL gclient sync -D
  CALL python %GN% --unoptimized --full-dart-sdk
  CALL ninja -C %HOST_DEBUG_UNOPT_DIR%)

cd %WEB_UI_DIR%
IF NOT EXIST "%SNAPSHOT_PATH%" (
  ECHO Precompiling felt snapshot
  CALL %PUB_BIN% get
  %DART_BIN% --snapshot="%SNAPSHOT_PATH%" --packages="%WEB_UI_DIR%\.dart_tool\package_config.json" %FELT_PATH%
)

IF %1==test (
  %DART_SDK_DIR%\bin\dart --packages="%WEB_UI_DIR%\.dart_tool\package_config.json" "%SNAPSHOT_PATH%" %* --browser=chrome
) ELSE (
  %DART_SDK_DIR%\bin\dart --packages="%WEB_UI_DIR%\.dart_tool\package_config.json" "%SNAPSHOT_PATH%" %*
)

EXIT /B %ERRORLEVEL%
