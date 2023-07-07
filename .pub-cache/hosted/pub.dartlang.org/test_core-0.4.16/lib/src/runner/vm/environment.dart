// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test_core/src/runner/environment.dart'; // ignore: implementation_imports
import 'package:vm_service/vm_service.dart';

/// The environment in which VM tests are loaded.
class VMEnvironment implements Environment {
  @override
  final supportsDebugging = true;
  @override
  final Uri observatoryUrl;

  /// The VM service isolate object used to control this isolate.
  final IsolateRef _isolate;
  final VmService _client;

  VMEnvironment(this.observatoryUrl, this._isolate, this._client);

  @override
  Uri? get remoteDebuggerUrl => null;

  @override
  Stream get onRestart => StreamController.broadcast().stream;

  @override
  CancelableOperation displayPause() {
    var completer =
        CancelableCompleter(onCancel: () => _client.resume(_isolate.id!));

    completer.complete(_client.pause(_isolate.id!).then((_) => _client
        .onDebugEvent
        .firstWhere((event) => event.kind == EventKind.kResume)));

    return completer.operation;
  }
}
