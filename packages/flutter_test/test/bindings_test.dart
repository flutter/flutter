// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=20210721"
@Tags(<String>['no-shuffle'])
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package;

void main() {
  final AutomatedTestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();

  group(TestViewConfiguration, () {
    test('is initialized with top-level window if one is not provided', () {
      // The code below will throw without the default.
      TestViewConfiguration(size: const Size(1280.0, 800.0));
    });
  });

  group(AutomatedTestWidgetsFlutterBinding, () {
    test('allows setting defaultTestTimeout to 5 minutes', () {
      binding.defaultTestTimeout = const test_package.Timeout(Duration(minutes: 5));
      expect(binding.defaultTestTimeout.duration, const Duration(minutes: 5));
    });
  });

  // The next three tests must run in order -- first using `test`, then `testWidgets`, then `test` again.

  int order = 0;

  test('Initializes httpOverrides and testTextInput', () async {
    assert(order == 0);
    expect(binding.testTextInput, isNotNull);
    expect(binding.testTextInput.isRegistered, isFalse);
    expect(HttpOverrides.current, isNotNull);
    order += 1;
  });

  testWidgets('Registers testTextInput', (WidgetTester tester) async {
    assert(order == 1);
    expect(tester.testTextInput.isRegistered, isTrue);
    order += 1;
  });

  test('Unregisters testTextInput', () async {
    assert(order == 2);
    expect(binding.testTextInput.isRegistered, isFalse);
    order += 1;
  });

  group('elapseBlocking', () {
    testWidgets('timer is not called', (WidgetTester tester) async {
      bool timerCalled = false;
      Timer.run(() => timerCalled = true);

      binding.elapseBlocking(const Duration(seconds: 1));

      expect(timerCalled, false);
      binding.idle();
    });

    testWidgets('can use to simulate slow build', (WidgetTester tester) async {
      final DateTime beforeTime = binding.clock.now();

      await tester.pumpWidget(Builder(builder: (_) {
        bool timerCalled = false;
        Timer.run(() => timerCalled = true);

        binding.elapseBlocking(const Duration(seconds: 1));

        // if we use `delayed` instead of `elapseBlocking`, such as
        // binding.delayed(const Duration(seconds: 1));
        // the timer will be called here. Surely, that violates how
        // a flutter widget build works
        expect(timerCalled, false);

        return Container();
      }));

      expect(binding.clock.now(), beforeTime.add(const Duration(seconds: 1)));
      binding.idle();
    });
  });

  testWidgets('Assets in the tester can be loaded without turning event loop', (WidgetTester tester) async {
    bool responded = false;
    // The particular asset does not matter, as long as it exists.
    rootBundle.load('AssetManifest.json').then((ByteData data) {
      responded = true;
    });
    expect(responded, true);
  });
}
