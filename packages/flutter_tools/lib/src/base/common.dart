// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'file_system.dart';
import 'platform.dart';

/// Return the absolute path of the user's home directory
String get homeDirPath {
  if (_homeDirPath == null) {
    _homeDirPath = platform.isWindows
        ? platform.environment['USERPROFILE']
        : platform.environment['HOME'];
    if (_homeDirPath != null)
      _homeDirPath = fs.path.absolute(_homeDirPath);
  }
  return _homeDirPath;
}
String _homeDirPath;

/// Throw a specialized exception for expected situations
/// where the tool should exit with a clear message to the user
/// and no stack trace unless the --verbose option is specified.
/// For example: network errors
void throwToolExit(String message, { int exitCode }) {
  throw ToolExit(message, exitCode: exitCode);
}

/// Specialized exception for expected situations
/// where the tool should exit with a clear message to the user
/// and no stack trace unless the --verbose option is specified.
/// For example: network errors
class ToolExit implements Exception {
  ToolExit(this.message, { this.exitCode });

  final String message;
  final int exitCode;

  @override
  String toString() => 'Exception: $message';
}
