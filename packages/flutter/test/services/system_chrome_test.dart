// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
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

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(label: 'Example label', primaryColor: 0xFF00FF00),
    );

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setApplicationSwitcherDescription',
      arguments: <String, dynamic>{'label': 'Example label', 'primaryColor': 4278255360},
    ));
  });

  test('setApplicationSwitcherDescription missing plugin', () async {
    final List<ByteData?> log = <ByteData>[];

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMessageHandler('flutter/platform', (ByteData? message) async {
      log.add(message);
    });

    await SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(label: 'Example label', primaryColor: 0xFF00FF00),
    );

    expect(log, isNotEmpty);
  });

  test('setEnabledSystemUIOverlays control test', () async {
    final List<MethodCall> log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[SystemUiOverlay.top]);

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setEnabledSystemUIOverlays',
      arguments: <String>['SystemUiOverlay.top'],
    ));
  });

  test('setEnabledSystemUIMode control test', () async {
    final List<MethodCall> log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setEnabledSystemUIMode',
      arguments: 'SystemUiMode.leanBack',
    ));
  });

  test('setEnabledSystemUIMode asserts for overlays in manual configuration', () async {
    expect(
      () async {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);
      },
      throwsA(
        isA<AssertionError>().having((AssertionError error) => error.toString(),
            'description', contains('mode == SystemUiMode.manual && overlays != null')),
      ),
    );
  });

  test('setEnabledSystemUIMode passes correct overlays for manual configuration', () async {
    final List<MethodCall> log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: <SystemUiOverlay>[SystemUiOverlay.top]);

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setEnabledSystemUIOverlays',
      arguments: <String>['SystemUiOverlay.top'],
    ));
  });

  test('setSystemUIChangeCallback control test', () async {
    final List<MethodCall> log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemChrome.setSystemUIChangeCallback(null);
    expect(log, hasLength(0));

    await SystemChrome.setSystemUIChangeCallback((bool overlaysAreVisible) async {});
    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemChrome.setSystemUIChangeListener',
      arguments: null,
    ));
  });

  test('toString works as intended', () async {
    const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle();

    expect(systemUiOverlayStyle.toString(), 'SystemUiOverlayStyle({'
      'systemNavigationBarColor: null, '
      'systemNavigationBarDividerColor: null, '
      'systemStatusBarContrastEnforced: true, '
      'statusBarColor: null, '
      'statusBarBrightness: null, '
      'statusBarIconBrightness: null, '
      'systemNavigationBarIconBrightness: null, '
      'systemNavigationBarContrastEnforced: true})',
    );
  });
}
