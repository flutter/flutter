// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    FrameTiming timing = FrameTiming(<int>[1000, 8000, 9000, 19500]);
    expect(timing.toString(), 'FrameTiming(buildDuration: 7.0ms, rasterDuration: 10.5ms, totalSpan: 18.5ms)');
  });

  test('window.frameTimings works', () async {
    // Test a single subscription. Check that debugNeedsReportTimings is
    // properly reset after the subscription is cancelled.
    expect(window.debugNeedsReportTimings, false);
    final FrameTiming mockTiming = FrameTiming(<int>[1000, 8000, 9000, 19500]);
    final Future<FrameTiming> frameTiming = window.frameTimings.first;
    expect(window.debugNeedsReportTimings, true);
    window.debugReportTimings(<FrameTiming>[mockTiming]);
    expect(await frameTiming, equals(mockTiming));
    expect(window.debugNeedsReportTimings, false);

    // Test multiple (two) subscriptions after that debugNeedsReportTimings has
    // been reset to false by the single subscription test above.
    //
    // Subscription 1
    final Future<FrameTiming> timingFuture = window.frameTimings.first;
    //
    // Subscription 2
    final List<FrameTiming> timings = <FrameTiming>[];
    final Completer<void> completer = Completer<void>();
    int frameCount = 0;
    window.frameTimings.listen((FrameTiming t) {
      timings.add(t);
      frameCount += 1;
      if (frameCount == 2) {
        completer.complete();
      }
    });

    final FrameTiming secondMock = FrameTiming(<int>[1, 2, 3, 4]);
    window.debugReportTimings(<FrameTiming>[secondMock, secondMock]);
    final FrameTiming timing = await timingFuture;
    expect(timing != mockTiming, isTrue);
    expect(timing, equals(secondMock));
    await completer.future;
    expect(timings, hasLength(2));
  });
}
