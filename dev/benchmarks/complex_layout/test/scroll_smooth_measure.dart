// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

// This test is a use case of flutter/flutter#60796
// the test should be run as:
// flutter drive -t test/using_array.dart --driver test_driver/scrolling_test_e2e_test.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e2e/e2e.dart';

import 'package:complex_layout/main.dart' as app;

Future<void> main() async {
  final E2EWidgetsFlutterBinding binding =
      E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  testWidgets('Smoothness test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final Finder scrollerFinder = find.byKey(const ValueKey<String>('complex-scroll'));
    final ListView scroller = tester.widget<ListView>(scrollerFinder);
    final ScrollController controller = scroller.controller;
    final List<int> frameTimestamp = <int>[];
    final List<double> scrollOffset = <double>[];
    binding.addPersistentFrameCallback((Duration timeStamp) {
      if (controller.hasClients) {
        // This if is necessary because by the end of the test the widget tree
        // is destroyed.
        frameTimestamp.add(timeStamp.inMicroseconds);
        scrollOffset.add(controller.offset);
      }
    });

    const Offset totalMove = Offset(0, -400);
    final Offset location = tester.getCenter(scrollerFinder) - totalMove / 2;
    const int totalTime = 2000;
    // The issue is about 120Hz input on 90Hz refresh rate device.
    // We test 90Hz input on 60Hz device here, which shows similar pattern.
    const int intervalCount = totalTime * 90 ~/ 1000; // 90Hz
    final Offset movePerEvent = totalMove / intervalCount.toDouble();
    final List<PointerEventRecord> records = <PointerEventRecord>[
      PointerEventRecord(Duration.zero, <PointerEvent>[
        PointerAddedEvent(
          timeStamp: Duration.zero,
          position: location,
        ),
        PointerDownEvent(
          timeStamp: Duration.zero,
          position: location,
          pointer: 1,
        ),
      ]),
      ...<PointerEventRecord>[
        for (int t=0; t < intervalCount+1; t++)
          PointerEventRecord(
            Duration(milliseconds: totalTime * t ~/ intervalCount),
            <PointerEvent>[PointerMoveEvent(
              // integer milliseconds is observed from devices
              timeStamp: Duration(milliseconds: totalTime * t ~/ intervalCount),
              position: location + movePerEvent * t.toDouble(),
              pointer: 1,
              // Scrolling behavior depends on this delta rather
              // than the position difference.
              delta: movePerEvent,
            )],
          ),
      ],
      PointerEventRecord(
        const Duration(milliseconds: totalTime),
        <PointerEvent>[PointerUpEvent(
          timeStamp: const Duration(microseconds: totalTime),
          position: location + totalMove,
          pointer: 1,
        )],
      ),
    ];

    List<Duration> delays = <Duration>[];
    for (int n = 0; n < 5; n++) {
      delays += await tester.handlePointerEventRecord(records);
    }

    double jankyCount = 0;
    double jerkAvg = 0;
    int lostFrame = 0;
    for (int i = 1; i < scrollOffset.length-1; i += 1) {
      if (frameTimestamp[i+1] - frameTimestamp[i-1] > 40E3
          || delays[i] > const Duration(milliseconds: 16)) {
        // filter datapoints from slow frame building or input simulation artifact
        lostFrame += 1;
        continue;
      }
      // Using abs rather than square because square (2-norm) amplifies the
      // effect of the data point that's relatively large, but in this metric
      // we prefer smaller data point to have similiar effect.
      // This is also why we count the number of data that's larger than a
      // threshold (and the result is tested not sensitive to this threshold),
      // which is effectly a 0-norm.
      final double jerk = (scrollOffset[i-1] + scrollOffset[i+1] - 2*scrollOffset[i]).abs();
      jerkAvg += jerk;
      if (jerk > 0.5)
        jankyCount += 1;
    }
    // expect(lostFrame < 0.1 * frameTimestamp.length, true);
    jerkAvg /= frameTimestamp.length - lostFrame;

    binding.reportData = <String, dynamic>{
      'janky_count': jankyCount,
      'average_abs_jerk': jerkAvg,
      'droped_frame_count': lostFrame,
      'frame_timestamp': frameTimestamp,
      'scroll_offset': scrollOffset,
      'input_delay': delays.map<int>((Duration data) => data.inMicroseconds).toList(),
    };

    await tester.idle();
  }, semanticsEnabled: false);
}

double _sq(double value) => value * value;
