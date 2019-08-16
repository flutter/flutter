// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'file_system.dart';
import 'platform.dart';

/// Whether the tool started from the daemon, as opposed to the command line.
// TODO(jonahwilliams): remove once IDE updates have rolled.
bool isRunningFromDaemon = false;

/// Return the absolute path of the user's home directory
String get homeDirPath {
  String path = platform.isWindows
      ? platform.environment['USERPROFILE']
      : platform.environment['HOME'];
  if (path != null) {
    path = fs.path.absolute(path);
  }
  return path;
}

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

/// Indicates to the linter that the given future is intentionally not `await`-ed.
///
/// Has the same functionality as `unawaited` from `package:pedantic`.
///
/// In an async context, it is normally expected than all Futures are awaited,
/// and that is the basis of the lint unawaited_futures which is turned on for
/// the flutter_tools package. However, there are times where one or more
/// futures are intentionally not awaited. This function may be used to ignore a
/// particular future. It silences the unawaited_futures lint.
void unawaited(Future<void> future) { }
