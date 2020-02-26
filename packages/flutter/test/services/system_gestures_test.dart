// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('setSystemGestureExclusionRects control test', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await SystemGestures.setSystemGestureExclusionRects(
      rects: <Rect>[const Rect.fromLTRB(0, 0, 100, 100)],
      devicePixelRatio: 1.0,
    );

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'SystemGestures.setSystemGestureExclusionRects',
      arguments: <Map<String, int>>[
        <String, int>{
          'left': 0,
          'top': 0,
          'right': 100,
          'bottom': 100,
        }
      ],
    ));
  });

  testWidgets('getSystemGestureExclusionRects control test', (WidgetTester tester) async {
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      return <Map<String, int>>[
        <String, int>{
          'left': 0,
          'top': 0,
          'right': 100,
          'bottom': 100,
        }
      ];
    });

    final List<Rect> result = await SystemGestures.getSystemGestureExclusionRects(
      devicePixelRatio: 1.0,
    );
    expect(result, <Rect>[const Rect.fromLTRB(0, 0, 100, 100)]);
  });
}
