@ECHO off
REM Copyright 2015 The Chromium Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

SETLOCAL ENABLEDELAYEDEXPANSION
FOR %%i IN ("%~dp0..") DO SET "flutter_root=%%~fi" REM Get the parent directory
SET flutter_tools_dir=%flutter_root%\packages\flutter_tools
SET snapshot_path=%flutter_root%\bin\cache\flutter_tools.snapshot
SET stamp_path=%flutter_root%\bin\cache\flutter_tools.stamp
SET script_path=%flutter_tools_dir%\bin\sky_tools.dart
REM TODO: Don't require dart to be on the user's path
SET dart=dart

REM Getting modified timestamps in a batch file is ... troublesome
REM More info: http://stackoverflow.com/questions/1687014/how-do-i-compare-timestamps-of-files-in-a-dos-batch-script
FOR %%f IN (%flutter_tools_dir%\pubspec.yaml) DO SET yamlt=%%~tf
FOR %%a IN (%flutter_tools_dir%\pubspec.lock) DO SET lockt=%%~ta
if !lockt! LSS !yamlt! (
    CD "%flutter_tools_dir%"
    CALL pub.bat get
    CD "%flutter_root%"
    IF EXIST %snapshot_path% DEL %snapshot_path%
)

REM IF doesn't have an "or". Instead, just use GOTO
FOR /f %%r IN ('git rev-parse HEAD') DO SET revision=%%r
IF NOT EXIST %snapshot_path% GOTO do_snapshot
IF NOT EXIST %stamp_path% GOTO do_snapshot
FOR /f %%r IN ('type "%stamp_path%"') DO SET stamp_value=%%r
IF (!stamp_value! NEQ !revision!) GOTO do_snapshot

GOTO :after_snapshot

:do_snapshot

CALL %dart% --snapshot="%snapshot_path%" --package-root="%flutter_tools_dir%\packages" "%script_path%"
ECHO !revision! > "%stamp_path%"

:after_snapshot

CALL %dart% "%snapshot_path%" %*

IF /I "%ERRORLEVEL%" EQU "253" (
   CALL %dart% --snapshot="%snapshot_path%" --package-root="%flutter_tools_dir%\packages" "%script_path%"
   CALL %dart% "%snapshot_path%" %*
)