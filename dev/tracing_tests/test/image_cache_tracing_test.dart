// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:isolate' as isolate;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main() {
  VmService vmService;
  String isolateId;
  setUpAll(() async {
    final developer.ServiceProtocolInfo info = await developer.Service.getInfo();

    if (info.serverUri == null) {
      fail('This test _must_ be run with --enable-vmservice.');
    }

    vmService = await vmServiceConnectUri('ws://localhost:${info.serverUri.port}${info.serverUri.path}ws');
    await vmService.setVMTimelineFlags(<String>['Dart']);
    isolateId = developer.Service.getIsolateID(isolate.Isolate.current);

    // Initialize the image cache.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('Image cache tracing', () async {
    final TestImageStreamCompleter completer1 = TestImageStreamCompleter();
    final TestImageStreamCompleter completer2 = TestImageStreamCompleter();
    PaintingBinding.instance.imageCache.putIfAbsent(
      'Test',
      () => completer1,
    );
    PaintingBinding.instance.imageCache.clear();

    // ignore: invalid_use_of_protected_member
    completer2.setImage(const ImageInfo(image: TestImage()));
    PaintingBinding.instance.imageCache.putIfAbsent(
      'Test2',
      () => completer2,
    );
    PaintingBinding.instance.imageCache.evict('Test2');

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
            'keepAliveImages': 0,
            'liveImages': 1,
            'currentSizeInBytes': 0,
            'isolateId': isolateId,
          }
        },
        <String, dynamic>{
          'name': 'ImageCache.putIfAbsent',
          'args': <String, dynamic>{'key': 'Test2', 'isolateId': isolateId}
        },
        <String, dynamic>{
          'name': 'ImageCache.evict',
          'args': <String, dynamic>{'sizeInBytes': 0, 'isolateId': isolateId}
        },
      ],
    );
  }, skip: isBrowser); // uses dart:isolate and io
}

void _expectTimelineEvents(List<TimelineEvent> events, List<Map<String, dynamic>> expected) {
  for (final TimelineEvent event in events) {
    for (int index = 0; index < expected.length; index += 1) {
      if (expected[index]['name'] == event.json['name']) {
        final Map<String, dynamic> expectedArgs = expected[index]['args'] as Map<String, dynamic>;
        final Map<String, dynamic> args = event.json['args'] as Map<String, dynamic>;
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

class TestImageStreamCompleter extends ImageStreamCompleter {}

class TestImage implements ui.Image {
  const TestImage({this.height = 0, this.width = 0});
  @override
  final int height;
  @override
  final int width;

  @override
  void dispose() { }

  @override
  Future<ByteData> toByteData({ ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba }) {
    throw UnimplementedError();
  }
}
