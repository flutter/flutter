// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/selection_area/selection_area.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final _MockClipboard mockClipboard = _MockClipboard();

  testWidgets('SelectionArea smoke test', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      mockClipboard.handleMethodCall,
    );

    await tester.pumpWidget(
      const example.SelectionAreaExampleApp(),
    );

    expect(find.byType(SelectionArea), findsExactly(1));

    Finder finder = find.descendant(
      of: find.byType(SelectionArea),
      matching: find.descendant(
        of: find.byType(AppBar),
        matching: find.text('SelectionArea Sample'),
      ),
    );

    expect(finder, findsExactly(1));
    expect(mockClipboard.clipboardData, isNull);

    finder = find.text('SelectionArea Sample');
    final Rect rect = tester.getRect(finder);

    await tester.dragFrom(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);

    expect(mockClipboard.clipboardData?['text'], 'SelectionArea Sample');
  });
}

class _MockClipboard {
  _MockClipboard();

  Map<String, dynamic>? clipboardData;

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.setData':
        clipboardData = methodCall.arguments as Map<String, dynamic>;
        return null;
    }
    if (methodCall.method.startsWith('Clipboard')) {
      throw StateError('unrecognized method call: ${methodCall.method}');
    }
    return null;
  }
}
