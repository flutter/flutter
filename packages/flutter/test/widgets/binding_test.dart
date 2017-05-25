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
}
