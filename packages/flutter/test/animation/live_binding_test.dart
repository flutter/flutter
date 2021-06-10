// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /*
   * Here lies golden tests for packages/flutter_test/lib/src/binding.dart
   * because [matchesGoldenFile] does not use Skia Gold in its native package.
   */

  LiveTestWidgetsFlutterBinding();

  testWidgets('Should show event indicator for pointer events', (WidgetTester tester) async {
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
      animationSheet.collate(6),
      matchesGoldenFile('LiveBinding.press.animation.png'),
    );
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/42767
}
