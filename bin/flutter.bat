@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM ---------------------------------- NOTE ----------------------------------
REM
REM Please keep the logic in this file consistent with the logic in the
REM `flutter` script in the same directory to ensure that Flutter & Dart continue to
REM work across all platforms!
REM
REM --------------------------------------------------------------------------

SETLOCAL ENABLEDELAYEDEXPANSION

REM To debug the tool, you can uncomment the following line to enable debug mode:
REM SET FLUTTER_TOOL_ARGS="--enable-asserts %FLUTTER_TOOL_ARGS%"

FOR %%i IN ("%~dp0..") DO SET FLUTTER_ROOT=%%~fi

REM If available, add location of bundled mingit to PATH
SET mingit_path=%FLUTTER_ROOT%\bin\mingit\cmd
IF EXIST "%mingit_path%" SET PATH=%PATH%;%mingit_path%

REM Test if Git is available on the Host
where /q git || ECHO Error: Unable to find git in your PATH. && EXIT /B 1
REM  Test if the flutter directory is a git clone, otherwise git rev-parse HEAD would fail
IF NOT EXIST "%flutter_root%\.git" (
  ECHO Error: The Flutter directory is not a clone of the GitHub project.
  ECHO        The flutter tool requires Git in order to operate properly;
  ECHO        to set up Flutter, run the following command:
  ECHO        git clone -b stable https://github.com/flutter/flutter.git
  EXIT 1
)

REM Include shared scripts in shared.bat
SET shared_bin=%FLUTTER_ROOT%\bin\internal\shared.bat
CALL "%shared_bin%"

SET flutter_tools_dir=%FLUTTER_ROOT%\packages\flutter_tools
SET cache_dir=%FLUTTER_ROOT%\bin\cache
SET snapshot_path=%cache_dir%\flutter_tools.snapshot
SET dart_sdk_path=%cache_dir%\dart-sdk
SET dart=%dart_sdk_path%\bin\dart.exe

REM Chaining the call to 'dart' and 'exit' with an ampersand ensures that
REM Windows reads both commands into memory once before executing them. This
REM avoids nasty errors that may otherwise occur when the dart command (e.g. as
REM part of 'flutter upgrade') modifies this batch script while it is executing.
REM
REM Do not use the CALL command in the next line to execute Dart. CALL causes
REM Windows to re-read the line from disk after the CALL command has finished
REM regardless of the ampersand chain.
"%dart%" --disable-dart-dev --packages="%flutter_tools_dir%\.dart_tool\package_config.json" %FLUTTER_TOOL_ARGS% "%snapshot_path%" %* & exit /B !ERRORLEVEL!
