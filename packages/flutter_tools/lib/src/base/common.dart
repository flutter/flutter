// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const int kDefaultObservatoryPort = 8100;
const int kDefaultDiagnosticPort  = 8101;
const int kDefaultDrivePort       = 8183;

/// Specialized exception for expected situations
/// where the tool should exit with a clear message to the user
/// and no stack trace unless the --verbose option is specified.
/// For example: network errors
class ToolExit implements Exception {
  ToolExit(this.message, { this.exitCode });

  final String message;
  final int exitCode;

  @override
  String toString() => "Exception: $message";
}
