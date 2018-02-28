// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Haptic feedback control test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await HapticFeedback.vibrate();

    expect(log, hasLength(1));
    expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: null));
  });

  test('Haptic feedback variation tests', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    const List<Function> hapticFunctions = const <Function>[
      HapticFeedback.lightImpact,
      HapticFeedback.mediumImpact,
      HapticFeedback.heavyImpact,
      HapticFeedback.selectionClick,
    ];
    final RegExp functionName = new RegExp(r".*\'(\w+)\'");

    for (int i = 0; i < hapticFunctions.length; i++) {
      await Function.apply(hapticFunctions[i], null);
      expect(log, hasLength(i + 1));
      expect(
        log.last,
        isMethodCall(
          'HapticFeedback.vibrate',
          arguments: 'HapticFeedbackType.${functionName.firstMatch(hapticFunctions[i].toString()).group(1)}',
        ),
      );
    }
  });
}
