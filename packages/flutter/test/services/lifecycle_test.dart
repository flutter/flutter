// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('initialLifecycleState is used to init state paused', (WidgetTester tester) async {
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.resetInternalState();
    // Use paused as the initial state.
    binding.platformDispatcher.initialLifecycleStateTestValue = 'AppLifecycleState.paused';
    binding.readTestInitialLifecycleStateFromNativeWindow(); // Re-attempt the initialization.

    // The lifecycleState should now be the state we passed above,
    // even though no lifecycle event was fired from the platform.
    expect(binding.lifecycleState.toString(), equals('AppLifecycleState.paused'));
  });
  testWidgets('Unknown lifecycle states are ignored', (WidgetTester tester) async {
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.resetInternalState();
    binding.platformDispatcher.initialLifecycleStateTestValue = 'AppLifecycleState.unknown';
    binding.readTestInitialLifecycleStateFromNativeWindow();
    expect(binding.lifecycleState, isNull);

    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StringCodec().encodeMessage('AppLifecycleState.unknown'),
      (_) {},
    );
    expect(binding.lifecycleState, isNull);
  });
  testWidgets('Handles all of the allowed states of AppLifecycleState', (
    WidgetTester tester,
  ) async {
    final TestWidgetsFlutterBinding binding = tester.binding;
    for (final AppLifecycleState state in AppLifecycleState.values) {
      binding.resetInternalState();
      binding.platformDispatcher.initialLifecycleStateTestValue = state.toString();
      binding.readTestInitialLifecycleStateFromNativeWindow();
      expect(ServicesBinding.instance.lifecycleState.toString(), equals(state.toString()));
    }
  });
  testWidgets(
    'readInitialLifecycleStateFromNativeWindow prefers appLifecycleState over initialLifecycleState',
    (WidgetTester tester) async {
      final TestWidgetsFlutterBinding binding = tester.binding;
      addTearDown(binding.platformDispatcher.clearAppLifecycleStateTestValue);
      binding.platformDispatcher.initialLifecycleStateTestValue = 'AppLifecycleState.paused';
      binding.platformDispatcher.appLifecycleStateTestValue = AppLifecycleState.hidden;
      // Setting the test value already updated the state, so clear it to test
      // the initial read.
      binding.resetInternalState();
      binding.readTestInitialLifecycleStateFromNativeWindow();
      expect(binding.lifecycleState, AppLifecycleState.hidden);
    },
  );
  testWidgets('onAppLifecycleStateChanged generates state transitions', (
    WidgetTester tester,
  ) async {
    final TestWidgetsFlutterBinding binding = tester.binding;
    addTearDown(binding.platformDispatcher.clearAppLifecycleStateTestValue);
    final states = <AppLifecycleState>[];
    final listener = AppLifecycleListener(onStateChange: states.add);
    addTearDown(listener.dispose);

    binding.platformDispatcher.appLifecycleStateTestValue = AppLifecycleState.resumed;
    states.clear();
    binding.platformDispatcher.appLifecycleStateTestValue = AppLifecycleState.paused;
    expect(binding.lifecycleState, AppLifecycleState.paused);
    expect(states, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
  });
  test('AppLifecycleState values are in the right order for the state machine to be correct', () {
    expect(
      AppLifecycleState.values,
      equals(<AppLifecycleState>[
        AppLifecycleState.detached,
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]),
    );
  });
}
