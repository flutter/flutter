:: Copyright 2018 The Chromium Authors. All rights reserved.
:: Use of this source code is governed by a BSD-style license that can be
:: found in the LICENSE file.

:: Calls vcvars64.bat to configure a command-line build environment, then builds
:: a project with msbuild.
@echo off

set VCVARS=%~1
set PROJECT=%~2
set CONFIG=%~3

call "%VCVARS%"
if %errorlevel% neq 0 exit /b %errorlevel%

msbuild "%PROJECT%" /p:Configuration=%CONFIG%
