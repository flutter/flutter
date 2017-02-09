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
SET snapshot_path=%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot
SET stamp_path=%FLUTTER_ROOT%\bin\cache\flutter_tools.stamp
SET script_path=%flutter_tools_dir%\bin\flutter_tools.dart
SET dart_sdk_path=%FLUTTER_ROOT%\bin\cache\dart-sdk

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
  IF NOT EXIST "%snapshot_path%" GOTO do_snapshot
  IF NOT EXIST "%stamp_path%" GOTO do_snapshot
  SET /p stamp_value=<"%stamp_path%"
  IF !stamp_value! NEQ !revision! GOTO do_snapshot
  REM Get modified timestamps
  FOR %%f IN ("%flutter_tools_dir%\pubspec.yaml") DO SET yamlt=%%~tf
  FOR %%a IN ("%flutter_tools_dir%\pubspec.lock") DO SET lockt=%%~ta
  IF !lockt! LSS !yamlt! GOTO do_snapshot

  REM Everything is uptodate - exit subroutine
  EXIT /B

  :do_snapshot
    MKDIR "%FLUTTER_ROOT%\bin\cache" 2> NUL
    ECHO: > "%FLUTTER_ROOT%\bin\cache\.dartignore"

    ECHO Checking Dart SDK version...
    CALL PowerShell.exe -ExecutionPolicy Bypass -Command "& '%FLUTTER_ROOT%/bin/internal/update_dart_sdk.ps1'"

    ECHO Updating flutter tool...
    PUSHD "%flutter_tools_dir%"
    CALL "%pub%" upgrade --verbosity=error --no-packages-dir
    POPD
    CALL "%dart%" --snapshot="%snapshot_path%" --packages="%flutter_tools_dir%\.packages" "%script_path%"
    >"%stamp_path%" ECHO %revision%

  REM Exit Subroutine
  EXIT /B

:after_subroutine

CALL "%dart%" %FLUTTER_TOOL_ARGS% "%snapshot_path%" %*
SET exit_code=%ERRORLEVEL%

REM The VM exits with code 253 if the snapshot version is out-of-date.
IF /I "%exit_code%" EQU "253" (
  CALL "%dart%" --snapshot="%snapshot_path%" --packages="%flutter_tools_dir%\.packages" "%script_path%"
  CALL "%dart%" %FLUTTER_TOOL_ARGS% "%snapshot_path%" %*
  SET exit_code=%ERRORLEVEL%
)

EXIT /B %exit_code%
