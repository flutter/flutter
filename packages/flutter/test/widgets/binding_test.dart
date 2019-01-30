// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MemoryPressureObserver with WidgetsBindingObserver {
  bool sawMemoryPressure = false;

  @override
  void didHaveMemoryPressure() {
    sawMemoryPressure = true;
  }
}

class AppLifecycleStateObserver with WidgetsBindingObserver {
  AppLifecycleState lifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycleState = state;
  }
}

class PushRouteObserver with WidgetsBindingObserver {
  String pushedRoute;

  @override
  Future<bool> didPushRoute(String route) async {
    pushedRoute = route;
    return true;
  }
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('didHaveMemoryPressure callback', (WidgetTester tester) async {
    final MemoryPressureObserver observer = MemoryPressureObserver();
    WidgetsBinding.instance.addObserver(observer);
    final ByteData message = const JSONMessageCodec().encodeMessage(
      <String, dynamic>{'type': 'memoryPressure'});
    await BinaryMessages.handlePlatformMessage('flutter/system', message, (_) {});
    expect(observer.sawMemoryPressure, true);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('handleLifecycleStateChanged callback', (WidgetTester tester) async {
    final AppLifecycleStateObserver observer = AppLifecycleStateObserver();
    WidgetsBinding.instance.addObserver(observer);

    ByteData message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(observer.lifecycleState, AppLifecycleState.paused);

    message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(observer.lifecycleState, AppLifecycleState.resumed);

    message = const StringCodec().encodeMessage('AppLifecycleState.inactive');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(observer.lifecycleState, AppLifecycleState.inactive);

    message = const StringCodec().encodeMessage('AppLifecycleState.suspending');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(observer.lifecycleState, AppLifecycleState.suspending);
  });

  testWidgets('didPushRoute callback', (WidgetTester tester) async {
    final PushRouteObserver observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const String testRouteName = 'testRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRoute', testRouteName));
    await BinaryMessages.handlePlatformMessage('flutter/navigation', message, (_) {});
    expect(observer.pushedRoute, testRouteName);

    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('Application lifecycle affects frame scheduling', (WidgetTester tester) async {
    ByteData message;
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.inactive');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.suspending');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.inactive');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await BinaryMessages.handlePlatformMessage('flutter/lifecycle', message, (_) {});
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleFrame();
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleForcedFrame();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    int frameCount = 0;
    tester.binding.addPostFrameCallback((Duration duration) { frameCount += 1; });
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(frameCount, 0);

    tester.binding.scheduleWarmUpFrame(); // this actually tests flutter_test's implementation
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(frameCount, 1);
  });
}
