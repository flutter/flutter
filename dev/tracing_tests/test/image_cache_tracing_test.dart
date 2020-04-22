// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate' as isolate;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String isolateId;
  final TimelineObtainer timelineObtainer = TimelineObtainer();

  setUpAll(() async {
    isolateId = developer.Service.getIsolateID(isolate.Isolate.current);
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();

    if (info.serverUri == null) {
      fail('This test _must_ be run with --enable-vmservice.');
    }
    await timelineObtainer.connect(info.serverUri);
    await timelineObtainer.setDartFlags();

    // Initialize the image cache.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDownAll(() async {
    await timelineObtainer?.close();
  });

  test('Image cache tracing', () async {
    final TestImageStreamCompleter completer1 = TestImageStreamCompleter();
    PaintingBinding.instance.imageCache.putIfAbsent(
      'Test',
      () => completer1,
    );
    PaintingBinding.instance.imageCache.clear();

    final List<Map<String, dynamic>> timelineEvents = await timelineObtainer.getTimelineData();

    _expectTimelineEvents(
      timelineEvents,
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'ImageCache.putIfAbsent',
          'args': <String, dynamic>{'key': 'Test', 'isolateId': isolateId}
        },
        <String, dynamic>{
          'name': 'listener',
          'args': <String, dynamic>{'parentId': '1', 'isolateId': isolateId}
        },
        <String, dynamic>{
          'name': 'ImageCache.clear',
          'args': <String, dynamic>{
            'pendingImages': 1,
            'keepAliveImages': 0,
            'liveImages': 1,
            'currentSizeInBytes': 0,
            'isolateId': isolateId,
          }
        },
      ],
    );
  }, skip: isBrowser); // uses dart:isolate and io
}

void _expectTimelineEvents(
  List<Map<String, dynamic>> events,
  List<Map<String, dynamic>> expected,
) {
  for (final Map<String, dynamic> event in events) {
    for (int index = 0; index < expected.length; index += 1) {
      if (expected[index]['name'] == event['name']) {
        final Map<String, dynamic> expectedArgs = expected[index]['args'] as Map<String, dynamic>;
        final Map<String, dynamic> args = event['args'] as Map<String, dynamic>;
        if (_mapsEqual(expectedArgs, args)) {
          expected.removeAt(index);
        }
      }
    }
  }
  if (expected.isNotEmpty) {
    final String encodedEvents = jsonEncode(events);
    fail('Timeline did not contain expected events: $expected\nactual: $encodedEvents');
  }
}

bool _mapsEqual(Map<String, dynamic> expectedArgs, Map<String, dynamic> args) {
  for (final String key in expectedArgs.keys) {
    if (expectedArgs[key] != args[key]) {
      return false;
    }
  }
  return true;
}

// TODO(dnfield): This can be removed in favor of using the vm_service package, https://github.com/flutter/flutter/issues/55411
class TimelineObtainer {
  WebSocket _observatorySocket;
  int _lastCallId = 0;

  final Map<int, Completer<dynamic>> _completers = <int, Completer<dynamic>>{};


  Future<void> connect(Uri uri) async {
    _observatorySocket = await WebSocket.connect('ws://localhost:${uri.port}${uri.path}ws');
    _observatorySocket.listen((dynamic data) => _processResponse(data as String));
  }

  void _processResponse(String data) {
    final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;
    final int id = json['id'] as int;
    _completers.remove(id).complete(json['result']);
  }

  Future<bool> setDartFlags() async {
    _lastCallId += 1;
    final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
    _completers[_lastCallId] = completer;
    _observatorySocket.add(jsonEncode(<String, dynamic>{
      'id': _lastCallId,
      'method': 'setVMTimelineFlags',
      'params': <String, dynamic>{
        'recordedStreams': <String>['Dart'],
      },
    }));

    final Map<String, dynamic> result = await completer.future;
    return result['type'] == 'Success';
  }

  Future<List<Map<String, dynamic>>> getTimelineData() async {
    _lastCallId += 1;
    final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
    _completers[_lastCallId] = completer;
    _observatorySocket.add(jsonEncode(<String, dynamic>{
      'id': _lastCallId,
      'method': 'getVMTimeline',
    }));

    final Map<String, dynamic> result = await completer.future;
    final List<dynamic> list = result['traceEvents'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> close() async {
    expect(_completers, isEmpty);
    await _observatorySocket?.close();
  }
}

class TestImageStreamCompleter extends ImageStreamCompleter {}
