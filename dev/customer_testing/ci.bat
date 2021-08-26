@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM This should match the ci.sh file in this directory.

REM This is called from the LUCI recipes:
REM https://flutter.googlesource.com/recipes/+/refs/heads/master/recipe_modules/adhoc_validation/resources/customer_testing.bat

dart --enable-asserts ci.dart
