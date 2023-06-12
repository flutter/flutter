// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Indicates that a build config file has changed, and the build needs to be
/// re-ran.
///
/// An exit code of 75 should be set when handling this exception.
class BuildConfigChangedException implements Exception {
  const BuildConfigChangedException();
}

/// Indicates that the build script itself has changed, and needs to be re-ran.
///
/// If the build is running from a snapshot, the snapshot should also be
/// deleted before exiting.
///
/// An exit code of 75 should be set when handling this exception.
class BuildScriptChangedException implements Exception {
  const BuildScriptChangedException();
}

/// Indicates that the build cannot be attempted.
///
/// Before throwing this exception a user actionable message should be logged.
class CannotBuildException implements Exception {
  const CannotBuildException();
}
