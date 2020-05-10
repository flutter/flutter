@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
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

REM Include shared scripts in shared.bat
SET shared_bin=%FLUTTER_ROOT%/bin/internal/shared.bat
CALL "%shared_bin%"

SET flutter_tools_dir=%FLUTTER_ROOT%\packages\flutter_tools
SET cache_dir=%FLUTTER_ROOT%\bin\cache
SET snapshot_path=%cache_dir%\flutter_tools.snapshot
SET stamp_path=%cache_dir%\flutter_tools.stamp
SET script_path=%flutter_tools_dir%\bin\flutter_tools.dart
SET dart_sdk_path=%cache_dir%\dart-sdk
SET engine_stamp=%cache_dir%\engine-dart-sdk.stamp
SET engine_version_path=%FLUTTER_ROOT%\bin\internal\engine.version
SET pub_cache_path=%FLUTTER_ROOT%\.pub-cache

SET dart=%dart_sdk_path%\bin\dart.exe
SET pub=%dart_sdk_path%\bin\pub.bat

REM Chaining the call to 'dart' and 'exit' with an ampersand ensures that
REM Windows reads both commands into memory once before executing them. This
REM avoids nasty errors that may otherwise occur when the dart command (e.g. as
REM part of 'flutter upgrade') modifies this batch script while it is executing.
REM
REM Do not use the CALL command in the next line to execute Dart. CALL causes
REM Windows to re-read the line from disk after the CALL command has finished
REM regardless of the ampersand chain.
"%dart%" %* & exit /B !ERRORLEVEL!

:final_exit
EXIT /B %exit_code%
