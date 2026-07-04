// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = AutomatedTestWidgetsFlutterBinding();

  group(TestViewConfiguration, () {
    test('is initialized with top-level window if one is not provided', () {
      // The code below will throw without the default.
      TestViewConfiguration(size: const Size(1280.0, 800.0));
    });

    test('toMatrix handles zero size', () {
      // The code below will throw without the default.
      final Matrix4 matrix = TestViewConfiguration(size: Size.zero).toMatrix();
      expect(matrix.storage.every((double x) => x.isFinite), isTrue);
    });

    test('sets the DPR to match the window', () {
      final configuration = TestViewConfiguration(size: const Size(1280.0, 800.0));
      expect(configuration.devicePixelRatio, binding.window.devicePixelRatio);
    });
  });

  group(AutomatedTestWidgetsFlutterBinding, () {
    test('allows setting defaultTestTimeout to 5 minutes', () {
      binding.defaultTestTimeout = const Timeout(Duration(minutes: 5));
      expect(binding.defaultTestTimeout.duration, const Duration(minutes: 5));
    });
  });

  group('testTextInput', () {
    setUp(() {
      expect(binding.testTextInput, isNotNull);
      expect(binding.testTextInput.isRegistered, isFalse);
      expect(HttpOverrides.current, isNotNull);
    });
    tearDown(() {
      expect(binding.testTextInput.isRegistered, isFalse);
    });

    testWidgets('Registers testTextInput', (WidgetTester tester) async {
      expect(tester.testTextInput.isRegistered, isTrue);
    });

    test('Does not register testTextInput', () async {
      expect(binding.testTextInput.isRegistered, isFalse);
    });
  });

  testWidgets('timeStamp should be accurate to microsecond precision', (WidgetTester tester) async {
    final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(const SizedBox());

    final Duration timeStampBefore = widgetsBinding.currentSystemFrameTimeStamp;
    tester.binding.scheduleFrame();
    await tester.pump(const Duration(microseconds: 12345));
    final Duration timeStampAfter = widgetsBinding.currentSystemFrameTimeStamp;

    expect(timeStampAfter - timeStampBefore, const Duration(microseconds: 12345));
  });

  group('elapseBlocking', () {
    testWidgets('timer is not called', (WidgetTester tester) async {
      var timerCalled = false;
      Timer.run(() => timerCalled = true);

      binding.elapseBlocking(const Duration(seconds: 1));

      expect(timerCalled, false);
      await binding.idle();
    });

    testWidgets('can use to simulate slow build', (WidgetTester tester) async {
      final DateTime beforeTime = binding.clock.now();

      await tester.pumpWidget(
        Builder(
          builder: (_) {
            var timerCalled = false;
            Timer.run(() => timerCalled = true);

            binding.elapseBlocking(const Duration(seconds: 1));

            // if we use `delayed` instead of `elapseBlocking`, such as
            // binding.delayed(const Duration(seconds: 1));
            // the timer will be called here. Surely, that violates how
            // a flutter widget build works
            expect(timerCalled, false);

            return Container();
          },
        ),
      );

      expect(binding.clock.now(), beforeTime.add(const Duration(seconds: 1)));
      await binding.idle();
    });
  });

  testWidgets('Assets in the tester can be loaded without turning event loop', (
    WidgetTester tester,
  ) async {
    var responded = false;
    // The particular asset does not matter, as long as it exists.
    // ignore: unawaited_futures
    rootBundle.load('AssetManifest.bin').then((ByteData data) {
      responded = true;
    });
    expect(responded, true);
  });
}
