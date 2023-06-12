// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:dwds/data/isolate_events.dart';
import 'package:dwds/data/serializers.dart';
import 'package:dwds/src/sockets.dart';

import 'restarter.dart';

class ReloadingManager {
  final SocketClient _client;
  final Restarter _restarter;

  ReloadingManager(this._client, this._restarter);

  /// Attemps to perform a hot restart and returns whether it was successful or
  /// not.
  ///
  /// [runId] is used to hot restart code in the browser for all apps that
  /// - are loaded on the same page
  /// - called hotRestart with the same runId
  ///
  /// The apps are restarted at the same time on the first call.
  Future<bool> hotRestart({String? runId}) async {
    _beforeRestart();
    final result = await _restarter.restart(runId: runId);
    _afterRestart(result);
    return result;
  }

  /// Does a hard reload of the application.
  void reloadPage() {
    window.location.reload();
  }

  void _afterRestart(bool succeeded) {
    if (!succeeded) return;
    // Notify package:dwds that the isolate has been created.
    // package:dwds will respond with a [RunRequest].
    _client.sink.add(jsonEncode(serializers.serialize(IsolateStart())));
  }

  void _beforeRestart() {
    // Notify package:dwds that the isolate is about to exit.
    _client.sink.add(jsonEncode(serializers.serialize(IsolateExit())));
  }
}
