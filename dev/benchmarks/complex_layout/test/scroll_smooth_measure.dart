// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test is a use case of flutter/flutter#60796
// the test should be run as:
// flutter drive -t test/using_array.dart --driver test_driver/scrolling_test_e2e_test.dart

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e2e/e2e.dart';

import 'package:complex_layout/main.dart' as app;

class PointerDataTestBinding extends E2EWidgetsFlutterBinding {
  // PointerData injection would usually be considered device input and therefore
  // blocked by [TestWidgetsFlutterBinding]. Override this behavior
  // to help events go into widget tree.
  @override
  void dispatchEvent(
    PointerEvent event,
    HitTestResult hitTestResult, {
    TestBindingEventSource source = TestBindingEventSource.device,
  }) {
    super.dispatchEvent(event, hitTestResult, source: TestBindingEventSource.test);
  }
}

/// A union of [ui.PointerDataPacket] and the time it should be sent.
class PointerDataRecord {
  PointerDataRecord(this.timeStamp, List<ui.PointerData> data)
    : data = ui.PointerDataPacket(data: data);
  final ui.PointerDataPacket data;
  final Duration timeStamp;
}

/// Generates the [PointerDataRecord] to simulate a drag operation from
/// `center - totalMove/2` to `center + totalMove/2`.
Iterable<PointerDataRecord> dragInputDatas(
  final Duration epoch,
  final Offset center, {
  final Offset totalMove = const Offset(0, -400),
  final Duration totalTime = const Duration(milliseconds: 2000),
  final double frequency = 90,
}) sync* {
  final Offset startLocation = (center - totalMove / 2) * ui.window.devicePixelRatio;
  // The issue is about 120Hz input on 90Hz refresh rate device.
  // We test 90Hz input on 60Hz device here, which shows similar pattern.
  final int moveEventCount = totalTime.inMilliseconds * frequency ~/ 1000;
  final Offset movePerEvent = totalMove / moveEventCount.toDouble() * ui.window.devicePixelRatio;
  yield PointerDataRecord(epoch, <ui.PointerData>[
    ui.PointerData(
      timeStamp: epoch,
      change: ui.PointerChange.add,
      physicalX: startLocation.dx,
      physicalY: startLocation.dy,
    ),
    ui.PointerData(
      timeStamp: epoch,
      change: ui.PointerChange.down,
      physicalX: startLocation.dx,
      physicalY: startLocation.dy,
      pointerIdentifier: 1,
    ),
  ]);
  for (int t = 0; t < moveEventCount + 1; t++) {
    final Offset position = startLocation + movePerEvent * t.toDouble();
    yield PointerDataRecord(
      epoch + totalTime * t ~/ moveEventCount,
      <ui.PointerData>[ui.PointerData(
        // integer milliseconds is observed from devices
        timeStamp: epoch + totalTime * t ~/ moveEventCount,
        change: ui.PointerChange.move,
        physicalX: position.dx,
        physicalY: position.dy,
        // Scrolling behavior depends on this delta rather
        // than the position difference.
        physicalDeltaX: movePerEvent.dx,
        physicalDeltaY: movePerEvent.dy,
        pointerIdentifier: 1,
      )],
    );
  }
  final Offset position = startLocation + totalMove;
  yield PointerDataRecord(epoch + totalTime, <ui.PointerData>[ui.PointerData(
    timeStamp: epoch + totalTime,
    change: ui.PointerChange.up,
    physicalX: position.dx,
    physicalY: position.dy,
    pointerIdentifier: 1,
  )]);
}

class ResampleFlagVariant extends TestVariant<bool> {
  ResampleFlagVariant(this.binding);
  final E2EWidgetsFlutterBinding binding;

  @override
  final Set<bool> values = <bool>{true, false};

  Map<String, dynamic> result;

  @override
  String describeValue(bool value) => value ? 'resampling on' : 'resampling off';

  @override
  Future<bool> setUp(bool value) async {
    final bool original = binding.resamplingEnabled;
    binding.resamplingEnabled = value;
    return original;
  }

  @override
  Future<void> tearDown(bool value, bool memento) async {
    binding.resamplingEnabled = memento;
    binding.reportData[value ? 'with resampler' : 'without resampler'] = result;
  }
}

