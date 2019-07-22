// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

Widget _buildScroller({ List<String> log }) {
  return NotificationListener<ScrollNotification>(
    onNotification: (ScrollNotification notification) {
      if (notification is ScrollStartNotification) {
        log.add('scroll-start');
      } else if (notification is ScrollUpdateNotification) {
        log.add('scroll-update');
      } else if (notification is ScrollEndNotification) {
        log.add('scroll-end');
      }
      return false;
    },
    child: SingleChildScrollView(
      child: Container(width: 1000.0, height: 1000.0),
    ),
  );
}

void main() {
  Completer<void> animateTo(WidgetTester tester, double newScrollOffset, { @required Duration duration }) {
    final Completer<void> completer = Completer<void>();
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.animateTo(newScrollOffset, duration: duration, curve: Curves.linear).whenComplete(completer.complete);
    return completer;
  }

  void jumpTo(WidgetTester tester, double newScrollOffset) {
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(newScrollOffset);
  }

  Future<List<double>> _simulateScrollEvents(
      WidgetTester tester,
      int numEvents,
      Duration deliveryTimestamp(int i),
      Duration frameTime) async {
    await tester.pumpWidget(SingleChildScrollView(
      child: Container(width: 1000.0, height: 1000.0),
    ));
    final TestGesture gesture = await tester.startGesture(const Offset(500.0, 500.0));

    double frameOffset() {
      try {
        return tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .pixels;
      } on StateError {
        return -1;  // fail elegantly when there's no scrollable.
      }
    }

    final List<double> frameOffsets = <double>[];
    int numFrameDrawn = 0, numFramePumped = 0;
    tester.binding.addPersistentFrameCallback((Duration t) {
      numFrameDrawn += 1;
      frameOffsets.add(frameOffset());
    });

    int dragIndex = 0;
    for (int frameIndex = 1; dragIndex < numEvents; frameIndex += 1) {
      final Duration frameTimestamp = frameTime * frameIndex;
      while (dragIndex < numEvents && deliveryTimestamp(dragIndex) <= frameTimestamp) {
        await gesture.moveBy(const Offset(0.0, -1.0));
        dragIndex += 1;
      }
      await tester.pump(frameTime);
      numFramePumped += 1;
    }

    // We should miss at most 1 frame.
    // Without the fix (https://github.com/flutter/flutter/pull/36616), we could miss half of the frames.
    if (numFrameDrawn < numFramePumped - 1) {
      final List<String> formatted = List<String>.generate(
          numEvents,
          (int i) => (deliveryTimestamp(i).inMicroseconds / frameTime.inMicroseconds).toStringAsFixed(3),
      );
      print('Test failed with delivery sequence: $formatted');
      print('Frame offsets: $frameOffsets');
    }
    expect(numFrameDrawn, greaterThanOrEqualTo(numFramePumped - 1));

    return frameOffsets;
  }

  testWidgets('Miss at most one frame for irregular scroll drag events', (WidgetTester tester) async {
    const Duration kFrameTime = Duration(microseconds: 1e6 ~/ 60);
    const double kBaseDeliveryDelay = 0.2;  // in kFrameTime

    // Add an additional delay of [0.1, 0.9, 0.1, 0.9, 0.1, 0.9, ...] in kFrameTime
    Duration deliveryTimestamp(int i) => kFrameTime * (i + kBaseDeliveryDelay + <double>[0.1, 0.9][i % 2]);

    await _simulateScrollEvents(tester, 20, deliveryTimestamp, kFrameTime);
  });

  testWidgets('Delay at most one event for faster-than-vsync events', (WidgetTester tester) async {
    const Duration kFrameTime = Duration(microseconds: 1e6 ~/ 60);
    const double kBaseDeliveryDelay = 0.2;  // in kFrameTime

    // Simulate 120Hz input events delivery.
    Duration deliveryTimestamp(int i) => kFrameTime * (i * 0.5 + kBaseDeliveryDelay);

    final List<double> offsets = await _simulateScrollEvents(tester, 40, deliveryTimestamp, kFrameTime);

    // Ideal offsets are [2, 4, 6, 8, ...] (i.e., two pixels per frame).
    final List<double> idealOffsets = List<double>.generate(20, (int i) => ((i + 1) * 2).toDouble());

    expect(offsets.length, equals(idealOffsets.length));
    for (int i = 0; i < offsets.length; i += 1) {
      expect(offsets[i], greaterThanOrEqualTo(idealOffsets[i] - 1));
    }
  });

  testWidgets('Handles iPhone XS irregular events with different base delays', (WidgetTester tester) async {
    const Duration kFrameTime = Duration(microseconds: 1e6 ~/ 60);

    final List<double> actualDeliveryTimes = <double>[
      0.0, 0.9659423828125, 2.1082000732421875, 3.0290679931640625,
      4.1031341552734375, 5.1513214111328125, 6.2241363525390625, 7.2659454345703125,
      8.308258056640625, 9.60675048828125, 10.399948120117188, 11.470001220703125,
      12.5802001953125, 13.535812377929688, 14.885757446289062, 15.564254760742188,
      16.654876708984375, 17.683822631835938, 18.759628295898438, 20.022262573242188,
      20.712265014648438, 21.741439819335938, 22.833389282226562, 24.141189575195312,
      24.9683837890625, 25.973190307617188, 27.008193969726562, 28.006820678710938,
      29.046951293945312, 30.136886596679688, 31.162567138671875, 32.22850036621094,
      33.266815185546875, 34.69987487792969, 35.41351318359375, 36.35557556152344,
      37.485443115234375, 38.55400085449219, 39.57757568359375, 40.678253173828125,
      41.96244812011719, 42.71376037597656, 43.70013427734375, 44.67982482910156,
      45.75013732910156, 46.811065673828125, 47.85569763183594
      // the raw number is in 16ms instead of 16.67ms
    ].map((double x) => x * 16 / (1000 / 60)).toList();


    // Try all kinds of base delay based on real delivery times.
    for (double baseDeliveryDelay = 0.0; baseDeliveryDelay < 1; baseDeliveryDelay += 0.2) {
      Duration deliveryTimestamp(int i) =>
          kFrameTime * (actualDeliveryTimes[i] + baseDeliveryDelay);

      await _simulateScrollEvents(tester, actualDeliveryTimes.length, deliveryTimestamp, kFrameTime);
    }
  });


  testWidgets('Scroll event drag', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scroll-start']));
    await gesture.moveBy(const Offset(-10.0, -10.0));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await gesture.up();
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
  });

  testWidgets('Scroll animateTo', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    final Completer<void> completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll jumpTo', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    jumpTo(tester, 100.0);
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
    await tester.pump();
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
  });

  testWidgets('Scroll jumpTo during animation', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    final Completer<void> completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    expect(completer.isCompleted, isFalse);

    jumpTo(tester, 100.0);
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end', 'scroll-start', 'scroll-update', 'scroll-end']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end', 'scroll-start', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end', 'scroll-start', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll scrollTo during animation', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<void> completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    expect(completer.isCompleted, isFalse);

    completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('fling, fling generates two start/end pairs', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    // The ideal behavior here would be a single start/end pair, but for
    // simplicity of implementation we compromise here and accept two. Should
    // you find a way to make this work with just one without complicating the
    // API, feel free to change the expectation here.

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Offset(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start']));
    await tester.flingFrom(const Offset(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start', 'scroll-end', 'scroll-start']));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start', 'scroll-end', 'scroll-start', 'scroll-end']));
  });

  testWidgets('fling, pause, fling generates two start/end pairs', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Offset(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(minutes: 1));
    await tester.flingFrom(const Offset(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start', 'scroll-end', 'scroll-start']));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start', 'scroll-end', 'scroll-start', 'scroll-end']));
  });

  testWidgets('fling up ends', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Offset(100.0, 100.0), const Offset(50.0, 50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(log.first, equals('scroll-start'));
    expect(log.last, equals('scroll-end'));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log.length, equals(2));
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, equals(0.0));
  });
}
