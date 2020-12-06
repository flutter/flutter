@ECHO off
REM Copyright 2014 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

set FLUTTER_BIN_DIR=%FLUTTER_ROOT%\bin
set DART_BIN_DIR=%FLUTTER_BIN_DIR%\cache\dart-sdk\bin

"%DART_BIN_DIR%\dart" "%FLUTTER_ROOT%\packages\flutter_tools\bin\tool_backend.dart" %*
