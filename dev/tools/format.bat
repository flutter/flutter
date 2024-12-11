@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

SETLOCAL ENABLEDELAYEDEXPANSION

FOR %%i IN ("%~dp0..\..") DO SET FLUTTER_ROOT=%%~fi

REM Test if Git is available on the Host
where /q git || ECHO Error: Unable to find git in your PATH. && EXIT /B 1

SET tools_dir=%FLUTTER_ROOT%\dev\tools

SET dart=%FLUTTER_ROOT%\bin\dart.exe

cd "%tools_dir%"

REM Do not use the CALL command in the next line to execute Dart. CALL causes
REM Windows to re-read the line from disk after the CALL command has finished
REM regardless of the ampersand chain.
"%dart%" pub get || exit /B !ERRORLEVEL!
"%dart%" bin\format.dart %* & exit /B !ERRORLEVEL!
