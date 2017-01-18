// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SystemChrome overlay style test', (WidgetTester tester) async {
    // The first call is a cache miss and will queue a microtask
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    expect(tester.binding.microtaskCount, equals(1));

    // Flush all microtasks
    await tester.idle();
    expect(tester.binding.microtaskCount, equals(0));

    // The second call with the same value should be a no-op
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    expect(tester.binding.microtaskCount, equals(0));
  });

  test('setPreferredOrientations control test', () async {
    List<String> log = <String>[];

    PlatformMessages.setMockStringMessageHandler('flutter/platform', (String message) async {
      log.add(message);
    });

    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);

    expect(log, equals(<String>['{"method":"SystemChrome.setPreferredOrientations","args":[["DeviceOrientation.portraitUp"]]}']));
  });

  test('setApplicationSwitcherDescription control test', () async {
    List<String> log = <String>[];

    PlatformMessages.setMockStringMessageHandler('flutter/platform', (String message) async {
      log.add(message);
    });

    await SystemChrome.setApplicationSwitcherDescription(
      new ApplicationSwitcherDescription(label: 'Example label', primaryColor: 0xFF00FF00)
    );

    expect(log, equals(<String>['{"method":"SystemChrome.setApplicationSwitcherDescription","args":[{"label":"Example label","primaryColor":4278255360}]}']));
  });

  test('setEnabledSystemUIOverlays control test', () async {
    List<String> log = <String>[];

    PlatformMessages.setMockStringMessageHandler('flutter/platform', (String message) async {
      log.add(message);
    });

    await SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[SystemUiOverlay.top]);

    expect(log, equals(<String>['{"method":"SystemChrome.setEnabledSystemUIOverlays","args":[["SystemUiOverlay.top"]]}']));
  });
}
