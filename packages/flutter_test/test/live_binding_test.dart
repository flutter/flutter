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
    await binding.setSurfaceSize(const Size(200, 200));
    final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(200, 200));
    final Widget target = MaterialApp(
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
    );

    await tester.pumpWidget(target);

    final TestGesture gesture = await tester.createGesture();
    await gesture.down(tester.getCenter(find.byType(Text)) + const Offset(10, 10));

    await tester.pumpFrames(animationSheet.record(target, fullscreen: true), const Duration(seconds: 1));

    debugDumpLayerTree();

    await gesture.up(timeStamp: const Duration(seconds: 1));

    await tester.pumpFrames(animationSheet.record(target, fullscreen: true), const Duration(seconds: 1));

    // tester.binding.setSurfaceSize(animationSheet.sheetSize());
    // final Widget display = await animationSheet.display();
    // await tester.pumpWidget(display);
    await expectLater(
      await animationSheet.composite(),
      matchesGoldenFile('LiveBinding.press.animation.png'),
    );
  });
}
