@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM This should match the ci.sh file in this directory.

REM This is called from the LUCI recipes:
REM https://github.com/flutter/flutter/blob/main/dev/bots/suite_runners/run_customer_testing_tests.dart

ECHO.
ECHO Updating pub packages...
CALL dart pub get
CD ..\tools
CALL dart pub get
CD ..\customer_testing

ECHO.
ECHO Finding correct version of customer tests...
CMD /S /C "IF EXIST "..\..\bin\cache\pkg\tests\" RMDIR /S /Q ..\..\bin\cache\pkg\tests"
git clone https://github.com/flutter/tests.git ..\..\bin\cache\pkg\tests
FOR /F "usebackq tokens=*" %%a IN (`dart --enable-asserts ..\tools\bin\find_commit.dart . master ..\..\bin\cache\pkg\tests main`) DO git -C ..\..\bin\cache\pkg\tests checkout %%a

ECHO.
ECHO Running tests...
CD ..\..\bin\cache\pkg\tests
CALL dart --enable-asserts ..\..\..\..\dev\customer_testing\run_tests.dart --verbose --skip-on-fetch-failure --skip-template registry/*.test
