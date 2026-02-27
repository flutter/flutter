@ECHO off
REM Copyright 2013 The Flutter Authors. All rights reserved.
REM Use of this source code is governed by a BSD-style license that can be
REM found in the LICENSE file.

REM ---------------------------------- NOTE ----------------------------------
REM
REM Please keep the logic in this file consistent with the logic in the
REM `black.sh` script in the same directory to ensure that it continues to
REM work across all platforms!
REM
REM --------------------------------------------------------------------------

SET black_path=%~dp0\..\..\flutter\third_party\black

IF NOT EXIST "%black_path%" (
  ECHO Error: black directory not found at %black_path%. Did you run gclient sync? >&2
  EXIT /B 1
)

REM Use the black binary from our third_party directory.
"%black_path%\black" %*

