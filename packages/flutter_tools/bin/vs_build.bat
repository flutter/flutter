@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM Calls vcvars64.bat to configure a command-line build environment, then builds
REM a project with msbuild.
@echo off

set VCVARS=%~1
set PROJECT=%~2
set CONFIG=%~3

call "%VCVARS%"
if %errorlevel% neq 0 exit /b %errorlevel%

msbuild "%PROJECT%" /p:Configuration=%CONFIG%
