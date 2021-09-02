@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM This should match the ci.sh file in this directory.

REM This is called from the LUCI recipes:
REM https://flutter.googlesource.com/recipes/+/refs/heads/master/recipe_modules/adhoc_validation/resources/customer_testing.bat

dart __deprecated_pub get
CD ..\tools
dart __deprecated_pub get
CD ..\customer_testing

CMD /S /C "IF EXIST "..\..\bin\cache\pkg\tests\" RMDIR /S /Q ..\..\bin\cache\pkg\tests"
git clone https://github.com/flutter/tests.git ..\..\bin\cache\pkg\tests
FOR /F "usebackq tokens=*" %%a IN (`dart --enable-asserts ..\tools\bin\find_commit.dart ..\..\bin\cache\pkg\tests`) DO git -C ..\..\bin\cache\pkg\tests checkout %%a
dart --enable-asserts run_tests.dart --skip-on-fetch-failure --skip-template ..\..\bin\cache\pkg\tests\registry\*.test
