@ECHO off
REM Copyright 2017 The Chromium Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.


REM ---------------------------------- NOTE ----------------------------------
REM
REM Please keep the logic in this file consistent with the logic in the
REM `flutter` script in the same directory to ensure that Flutter continues to
REM work across all platforms!
REM
REM --------------------------------------------------------------------------

SETLOCAL ENABLEDELAYEDEXPANSION

FOR %%i IN ("%~dp0..") DO SET FLUTTER_ROOT=%%~fi

SET flutter_tools_dir=%FLUTTER_ROOT%\packages\flutter_tools
SET cache_dir=%FLUTTER_ROOT%\bin\cache
SET snapshot_path=%cache_dir%\flutter_tools.snapshot
SET stamp_path=%cache_dir%\flutter_tools.stamp
SET script_path=%flutter_tools_dir%\bin\flutter_tools.dart
SET dart_sdk_path=%cache_dir%\dart-sdk
SET dart_stamp_path=%cache_dir%\dart-sdk.stamp
SET dart_version_path=%FLUTTER_ROOT%\bin\internal\dart-sdk.version

SET dart=%dart_sdk_path%\bin\dart.exe
SET pub=%dart_sdk_path%\bin\pub.bat

REM Test if Git is available on the Host
where /q git || ECHO Error: Unable to find git in your PATH. && EXIT /B 1
REM  Test if the flutter directory is a git clone, otherwise git rev-parse HEAD would fail
IF NOT EXIST "%flutter_root%\.git" (
  ECHO Error: The Flutter directory is not a clone of the GitHub project.
  EXIT /B 1
)

REM Ensure that bin/cache exists.
IF NOT EXIST "%cache_dir%" MKDIR "%cache_dir%"

REM To debug the tool, you can uncomment the following line to enable checked mode and set an observatory port:
REM SET FLUTTER_TOOL_ARGS="--observe=65432 --checked"

:acquire_lock
2>NUL (
  REM "3" is now stderr because of "2>NUL".
  CALL :subroutine %* 2>&3 9> "%cache_dir%\flutter.bat.lock" || GOTO acquire_lock
)
GOTO :after_subroutine

:subroutine
  PUSHD "%flutter_root%"
  FOR /f %%r IN ('git rev-parse HEAD') DO SET revision=%%r
  POPD

  REM The following IF conditions are all linked with a logical OR. However,
  REM there is no OR operator in batch and a GOTO construct is used as replacement.

  IF NOT EXIST "%dart_stamp_path%" GOTO do_sdk_update_and_snapshot
  SET /P dart_required_version=<"%dart_version_path%"
  SET /P dart_installed_version=<"%dart_stamp_path%"
  IF !dart_required_version! NEQ !dart_installed_version! GOTO do_sdk_update_and_snapshot
  IF NOT EXIST "%snapshot_path%" GOTO do_snapshot
  IF NOT EXIST "%stamp_path%" GOTO do_snapshot
  SET /P stamp_value=<"%stamp_path%"
  IF !stamp_value! NEQ !revision! GOTO do_snapshot
  REM Compare "last modified" timestamps
  SET pubspec_yaml_path=%flutter_tools_dir%\pubspec.yaml
  SET pubspec_lock_path=%flutter_tools_dir%\pubspec.lock
  FOR %%i IN ("%pubspec_yaml_path%") DO SET yaml_timestamp=%%~ti
  FOR %%i IN ("%pubspec_lock_path%") DO SET lock_timestamp=%%~ti
  IF !yaml_timestamp! EQU !lock_timestamp! GOTO do_snapshot
  FOR /F %%i IN ('DIR /B /O:D "%pubspec_yaml_path%" "%pubspec_lock_path%"') DO SET newer_file=%%i
  IF "%newer_file%" EQU "pubspec.yaml" GOTO do_snapshot

  REM Everything is uptodate - exit subroutine
  EXIT /B

  :do_sdk_update_and_snapshot
    ECHO Checking Dart SDK version...
    CALL PowerShell.exe -ExecutionPolicy Bypass -Command "& '%FLUTTER_ROOT%/bin/internal/update_dart_sdk.ps1'"
    IF "%ERRORLEVEL%" NEQ "0" (
      ECHO Error: Unable to update Dart SDK. Retrying...
      timeout /t 5 /nobreak
      GOTO :do_sdk_update_and_snapshot
    )

  :do_snapshot
    ECHO: > "%cache_dir%\.dartignore"
    ECHO Updating flutter tool...
    PUSHD "%flutter_tools_dir%"

    REM Makes changes to PUB_ENVIRONMENT only visible to commands within SETLOCAL/ENDLOCAL
    SETLOCAL
      IF "%TRAVIS%" == "true" GOTO on_bot
      IF "%BOT%" == "true" GOTO on_bot
      IF "%CONTINUOUS_INTEGRATION%" == "true" GOTO on_bot
      IF "%CHROME_HEADLESS%" == "1" GOTO on_bot
      IF "%APPVEYOR%" == "true" GOTO on_bot
      IF "%CI%" == "true" GOTO on_bot
      GOTO not_on_bot
      :on_bot
        SET PUB_ENVIRONMENT=%PUB_ENVIRONMENT%:flutter_bot
      :not_on_bot
      SET PUB_ENVIRONMENT=%PUB_ENVIRONMENT%:flutter_install
      :retry_pub_upgrade
      CALL "%pub%" upgrade --verbosity=error --no-packages-dir
      IF "%ERRORLEVEL%" NEQ "0" (
        ECHO Error: Unable to 'pub upgrade' flutter tool. Retrying...
        timeout /t 5 /nobreak
        GOTO :retry_pub_upgrade
      )
    ENDLOCAL

    POPD

    :retry_dart_snapshot
    CALL "%dart%" --snapshot="%snapshot_path%" --packages="%flutter_tools_dir%\.packages" "%script_path%"
    IF "%ERRORLEVEL%" NEQ "0" (
      ECHO Error: Unable to create dart snapshot for flutter tool. Retrying...
      timeout /t 5 /nobreak
      GOTO :retry_dart_snapshot
    )
    >"%stamp_path%" ECHO %revision%

  REM Exit Subroutine
  EXIT /B

:after_subroutine

CALL "%dart%" %FLUTTER_TOOL_ARGS% "%snapshot_path%" %*
SET exit_code=%ERRORLEVEL%

REM The VM exits with code 253 if the snapshot version is out-of-date.
IF "%exit_code%" EQU "253" (
  CALL "%dart%" --snapshot="%snapshot_path%" --packages="%flutter_tools_dir%\.packages" "%script_path%"
  SET exit_code=%ERRORLEVEL%
  IF "%exit_code%" EQU "253" (
    ECHO Error: Unable to create dart snapshot for flutter tool.
    EXIT /B %exit_code%
  )
  CALL "%dart%" %FLUTTER_TOOL_ARGS% "%snapshot_path%" %*
  SET exit_code=%ERRORLEVEL%
)

EXIT /B %exit_code%
