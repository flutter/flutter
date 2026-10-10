// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final animateWithoutListeners in <bool>[true, false]) {
    testWidgets('Visibility removes animation listeners ($animateWithoutListeners)', (
      WidgetTester tester,
    ) async {
      // Regression test for https://github.com/flutter/flutter/issues/174785.
      final key = GlobalKey<_AnimatedVisibilityState>();
      Widget build(bool visible) {
        return _AnimatedVisibility(
          key: key,
          visible: visible,
          animateWithoutListeners: animateWithoutListeners,
        );
      }

      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      final _AnimatedVisibilityState state = key.currentState!;
      expect(state.buildCount, greaterThan(1));
      expect(tester.binding.transientCallbackCount, 1);

      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 100));
      final int hiddenBuildCount = state.buildCount;
      final double hiddenValue = state.controller.value;
      expect(find.byType(ColoredBox, skipOffstage: false), findsNothing);
      expect(find.byType(Visibility), paintsNothing);
      expect(state.controller.isAnimating, isTrue);
      expect(tester.binding.transientCallbackCount, animateWithoutListeners ? 1 : 0);
      expect(tester.binding.hasScheduledFrame, animateWithoutListeners);

      await tester.pump(const Duration(milliseconds: 100));
      expect(state.buildCount, hiddenBuildCount);
      expect(state.controller.value, animateWithoutListeners ? isNot(hiddenValue) : hiddenValue);

      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.buildCount, greaterThan(hiddenBuildCount));
      expect(state.controller.value, isNot(hiddenValue));
      expect(tester.binding.transientCallbackCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('AnimationController animates without value listeners by default', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(vsync: tester, duration: const Duration(seconds: 1));
    addTearDown(controller.dispose);
    final statuses = <AnimationStatus>[];
    controller.addStatusListener(statuses.add);
    var completed = false;
    controller.forward().then((_) => completed = true);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.value, 0.5);
    await tester.pump(const Duration(milliseconds: 501));
    expect(controller.value, 1.0);
    expect(completed, isTrue);
    expect(statuses, <AnimationStatus>[AnimationStatus.forward, AnimationStatus.completed]);
  });

  testWidgets('Silenced controllers resume with elapsed time and preserve completion', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
      animateWithoutListeners: false,
    );
    addTearDown(controller.dispose);
    final statuses = <AnimationStatus>[];
    controller.addStatusListener(statuses.add);
    var completed = false;
    controller.forward().then((_) => completed = true);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(controller.isAnimating, isTrue);

    void listener() {}
    controller.addListener(listener);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.value, 0.1);
    controller.removeListener(listener);
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.value, 0.1);
    expect(tester.binding.transientCallbackCount, 0);

    controller.addListener(listener);
    await tester.pump();
    expect(controller.value, 0.3);
    controller.removeListener(listener);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isFalse);
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    controller.addListener(listener);
    await tester.pump();
    expect(controller.value, 1.0);
    expect(completed, isTrue);
    expect(statuses, <AnimationStatus>[AnimationStatus.forward, AnimationStatus.completed]);
  });

  testWidgets('Duplicate listeners and removing absent listeners preserve ticking', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
      animateWithoutListeners: false,
    )..repeat();
    addTearDown(controller.dispose);
    void listener() {}
    void absentListener() {}

    controller
      ..removeListener(listener)
      ..addListener(listener)
      ..addListener(listener)
      ..removeListener(absentListener)
      ..removeListener(listener);
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pump();
    controller.removeListener(listener);
    expect(tester.binding.transientCallbackCount, 0);
    controller.removeListener(listener);
    expect(tester.binding.transientCallbackCount, 0);
    controller.addListener(listener);
    expect(tester.binding.transientCallbackCount, 1);
    controller.stop();
  });

  testWidgets('Clearing value listeners silences the controller', (WidgetTester tester) async {
    final controller = _ClearableAnimationController(vsync: tester)..repeat();
    addTearDown(controller.dispose);
    controller.addListener(() {});
    expect(tester.binding.transientCallbackCount, 1);
    controller.removeAllListeners();
    expect(tester.binding.transientCallbackCount, 0);
    controller.addListener(() {});
    expect(tester.binding.transientCallbackCount, 1);
    controller.stop();
  });

  testWidgets('Unbounded controllers can silence unobserved animations', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController.unbounded(vsync: tester, animateWithoutListeners: false)
      ..repeat(min: 0.0, max: 2.0, period: const Duration(seconds: 1));
    addTearDown(controller.dispose);
    expect(tester.binding.transientCallbackCount, 0);
    controller.addListener(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.value, 0.2);
    controller.stop();
  });

  testWidgets('Resync preserves silencing, elapsed time, and the animation future', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
      animateWithoutListeners: false,
    );
    addTearDown(controller.dispose);
    void listener() {}
    controller.addListener(listener);
    var completed = false;
    controller.forward().then((_) => completed = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    controller
      ..removeListener(listener)
      ..resync(const TestVSync());
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(milliseconds: 200));
    controller.addListener(listener);
    await tester.pump();
    expect(controller.value, 0.3);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
  });

  testWidgets('Value listeners and TickerMode independently silence animations', (
    WidgetTester tester,
  ) async {
    final key = GlobalKey<_AnimatedVisibilityState>();
    Future<void> check({required bool visible, required bool tickerMode}) async {
      await tester.pumpWidget(
        TickerMode(
          enabled: tickerMode,
          child: _AnimatedVisibility(key: key, visible: visible, animateWithoutListeners: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(key.currentState!.controller.isAnimating, isTrue);
      expect(tester.binding.transientCallbackCount, visible && tickerMode ? 1 : 0);
      expect(tester.binding.hasScheduledFrame, visible && tickerMode);
    }

    await check(visible: true, tickerMode: true);
    await check(visible: false, tickerMode: true);
    await check(visible: false, tickerMode: false);
    await check(visible: false, tickerMode: true);
    await check(visible: false, tickerMode: false);
    await check(visible: true, tickerMode: false);
    await check(visible: true, tickerMode: true);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _AnimatedVisibility extends StatefulWidget {
  const _AnimatedVisibility({
    super.key,
    required this.visible,
    required this.animateWithoutListeners,
  });

  final bool visible;
  final bool animateWithoutListeners;

  @override
  State<_AnimatedVisibility> createState() => _AnimatedVisibilityState();
}

class _AnimatedVisibilityState extends State<_AnimatedVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final CurvedAnimation curve;
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      animateWithoutListeners: widget.animateWithoutListeners,
    )..repeat(reverse: true);
    curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Visibility(
        visible: widget.visible,
        child: AnimatedBuilder(
          animation: curve,
          builder: (BuildContext context, Widget? child) {
            buildCount += 1;
            return SizedBox(
              width: 100.0 + 100.0 * curve.value,
              height: 100.0,
              child: const ColoredBox(color: Color(0xFF0000FF)),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    curve.dispose();
    controller.dispose();
    super.dispose();
  }
}

class _ClearableAnimationController extends AnimationController {
  _ClearableAnimationController({required super.vsync})
    : super(duration: const Duration(seconds: 1), animateWithoutListeners: false);

  void removeAllListeners() {
    clearListeners();
  }
}
