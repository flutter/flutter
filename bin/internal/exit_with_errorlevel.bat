@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM A script to exit caller script with the last status code.
REM This can be used with ampersand without `SETLOCAL ENABLEDELAYEDEXPANSION`.
REM
REM To use this script like `exit`, do not use with the CALL command.
REM Without CALL, this script can exit caller script, but with CALL,
REM this script returns back to caller and does not exit caller.

exit /B %ERRORLEVEL%
