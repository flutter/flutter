// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

/// The abstract class of environments in which test suites are
/// loaded—specifically, browsers and the Dart VM.
abstract class Environment {
  /// Whether this environment supports interactive debugging.
  bool get supportsDebugging;

  /// The URL of the Dart VM Observatory for this environment, or `null` if this
  /// environment doesn't run the Dart VM or the URL couldn't be detected.
  Uri? get observatoryUrl;

  /// The URL of the remote debugger for this environment, or `null` if it isn't
  /// enabled.
  Uri? get remoteDebuggerUrl;

  /// A broadcast stream that emits a `null` event whenever the user tells the
  /// environment to restart the current test once it's finished.
  ///
  /// Never emits an error, and never closes.
  Stream get onRestart;

  /// Displays information indicating that the test runner is paused.
  ///
  /// The returned operation will complete when the user takes action within the
  /// environment that should unpause the runner. If the runner is unpaused
  /// elsewhere, the operation should be canceled.
  CancelableOperation displayPause();
}

/// The default environment for platform plugins.
class PluginEnvironment implements Environment {
  @override
  final supportsDebugging = false;
  @override
  Stream get onRestart => StreamController.broadcast().stream;

  const PluginEnvironment();

  @override
  Uri? get observatoryUrl => null;

  @override
  Uri? get remoteDebuggerUrl => null;

  @override
  CancelableOperation displayPause() => throw UnsupportedError(
      'PluginEnvironment.displayPause is not supported.');
}
