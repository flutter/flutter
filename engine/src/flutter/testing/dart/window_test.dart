// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('window.sendPlatformMessage preserves callback zone', () {
    runZoned(() {
      final Zone innerZone = Zone.current;
      window.sendPlatformMessage('test', ByteData.view(Uint8List(0).buffer), expectAsync1((ByteData data) {
        final Zone runZone = Zone.current;
        expect(runZone, isNotNull);
        expect(runZone, same(innerZone));
      }));
    });
  });

  test('FrameTiming.toString has the correct format', () {
    final FrameTiming timing = FrameTiming(<int>[1000, 8000, 9000, 19500]);
    expect(timing.toString(), 'FrameTiming(buildDuration: 7.0ms, rasterDuration: 10.5ms, totalSpan: 18.5ms)');
  });
}
