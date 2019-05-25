// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';

void main() {
  testWidgets('initialLifecycleState is used to init state paused', (WidgetTester tester) async {
    // The lifecycleState is null initially in tests as there is no
    // initialLifecycleState.
    expect(SchedulerBinding.instance.lifecycleState, equals(null));
    // Mock the Window to provide paused as the AppLifecycleState
    final TestWidgetsFlutterBinding binding = tester.binding;
    // Use paused as the initial state.
    binding.window.initialLifecycleStateTestValue = 'AppLifecycleState.paused';
    binding.readTestInitialLifecycleStateFromNativeWindow(); // Re-attempt the initializaiton.

    // The lifecycleState should now be the state we passed above,
    // even though no lifecycle event was fired from the platform.
    expect(SchedulerBinding.instance.lifecycleState.toString(), equals('AppLifecycleState.paused'));
  });
}
