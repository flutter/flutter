// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('initialLifecycleState is used to init state paused', (WidgetTester tester) async {
    // The lifecycleState is null initially in tests as there is no
    // initialLifecycleState.
    expect(ServicesBinding.instance.lifecycleState, equals(null));
    // Mock the Window to provide paused as the AppLifecycleState
    final TestWidgetsFlutterBinding binding = tester.binding;
    // Use paused as the initial state.
    binding.platformDispatcher.initialLifecycleStateTestValue = 'AppLifecycleState.paused';
    binding.readTestInitialLifecycleStateFromNativeWindow(); // Re-attempt the initialization.

    // The lifecycleState should now be the state we passed above,
    // even though no lifecycle event was fired from the platform.
    expect(ServicesBinding.instance.lifecycleState.toString(), equals('AppLifecycleState.paused'));
  });
}
