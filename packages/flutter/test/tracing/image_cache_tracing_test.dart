// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:isolate' as isolate;

import 'package:flutter/painting.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../flutter_test_alternative.dart';
import '../painting/mocks_for_image_cache.dart';
import '../rendering/rendering_tester.dart';

void main() {
  VmService vmService;
  String isolateId;
  setUpAll(() async {
    final developer.ServiceProtocolInfo info =
        await developer.Service.getInfo();
    vmService = await vmServiceConnectUri(
        'ws://localhost:${info.serverUri.port}${info.serverUri.path}ws');
    await vmService.setVMTimelineFlags(<String>['Dart']);
    isolateId = developer.Service.getIsolateID(isolate.Isolate.current);
    TestRenderingFlutterBinding();
  });

  test('Image cache tracing', () async {
    final TestImageStreamCompleter completer1 = TestImageStreamCompleter();
    PaintingBinding.instance.imageCache.putIfAbsent(
      'Test',
      () => completer1,
    );
    PaintingBinding.instance.imageCache.clear();
    final Timeline timeline = await vmService.getVMTimeline();
    _expectTimelineEvents(
      timeline.traceEvents,
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
            'cachedImages': 0,
            'currentSizeInBytes': 0,
            'isolateId': isolateId,
          }
        },
      ],
    );
  }, skip: isBrowser); // uses dart:isolate and io
}

void _expectTimelineEvents(
    List<TimelineEvent> events, List<Map<String, dynamic>> expected) {
  for (final TimelineEvent event in events) {
    for (int index = 0; index < expected.length; index += 1) {
      if (expected[index]['name'] == event.json['name']) {
        final Map<String, dynamic> expectedArgs =
            expected[index]['args'] as Map<String, dynamic>;
        final Map<String, dynamic> args =
            event.json['args'] as Map<String, dynamic>;
        if (_mapsEqual(expectedArgs, args)) {
          expected.removeAt(index);
        }
      }
    }
  }
  if (expected.isNotEmpty) {
    final String encodedEvents = jsonEncode(events);
    fail(
        'Timeline did not contain expected events: $expected\nactual: $encodedEvents');
  }
}

bool _mapsEqual(Map<String, dynamic> expectedArgs, Map<String, dynamic> args) {
  if (expectedArgs.length != args.length) {
    return false;
  }
  for (final String key in expectedArgs.keys) {
    if (expectedArgs[key] != args[key]) {
      return false;
    }
  }
  return true;
}
