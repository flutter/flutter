// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import '../environment.dart';

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
