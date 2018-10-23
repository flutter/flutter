// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(MouseDetector, () {
    testWidgets('detects pointer enter', (WidgetTester tester) async {
      MouseEnterDetails enter;
      MouseMoveDetails move;
      MouseExitDetails exit;
      await tester.pumpWidget(Center(
        child: MouseDetector(
          child: Container(
            color: const Color.fromARGB(0xff, 0xff, 0x00, 0x00),
            width: 100.0,
            height: 100.0,
          ),
          onEnter: (MouseEnterDetails details) => enter = details,
          onMove: (MouseMoveDetails details) => move = details,
          onExit: (MouseExitDetails details) => exit = details,
        ),
      ));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 300.0));
      await tester.pump();
      expect(move, isNotNull);
      expect(move.globalPosition, equals(const Offset(400.0, 300.0)));
      expect(enter, isNotNull);
      expect(enter.globalPosition, equals(const Offset(400.0, 300.0)));
      expect(exit, isNull);
    });
    testWidgets('detects pointer exit', (WidgetTester tester) async {
      MouseEnterDetails enter;
      MouseMoveDetails move;
      MouseExitDetails exit;
      await tester.pumpWidget(Center(
        child: MouseDetector(
          child: Container(
            width: 100.0,
            height: 100.0,
          ),
          onEnter: (MouseEnterDetails details) => enter = details,
          onMove: (MouseMoveDetails details) => move = details,
          onExit: (MouseExitDetails details) => exit = details,
        ),
      ));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 300.0));
      await tester.pump();
      move = null;
      enter = null;
      await gesture.moveTo(const Offset(1.0, 1.0));
      await tester.pump();
      expect(move, isNull);
      expect(enter, isNull);
      expect(exit, isNotNull);
      expect(exit.globalPosition, equals(const Offset(1.0, 1.0)));
    });
    testWidgets('detects pointer exit when widget disappears', (WidgetTester tester) async {
      MouseEnterDetails enter;
      MouseMoveDetails move;
      MouseExitDetails exit;
      await tester.pumpWidget(Center(
        child: MouseDetector(
          child: Container(
            width: 100.0,
            height: 100.0,
          ),
          onEnter: (MouseEnterDetails details) => enter = details,
          onMove: (MouseMoveDetails details) => move = details,
          onExit: (MouseExitDetails details) => exit = details,
        ),
      ));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 300.0));
      await tester.pump();
      expect(move, isNotNull);
      expect(move.globalPosition, equals(const Offset(400.0, 300.0)));
      expect(enter, isNotNull);
      expect(enter.globalPosition, equals(const Offset(400.0, 300.0)));
      expect(exit, isNull);
      await tester.pumpWidget(Center(
        child: Container(
          width: 100.0,
          height: 100.0,
        ),
      ));
      expect(exit, isNotNull);
      expect(exit.globalPosition, equals(const Offset(400.0, 300.0)));
    });
  });
}
