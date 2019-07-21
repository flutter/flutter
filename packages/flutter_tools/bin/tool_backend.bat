:: Copyright 2019 The Chromium Authors. All rights reserved.
:: Use of this source code is governed by a BSD-style license that can be
:: found in the LICENSE file.
@echo off

set FLUTTER_BIN_DIR=%FLUTTER_ROOT%\bin
set DART_BIN_DIR=%FLUTTER_BIN_DIR%\cache\dart-sdk\bin

"%DART_BIN_DIR%\dart" "%FLUTTER_ROOT%\packages\flutter_tools\bin\tool_backend.dart" %*
