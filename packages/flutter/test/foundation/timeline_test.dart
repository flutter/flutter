// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterTimeline.reset();
    FlutterTimeline.collectionEnabled = false;
  });

  test('Does not collect when collection not enabled', () {
    FlutterTimeline.startSync('TEST');
    FlutterTimeline.finishSync();
    expect(
      () => FlutterTimeline.collect(),
      throwsStateError,
    );
  });

  test('Collects when collection is enabled', () {
    FlutterTimeline.collectionEnabled = true;
    FlutterTimeline.startSync('TEST');
    FlutterTimeline.finishSync();
    final AggregatedTimings data = FlutterTimeline.collect();
    expect(data.timedBlocks, hasLength(1));
    expect(data.aggregatedBlocks, hasLength(1));

    final AggregatedTimedBlock block = data.getAggregated('TEST');
    expect(block.name, 'TEST');
    expect(block.count, 1);
  });

  test('Deletes old data when reset', () {
    FlutterTimeline.collectionEnabled = true;
    FlutterTimeline.startSync('TEST');
    FlutterTimeline.finishSync();
    FlutterTimeline.reset();

    final AggregatedTimings data = FlutterTimeline.collect();
    expect(data.timedBlocks, isEmpty);
    expect(data.aggregatedBlocks, isEmpty);
  });

  test('Reports zero aggregation when requested missing block', () {
    FlutterTimeline.collectionEnabled = true;

    final AggregatedTimings data = FlutterTimeline.collect();
    final AggregatedTimedBlock block = data.getAggregated('MISSING');
    expect(block.name, 'MISSING');
    expect(block.count, 0);
    expect(block.duration, 0);
  });

  test('Measures the runtime of a function', () {
    FlutterTimeline.collectionEnabled = true;

    // The off-by-one values for `start` and `end` are for web's sake where
    // timer values are reported as float64 and toInt/toDouble conversions
    // are noops, so there's no value truncation happening, which makes it
    // a bit inconsistent with Stopwatch.
    final int start = FlutterTimeline.now - 1;
    FlutterTimeline.timeSync('TEST', () {
      final Stopwatch watch = Stopwatch()..start();
      while (watch.elapsedMilliseconds < 5) {}
      watch.stop();
    });
    final int end = FlutterTimeline.now + 1;

    final AggregatedTimings data = FlutterTimeline.collect();
    expect(data.timedBlocks, hasLength(1));
    expect(data.aggregatedBlocks, hasLength(1));

    final TimedBlock block = data.timedBlocks.single;
    expect(block.name, 'TEST');
    expect(block.start, greaterThanOrEqualTo(start));
    expect(block.end, lessThanOrEqualTo(end));
    expect(block.duration, greaterThan(0));

    final AggregatedTimedBlock aggregated = data.getAggregated('TEST');
    expect(aggregated.name, 'TEST');
    expect(aggregated.count, 1);
    expect(aggregated.duration, block.duration);
  });

  test('FlutterTimeline.instanceSync does not collect anything', () {
    FlutterTimeline.collectionEnabled = true;
    FlutterTimeline.instantSync('TEST');

    final AggregatedTimings data = FlutterTimeline.collect();
    expect(data.timedBlocks, isEmpty);
    expect(data.aggregatedBlocks, isEmpty);
  });

  test('FlutterTimeline.now returns a value', () {
    FlutterTimeline.collectionEnabled = true;
    expect(FlutterTimeline.now, isNotNull);
  });

  test('Can collect more than one slice of data', () {
    // IMPORTANT: keep this in sync with the same constant defined
    //            in foundation/timeline.dart
    const int kSliceSize = 500;

    FlutterTimeline.collectionEnabled = true;

    for (int i = 0; i < 10 * kSliceSize; i++) {
      FlutterTimeline.startSync('TEST');
      FlutterTimeline.finishSync();
    }
    final AggregatedTimings data = FlutterTimeline.collect();
    expect(data.timedBlocks, hasLength(10 * kSliceSize));
    expect(data.aggregatedBlocks, hasLength(1));

    final AggregatedTimedBlock block = data.getAggregated('TEST');
    expect(block.name, 'TEST');
    expect(block.count, 10 * kSliceSize);
  });
}