Future<void> main() async {
  final PointerDataTestBinding binding = PointerDataTestBinding();
  assert(WidgetsBinding.instance == binding);
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  binding.reportData ??= <String, dynamic>{};
  final ResampleFlagVariant variant = ResampleFlagVariant(binding);
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

    Duration now() => binding.currentSystemFrameTimeStamp;
    Future<List<Duration>> scroll() async {
      // Extra 50ms to avoid timeouts.
      final Duration startTime = const Duration(milliseconds: 500) + now();
      final List<Duration> delays = <Duration>[];
      for (final PointerDataRecord record in dragInputDatas(startTime, tester.getCenter(scrollerFinder))) {
        await tester.binding.delayed(record.timeStamp - now());
        // This now measures how accurate the above delayed is.
        delays.add(now() - record.timeStamp);
        ui.window.onPointerDataPacket(record.data);
      }
      return delays;
    }

    List<Duration> delays = <Duration>[];
    for (int n = 0; n < 5; n++) {
      delays += await scroll();
    }
    variant.result = scrollSummary(scrollOffset, delays, frameTimestamp);
    await tester.pumpAndSettle();
    scrollOffset.clear();
    delays.clear();
    await tester.idle();
  }, semanticsEnabled: false, variant: variant);
}

/// Calculates the smoothness measure from `scrollOffset` and `delays` list.
///
/// For smoothness it filters the frames with delays too longer to separate the
/// effect of building a frame too slow. Frames that are built slow are counted
/// to `droped_frame_count`.
///
/// Smoothness (jerk) is measured by the average of the absolute value for
/// discrete 2nd derivative (`average_abs_jerk`). And the frames with
/// estimated `jerk` larger than 0.5 is counted to `janky_count`.
Map<String, dynamic> scrollSummary(
  List<double> scrollOffset,
  List<Duration> delays,
  List<int> frameTimestamp,
) {
  double jankyCount = 0;
  double jerkAvg = 0;
  int lostFrame = 0;
  for (int i = 1; i < scrollOffset.length-1; i += 1) {
    if (frameTimestamp[i+1] - frameTimestamp[i-1] > 40E3
        || delays[i] > const Duration(milliseconds: 16)) {
      // filter data points from slow frame building or input simulation artifact
      lostFrame += 1;
      continue;
    }
    // Using abs rather than square because square (2-norm) amplifies the
    // effect of the data point that's relatively large, but in this metric
    // we prefer smaller data point to have similar effect.
    // This is also why we count the number of data that's larger than a
    // threshold (and the result is tested not sensitive to this threshold),
    // which is effectively a 0-norm.
    //
    // go/tq-smooth-scrolling suggests using jerk (3rd derivative of the position)
    // to measure the smoothness.
    // Here we are not using 2nd derivative instead because the input is
    // completely linear and the expected acceleration should be strictly zero.
    // Observed acceleration is jumping from positive to negative within
    // adjacent frames, meaning mathematically the discrete 3-rd derivative
    // (`f[3] - 3*f[2] + 3*f[1] - f[0]`) is not a good approximation of jerk
    // (continuous 3-rd derivative), while discrete 2nd
    // derivative (`f[2] - 2*f[1] + f[0]`) on the other hand is a better measure
    // of how the scrolling deviate away from linear, and given the acceleration
    // should average to zero within two frames, it's also a good approximation
    // for jerk in terms of physics.
    final double jerk = (scrollOffset[i-1] + scrollOffset[i+1] - 2*scrollOffset[i]).abs();
    jerkAvg += jerk;
    if (jerk > 0.5)
      jankyCount += 1;
  }
  // expect(lostFrame < 0.1 * frameTimestamp.length, true);
  jerkAvg /= frameTimestamp.length - lostFrame;

  return <String, dynamic>{
    'janky_count': jankyCount,
    'average_abs_jerk': jerkAvg,
    'droped_frame_count': lostFrame,
    'frame_timestamp': List<int>.from(frameTimestamp),
    'scroll_offset': List<double>.from(scrollOffset),
    'input_delay': delays.map<int>((Duration data) => data.inMicroseconds).toList(),
  };
}
