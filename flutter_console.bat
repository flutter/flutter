@echo off
REM Copyright 2017 The Chromium Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

TITLE Flutter Console

echo.
echo          ######## ##       ##     ## ######## ######## ######## ########
echo          ##       ##       ##     ##    ##       ##    ##       ##     ##
echo          ##       ##       ##     ##    ##       ##    ##       ##     ##
echo          ######   ##       ##     ##    ##       ##    ######   ########
echo          ##       ##       ##     ##    ##       ##    ##       ##   ##
echo          ##       ##       ##     ##    ##       ##    ##       ##    ##
echo          ##       ########  #######     ##       ##    ######## ##     ##
echo.
echo.

echo  WELCOME to the Flutter Console.
echo  ================================================================================
echo.
echo  Use the console below this message to interact with the "flutter" command.
echo  Run "flutter doctor" to check if your system is ready to run Flutter apps.
echo  Run "flutter create <app_name>" to create a new Flutter project.
echo.
echo  Run "flutter help" to see all available commands.
echo.
echo  Want to use an IDE to interact with Flutter? https://flutter.dev/ide-setup/
echo.
echo  Want to run the "flutter" command from any Command Prompt or PowerShell window?
echo  Add Flutter to your PATH: https://flutter.dev/setup-windows/#update-your-path
echo.
echo  ================================================================================

REM "%~dp0" is the directory of this file including trailing backslash
SET PATH=%~dp0bin;%PATH%

CALL cmd /K "@echo off & cd %USERPROFILE% & echo on"
