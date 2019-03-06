  // Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';

void main() {
  testWidgets('initialLifecycleState is used to init state paused', (WidgetTester tester) async {
    // Mock the Window to provide paused as the AppLifecycleState
    final TestWidgetsFlutterBinding binding = tester.binding;
    // Use paused as the initial state.
    binding.window.initialLifecycleStateTestValue = 'AppLifecycleState.paused';
    binding.initLifecycleState();

    expect(binding.window.initialLifecycleState, equals('AppLifecycleState.paused'));
    expect(SchedulerBinding.instance.lifecycleState.toString(), equals('AppLifecycleState.paused'));
  });
}