// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:macrobenchmarks/common.dart';
import 'package:e2e/e2e.dart';
import 'package:macrobenchmarks/main.dart' as app;

typedef ControlCallback = Future<void> Function(WidgetController controller);

void macroPerfTestE2E(
  String testName,
  String routeName, {
  Duration pageDelay,
  Duration duration = const Duration(seconds: 3),
  Duration timeout = const Duration(seconds: 30),
  ControlCallback body,
  ControlCallback setup,
}) {
  final WidgetsBinding _binding = E2EWidgetsFlutterBinding.ensureInitialized();
  assert(_binding is E2EWidgetsFlutterBinding);
  final E2EWidgetsFlutterBinding binding = _binding as E2EWidgetsFlutterBinding;
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets(testName, (WidgetTester tester) async {
    assert(tester.binding == binding);
    app.main();
    await tester.pumpAndSettle();

    // The slight initial delay avoids starting the timing during a
    // period of increased load on the device. Without this delay, the
    // benchmark has greater noise.
    // See: https://github.com/flutter/flutter/issues/19434
    await tester.binding.delayed(const Duration(microseconds: 250));

    final Finder scrollable =
        find.byKey(const ValueKey<String>(kScrollableName));
    expect(scrollable, findsOneWidget);
    final Finder button =
        find.byKey(ValueKey<String>(routeName), skipOffstage: false);
    await tester.scrollUntilVisible(button, 50);
    expect(button, findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(button);
    // Cannot be pumpAndSettle because some tests have infinite animation.
    await tester.pump(const Duration(milliseconds: 20));

    if (pageDelay != null) {
      // Wait for the page to load
      await tester.binding.delayed(pageDelay);
    }

    if (setup != null) {
      await setup(tester);
    }

    await watchPerformance(binding, () async {
      final Future<void> durationFuture = tester.binding.delayed(duration);
      if (body != null) {
        await body(tester);
      }
      await durationFuture;
    });
  }, semanticsEnabled: false, timeout: Timeout(timeout));
}

bool _firstRun = true;

// TODO(CareF): move this to e2e after FrameTimingSummarizer goes into stable
// branch (#63537)
/// watches the [FrameTiming] of `action` and report it to the e2e binding.
Future<void> watchPerformance(
  E2EWidgetsFlutterBinding binding,
  Future<void> action(), {
  String reportKey = 'performance',
}) async {
  assert(() {
    if (_firstRun) {
      debugPrint(kDebugWarning);
      _firstRun = false;
    }
    return true;
  }());
  final List<FrameTiming> frameTimings = <FrameTiming>[];
  final TimingsCallback watcher = frameTimings.addAll;
  binding.addTimingsCallback(watcher);
  await action();
  binding.removeTimingsCallback(watcher);
  final FrameTimingSummarizer frameTimes = FrameTimingSummarizer(frameTimings);
  binding.reportData = <String, dynamic>{reportKey: frameTimes.summary};
}
