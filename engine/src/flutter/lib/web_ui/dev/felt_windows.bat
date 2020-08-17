:: felt_windows: a command-line utility for Windows for building and testing
:: Flutter web engine.
:: FELT stands for Flutter Engine Local Tester.

@ECHO OFF
SETLOCAL

FOR /F "tokens=1-2 delims=:" %%a in ('where gclient') DO SET GCLIENT_PATH=%%b
IF %GCLIENT_PATH%==[] (ECHO "ERROR: gclient is not in your PATH")

FOR /F "tokens=1-2 delims=:" %%a in ('where ninja') DO SET NINJA_PATH=%%b
IF %NINJA_PATH%==[] (ECHO "ERROR: ninja is not in your PATH")

SET FELT_DIR=%~dp0

:: web_ui directory is the parent of felt directory.
FOR %%a IN ("%FELT_DIR:~0,-1%") DO SET WEB_UI_DIR=%%~dpa

:: Flutter Directory is grandparent of web_ui directory.
FOR %%a IN ("%WEB_UI_DIR:~0,-1%") DO SET orTempValue=%%~dpa
FOR %%a IN ("%orTempValue:~0,-1%") DO SET FLUTTER_DIR=%%~dpa

:: Engine source directory is the parent of flutter directory.
FOR %%a IN ("%FLUTTER_DIR:~0,-1%") DO SET ENGINE_SRC_DIR=%%~dpa

SET DEV_DIR="%WEB_UI_DIR%dev"
SET OUT_DIR="%ENGINE_SRC_DIR%out"
SET HOST_DEBUG_UNOPT_DIR="%ENGINE_SRC_DIR%out\host_debug_unopt"
SET DART_SDK_DIR=%ENGINE_SRC_DIR%out\host_debug_unopt\dart-sdk
SET PUB_DIR="%DART_SDK_DIR%\bin\pub"
SET SCRIPT_PATH="%DEV_DIR%felt.dart"
SET STAMP_PATH="%DART_TOOL_DIR%felt.snapshot.stamp"
SET GN="%FLUTTER_DIR%tools\gn"
SET DART_TOOL_DIR="%WEB_UI_DIR%.dart_tool"
SET SNAPSHOT_PATH="%DART_TOOL_DIR%felt.snapshot"

:: Set revision from using git in Flutter directory.
CD %FLUTTER_DIR%
FOR /F "tokens=1 delims=:" %%a in ('git rev-parse HEAD') DO SET REVISION=%%a

:: Uncomment for debugging the values.
:: ECHO "FELT_DIR:%FELT_DIR%"
:: ECHO "WEB_UI_DIR:%WEB_UI_DIR%"
:: ECHO "FLUTTER_DIR:%FLUTTER_DIR%"
:: ECHO "ENGINE_SRC_DIR:%ENGINE_SRC_DIR%"
:: ECHO "REVISION:%REVISION%"

SET orTempValue=1
IF NOT EXIST %OUT_DIR% (SET orTempValue=0)
IF NOT EXIST %HOST_DEBUG_UNOPT_DIR% (SET orTempValue=0)
IF %orTempValue%==0 (
  ECHO "Compiling the Dart SDK."
  CALL gclient sync
  CALL python %GN% --unoptimized --full-dart-sdk
  CALL ninja -C %HOST_DEBUG_UNOPT_DIR%)

:: TODO(nurhan): The batch script does not support snanphot option.
:: Support snapshot option.
CALL :installdeps
IF %1==test (%DART_SDK_DIR%\bin\dart "%DEV_DIR%\felt.dart" %* --browser=chrome) ELSE ( %DART_SDK_DIR%\bin\dart "%DEV_DIR%\felt.dart" %* )

EXIT /B %ERRORLEVEL%

:installdeps
ECHO "Running \`pub get\` in 'engine/src/flutter/web_sdk/web_engine_tester'"
cd "%FLUTTER_DIR%web_sdk\web_engine_tester"
CALL %PUB_DIR% get
ECHO "Running \`pub get\` in 'engine/src/flutter/lib/web_ui'"
cd %WEB_UI_DIR%
CALL %PUB_DIR% get
EXIT /B 0
