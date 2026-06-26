// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/browser.dart';

import '../common.dart';
import 'browser_test_json_samples.dart';

void main() {
  group('BlinkTraceEvent works with Chrome 89+', () {
    // Used to test 'false' results
    final unrelatedPhX = BlinkTraceEvent.fromJson(unrelatedPhXJson);
    final anotherUnrelated = BlinkTraceEvent.fromJson(anotherUnrelatedJson);

    test('isBeginFrame', () {
      final event = BlinkTraceEvent.fromJson(beginMainFrameJson_89plus);

      expect(event.isBeginFrame, isTrue);
      expect(unrelatedPhX.isBeginFrame, isFalse);
      expect(anotherUnrelated.isBeginFrame, isFalse);
    });

    test('isUpdateAllLifecyclePhases', () {
      final event = BlinkTraceEvent.fromJson(updateLifecycleJson_89plus);

      expect(event.isUpdateAllLifecyclePhases, isTrue);
      expect(unrelatedPhX.isUpdateAllLifecyclePhases, isFalse);
      expect(anotherUnrelated.isUpdateAllLifecyclePhases, isFalse);
    });

    test('isBeginMeasuredFrame', () {
      final event = BlinkTraceEvent.fromJson(beginMeasuredFrameJson_89plus);

      expect(event.isBeginMeasuredFrame, isTrue);
      expect(unrelatedPhX.isBeginMeasuredFrame, isFalse);
      expect(anotherUnrelated.isBeginMeasuredFrame, isFalse);
    });

    test('isEndMeasuredFrame', () {
      final event = BlinkTraceEvent.fromJson(endMeasuredFrameJson_89plus);

      expect(event.isEndMeasuredFrame, isTrue);
      expect(unrelatedPhX.isEndMeasuredFrame, isFalse);
      expect(anotherUnrelated.isEndMeasuredFrame, isFalse);
    });
  });

  test('BlinkTraceSummary falls back to duration when thread duration is absent', () {
    final Map<String, dynamic> beginMeasuredFrame = _event(beginMeasuredFrameJson_89plus, ts: 100);
    final Map<String, dynamic> beginFrame = _event(
      beginMainFrameJson_89plus,
      ts: 110,
      duration: 6000,
      removeThreadDuration: true,
    );
    final Map<String, dynamic> endMeasuredFrame = _event(endMeasuredFrameJson_89plus, ts: 120);
    final Map<String, dynamic> updateLifecycle = _event(
      updateLifecycleJson_89plus,
      ts: 130,
      duration: 250,
      removeThreadDuration: true,
    );

    final BlinkTraceSummary? summary = BlinkTraceSummary.fromJson(<Map<String, dynamic>>[
      beginMeasuredFrame,
      beginFrame,
      endMeasuredFrame,
      updateLifecycle,
    ]);

    expect(summary!.averageBeginFrameTime, const Duration(microseconds: 6000));
    expect(summary.averageUpdateLifecyclePhasesTime, const Duration(microseconds: 250));
    expect(summary.averageTotalUIFrameTime, const Duration(microseconds: 6250));
  });
}

Map<String, dynamic> _event(
  Map<String, Object?> event, {
  required int ts,
  int? duration,
  bool removeThreadDuration = false,
}) {
  final result = Map<String, dynamic>.from(event);
  result['ts'] = ts;
  if (duration != null) {
    result['dur'] = duration;
  }
  if (removeThreadDuration) {
    result.remove('tdur');
  }
  return result;
}
