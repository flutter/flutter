// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is for testings that require a `LiveTestWidgetsFlutterBinding`
void main() {
  final LiveTestWidgetsFlutterBinding binding = LiveTestWidgetsFlutterBinding();
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

  testWidgets('Should render on pointer events', (WidgetTester tester) async {
    final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(200, 200), allLayers: true);
    final Widget target = Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 25, 20),
      child: animationSheet.record(
        MaterialApp(
          home: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 128, 128, 128),
              border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(target);

    await tester.pumpFrames(target, const Duration(milliseconds: 50));

    final TestGesture gesture1 = await tester.createGesture();
    await gesture1.down(tester.getCenter(find.byType(Text)) + const Offset(10, 10));

    await tester.pumpFrames(target, const Duration(milliseconds: 100));

    final TestGesture gesture2 = await tester.createGesture();
    await gesture2.down(tester.getTopLeft(find.byType(Text)) + const Offset(30, -10));
    await gesture1.moveBy(const Offset(50, 50));

    await tester.pumpFrames(target, const Duration(milliseconds: 100));
    await gesture1.up();
    await gesture2.up();
    await tester.pumpFrames(target, const Duration(milliseconds: 50));

    await expectLater(
      await animationSheet.composite(1200),
      matchesGoldenFile('LiveBinding.press.animation.png'),
    );
  });
}
