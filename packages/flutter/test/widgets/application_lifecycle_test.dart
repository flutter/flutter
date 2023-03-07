// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance
        ..resetEpoch()
        ..platformDispatcher.onBeginFrame = null
        ..platformDispatcher.onDrawFrame = null;
  });

  Future<void> setAppLifeCycleState(AppLifecycleState state) async {
    final ByteData? message =
        const StringCodec().encodeMessage(state.toString());
    await ServicesBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('flutter/lifecycle', message, (_) {});
  }

  Future<void> sendAppExitRequest() async {
    final ByteData message =
        const StandardMethodCodec().encodeMethodCall(const MethodCall('System.requestAppExit'));
    await ServicesBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('flutter/platform', message, (_) {});
  }

  testWidgets('listens to AppLifecycleState', (WidgetTester tester) async {
    AppLifecycleState lastState = AppLifecycleState.detached;
    void stateChange(AppLifecycleState state) {
      lastState = state;
    }
    final AppLifecycleListener listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onStateChange: stateChange,
    );
    expect(lastState, equals(AppLifecycleState.detached));
    await setAppLifeCycleState(AppLifecycleState.inactive);
    expect(lastState, equals(AppLifecycleState.inactive));
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(lastState, equals(AppLifecycleState.resumed));
  });

  testWidgets('Receives exit requests', (WidgetTester tester) async {
    bool exitRequested = false;
    Future<AppExitResponse> handleExitRequested() async {
      exitRequested = true;
      return AppExitResponse.cancel;
    }
    final AppLifecycleListener listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onExitRequested: handleExitRequested,
    );
    await sendAppExitRequest();
    expect(exitRequested, isTrue);
  });
}