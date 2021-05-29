// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is for testings that require a `LiveTestWidgetsFlutterBinding`
void main() {
  LiveTestWidgetsFlutterBinding();
  testWidgets('Input PointerAddedEvent', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Test')));
    await tester.pump();
    final TestGesture gesture = await tester.createGesture();
    // This mimics the start of a gesture as seen on a device, where inputs
    // starts with a PointerAddedEvent.
    await gesture.addPointer();
    // The expected result of the test is not to trigger any assert.
  });

  testWidgets('Input PointerHoverEvent', (WidgetTester tester) async {
    PointerHoverEvent? hoverEvent;
    await tester.pumpWidget(MaterialApp(home: MouseRegion(
      child: const Text('Test'),
      onHover: (PointerHoverEvent event){
        hoverEvent = event;
      },
    )));
    await tester.pump();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final Offset location = tester.getCenter(find.text('Test'));
    // for mouse input without a down event, moveTo generates a hover event
    await gesture.moveTo(location);
    expect(hoverEvent, isNotNull);
    expect(hoverEvent!.position, location);
    await gesture.removePointer();
  });
}
