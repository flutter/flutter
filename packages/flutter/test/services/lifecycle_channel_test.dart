// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // This replaces the binding's handler for SystemChannels.lifecycle, so it is
  // kept in its own file.
  testWidgets('appLifecycleState changes are delivered on the deprecated lifecycle channel', (
    WidgetTester tester,
  ) async {
    final TestWidgetsFlutterBinding binding = tester.binding;
    addTearDown(binding.platformDispatcher.clearAppLifecycleStateTestValue);
    final messages = <String?>[];
    SystemChannels.lifecycle.setMessageHandler((String? message) async {
      messages.add(message);
      return null;
    });
    addTearDown(() => SystemChannels.lifecycle.setMessageHandler(null));

    binding.platformDispatcher.appLifecycleStateTestValue = AppLifecycleState.resumed;
    binding.platformDispatcher.appLifecycleStateTestValue = AppLifecycleState.paused;
    await tester.idle();

    expect(messages, <String>['AppLifecycleState.resumed', 'AppLifecycleState.paused']);
  });
}
