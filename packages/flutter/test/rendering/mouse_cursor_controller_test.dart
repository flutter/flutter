// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Should work on platforms that does not support mouse cursor', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final MethodChannel mockChannel = SystemChannels.mouseCursor;

    mockChannel.setMockMethodCallHandler((MethodCall call) async {
      return null;
    });

    await MouseCursorController.activateSystemCursor(device: 10, shapeCode: 100);

    // Passes if no errors are thrown
  });

  test('activateSystemCursor(should correctly pass argument', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final List<MethodCall> logs = <MethodCall>[];
    final MethodChannel mockChannel = SystemChannels.mouseCursor;

    mockChannel.setMockMethodCallHandler((MethodCall call) async {
      logs.add(call);
      return true;
    });
    await MouseCursorController.activateSystemCursor(device: 10, shapeCode: 100);
    expectMethodCallsEquals(logs, const <MethodCall>[
      MethodCall('activateSystemCursor', <String, dynamic>{'device': 10, 'shapeCode': 100}),
    ]);
    logs.clear();

  });

  test('Should throw a PlatformException when an error occurs', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final MethodChannel mockChannel = SystemChannels.mouseCursor;

    mockChannel.setMockMethodCallHandler((MethodCall call) async {
      throw ArgumentError('some error');
    });
    await expectLater(
      MouseCursorController.activateSystemCursor(device: 12, shapeCode: 102),
      throwsA(isInstanceOf<PlatformException>()));
  });
}

void expectMethodCallsEquals(dynamic subject, List<MethodCall> target) {
  expect(subject is List<MethodCall>, true);
  final List<MethodCall> list = subject as List<MethodCall>;
  expect(list.length, target.length);
  for (int i = 0; i < list.length; i++) {
    expect(list[i].method, target[i].method);
    expect(list[i].arguments, equals(target[i].arguments));
  }
}
