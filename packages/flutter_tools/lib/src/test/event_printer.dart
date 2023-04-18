// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../convert.dart';

import 'test_device.dart';
import 'watcher.dart';

/// Prints JSON events when running a test in --machine mode.
class EventPrinter extends TestWatcher {
  EventPrinter({required final StringSink out, final TestWatcher? parent})
    : _out = out,
      _parent = parent;

  final StringSink _out;
  final TestWatcher? _parent;

  @override
  void handleStartedDevice(final Uri? vmServiceUri) {
    _sendEvent('test.startedProcess',
        <String, dynamic>{
          'vmServiceUri': vmServiceUri?.toString(),
          // TODO(bkonyi): remove references to Observatory
          // See https://github.com/flutter/flutter/issues/121271
          'observatoryUri': vmServiceUri?.toString()
        });
    _parent?.handleStartedDevice(vmServiceUri);
  }

  @override
  Future<void> handleTestCrashed(final TestDevice testDevice) async {
    return _parent?.handleTestCrashed(testDevice);
  }

  @override
  Future<void> handleTestTimedOut(final TestDevice testDevice) async {
    return _parent?.handleTestTimedOut(testDevice);
  }

  @override
  Future<void> handleFinishedTest(final TestDevice testDevice) async {
    return _parent?.handleFinishedTest(testDevice);
  }

  void _sendEvent(final String name, [ final dynamic params ]) {
    final Map<String, dynamic> map = <String, dynamic>{'event': name};
    if (params != null) {
      map['params'] = params;
    }
    _send(map);
  }

  void _send(final Map<String, dynamic> command) {
    final String encoded = json.encode(command, toEncodable: _jsonEncodeObject);
    _out.writeln('\n[$encoded]');
  }

  dynamic _jsonEncodeObject(final dynamic object) {
    if (object is Uri) {
      return object.toString();
    }
    return object;
  }
}
