// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import '../base/io.dart' show stdout;
import 'watcher.dart';

/// Prints JSON events when running a test in --machine mode.
class EventPrinter extends TestWatcher {
  EventPrinter({StringSink out}) : this._out = out == null ? stdout: out;

  final StringSink _out;

  @override
  void onStartedProcess(ProcessEvent event) {
    _sendEvent('test.startedProcess',
        <String, dynamic>{'observatoryUri': event.observatoryUri.toString()});
  }

  void _sendEvent(String name, [dynamic params]) {
    final Map<String, dynamic> map = <String, dynamic>{ 'event': name};
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
