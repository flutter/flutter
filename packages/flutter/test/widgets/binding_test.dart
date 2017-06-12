// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MemoryPressureObserver extends WidgetsBindingObserver {
  bool sawMemoryPressure = false;

  @override
  void didHaveMemoryPressure() {
    sawMemoryPressure = true;
  }
}

class AppLifecycleStateObserver extends WidgetsBindingObserver {
  AppLifecycleState lifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycleState = state;
  }
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('didHaveMemoryPressure callback', (WidgetTester tester) async {
    final MemoryPressureObserver observer = new MemoryPressureObserver();
    WidgetsBinding.instance.addObserver(observer);
    final ByteData message = const JSONMessageCodec().encodeMessage(
      <String, dynamic>{'type': 'memoryPressure'});
    await BinaryMessages.handlePlatformMessage('flutter/system', message, (_) {});
    expect(observer.sawMemoryPressure, true);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('handleLifecycleStateChanged callback', (WidgetTester tester) async {
    final AppLifecycleStateObserver observer = new AppLifecycleStateObserver();
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
}
