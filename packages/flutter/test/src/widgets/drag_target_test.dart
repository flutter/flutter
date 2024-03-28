// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Draggable feedback matches pointer in unscaled MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Draggable<int>(
          data: 42,
          feedback: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.red,
          ),
        ),
      ),
    ));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Container)));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    final Offset appTopLeft = tester.getTopLeft(find.byType(MaterialApp));
    final Finder finder = find.byType(Container);
    expect(finder, findsNWidgets(2));
    expect(tester.getTopLeft(finder.at(0)), appTopLeft);
    expect(tester.getTopLeft(finder.at(1)), appTopLeft + const Offset(100, 100));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Draggable feedback matches pointer in scaled MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(Transform.scale(
      scale: 0.5,
      child: MaterialApp(
        home: Scaffold(
          body: Draggable<int>(
            data: 42,
            feedback: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.red,
            ),
          ),
        ),
      ),
    ));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Container)));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    final Offset appTopLeft = tester.getTopLeft(find.byType(MaterialApp));
    final Finder finder = find.byType(Container);
    expect(finder, findsNWidgets(2));
    expect(tester.getTopLeft(finder.at(0)), appTopLeft);
    expect(tester.getTopLeft(finder.at(1)), appTopLeft + const Offset(100, 100));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
