// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:macrobenchmarks/common.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macrobenchmarks/main.dart' as app;
import 'package:vm_service/vm_service.dart' as vm;

typedef ControlCallback = Future<void> Function(WidgetController controller);

void macroPerfTestE2E(
  String testName,
  String routeName, {
  Duration pageDelay,
  Duration duration = const Duration(seconds: 3),
  Duration timeout = const Duration(seconds: 30),
  ControlCallback body,
  ControlCallback setup,
  bool measureCpuGpu = false,
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

    Future<void> testBody() async {
      final Future<void> durationFuture = tester.binding.delayed(duration);
      if (body != null) {
        await body(tester);
      }
      await durationFuture;
    }

    vm.Timeline timeline;
    await binding.watchPerformance(() async {
      if (measureCpuGpu) {
        timeline = await binding.traceTimeline(testBody, streams: <String>['Embedder']);
      } else {
        await testBody();
      }
    });

    if (measureCpuGpu) {
      final List<double> cpuUsage = timeline.traceEvents.where(
        (vm.TimelineEvent event) => event.json['name'] == 'CpuUsage').map<double>(
        (vm.TimelineEvent event) => double.parse(event.json['args']['total_cpu_usage'] as String)
      ).toList();
      if (cpuUsage.isNotEmpty) {
        binding.reportData['average_cpu_usage'] = cpuUsage.reduce(
          (double a, double b) => a + b,
        ) / cpuUsage.length;
      }
      final List<double> gpuUsage = timeline.traceEvents.where(
        (vm.TimelineEvent event) => event.json['name'] == 'GpuUsage').map<double>(
        (vm.TimelineEvent event) => double.parse(event.json['args']['gpu_usage'] as String)
      ).toList();
      if (gpuUsage.isNotEmpty) {
        binding.reportData['average_gpu_usage'] = gpuUsage.reduce(
          (double a, double b) => a + b,
        ) / gpuUsage.length;
      }
    }
  }, semanticsEnabled: false, timeout: Timeout(timeout));
}
