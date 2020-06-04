// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../convert.dart';
import '../globals.dart' as globals;
import 'watcher.dart';

/// Prints JSON events when running a test in --machine mode.
class EventPrinter extends TestWatcher {
  EventPrinter({StringSink out, TestWatcher parent})
    : _out = out ?? globals.stdio.stdout,
      _parent = parent;

  final StringSink _out;
  final TestWatcher _parent;

  @override
  void handleStartedProcess(ProcessEvent event) {
    _sendEvent('test.startedProcess',
        <String, dynamic>{'observatoryUri': event.observatoryUri.toString()});
    _parent?.handleStartedProcess(event);
  }

  @override
  Future<void> handleTestCrashed(ProcessEvent event) async {
    return _parent?.handleTestCrashed(event);
  }

  @override
  Future<void> handleTestTimedOut(ProcessEvent event) async {
    return _parent?.handleTestTimedOut(event);
  }

  @override
  Future<void> handleFinishedTest(ProcessEvent event) async {
    return _parent?.handleFinishedTest(event);
  }

  void _sendEvent(String name, [ dynamic params ]) {
    final Map<String, dynamic> map = <String, dynamic>{'event': name};
    if (params != null) {
      map['params'] = params;
    }
    _send(map);
  }

  void _send(Map<String, dynamic> command) {
    final String encoded = json.encode(command, toEncodable: _jsonEncodeObject);
    _out.writeln('\n[$encoded]');
  }

  dynamic _jsonEncodeObject(dynamic object) {
    if (object is Uri) {
      return object.toString();
    }
    return object;
  }
}
