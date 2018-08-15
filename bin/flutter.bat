@ECHO off
REM Copyright 2017 The Chromium Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM This wrapper script copies the actual launch script from internal/ to cache/
REM and then executes the copy in cache/. Copying is necessary to prevent
REM Flutter from modifying the script while it is executing during a
REM "flutter upgrade" or "flutter channel" command. Modifying the script
REM mid-execution would cause Windows to throw errors.

SETLOCAL ENABLEDELAYEDEXPANSION

FOR %%i IN ("%~dp0..") DO SET FLUTTER_ROOT=%%~fi
SET cache_dir=%FLUTTER_ROOT%\bin\cache
SET script_src=%FLUTTER_ROOT%\bin\internal\run_flutter.bat
SET script_dest=%cache_dir%\run_flutter.bat

IF NOT EXIST "%cache_dir%" MKDIR "%cache_dir%"

COPY "%script_src%" "%script_dest%" 1>NUL
"%script_dest%" %*
REM The call above REPLACES this process with the cache\run_flutter.bat process.
