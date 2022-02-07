// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macrobenchmarks/main.dart' as app;

typedef ControlCallback = Future<void> Function(WidgetController controller);

void macroPerfTestE2E(
  String testName,
  String routeName, {
  Duration? pageDelay,
  Duration duration = const Duration(seconds: 3),
  ControlCallback? body,
  ControlCallback? setup,
}) {
  final WidgetsBinding _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  assert(_binding is IntegrationTestWidgetsFlutterBinding);
  final IntegrationTestWidgetsFlutterBinding binding = _binding as IntegrationTestWidgetsFlutterBinding;
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

    expect(routeName, startsWith('/'));
    int i = 0;
    while (i < routeName.length) {
      i = routeName.indexOf('/', i + 1);
      if (i < 0) {
        i = routeName.length;
      }
      final Finder button = find.byKey(ValueKey<String>(routeName.substring(0, i)), skipOffstage: false);
      await tester.scrollUntilVisible(button, 50);
      expect(button, findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(button);
      // Cannot be pumpAndSettle because some tests have infinite animation.
      await tester.pump(const Duration(milliseconds: 20));
    }

    if (pageDelay != null) {
      // Wait for the page to load
      await tester.binding.delayed(pageDelay);
    }

    if (setup != null) {
      await setup(tester);
    }

    await binding.watchPerformance(() async {
      final Future<void> durationFuture = tester.binding.delayed(duration);
      if (body != null) {
        await body(tester);
      }
      await durationFuture;
    });
  }, semanticsEnabled: false, timeout: Timeout.none);
}
