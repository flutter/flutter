// Copyright 2014 The Flutter Authors. All rights reserved.
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
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setPreferredOrientations',
      arguments: <String>['DeviceOrientation.portraitUp'],
    ));
  });

  test('setApplicationSwitcherDescription control test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(label: 'Example label', primaryColor: 0xFF00FF00)
    );

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setApplicationSwitcherDescription',
      arguments: <String, dynamic>{'label': 'Example label', 'primaryColor': 4278255360},
    ));
  });

  test('setApplicationSwitcherDescription missing plugin', () async {
    final List<ByteData?> log = <ByteData>[];

    ServicesBinding.instance!.defaultBinaryMessenger.setMockMessageHandler('flutter/platform', (ByteData? message) async {
      log.add(message);
    });

    await SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(label: 'Example label', primaryColor: 0xFF00FF00)
    );

    expect(log, isNotEmpty);
  });

  test('setEnabledSystemUIOverlays control test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[SystemUiOverlay.top]);

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setEnabledSystemUIOverlays',
      arguments: <String>['SystemUiOverlay.top'],
    ));
  });
}
