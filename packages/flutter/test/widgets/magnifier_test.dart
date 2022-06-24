// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('magnifier', () {
    testWidgets('should wrap to child size', (WidgetTester tester) async {
       final GlobalKey magnifierKey = GlobalKey();
      const Size maxSpaceSize = Size(100, 200);

      await tester.pumpWidget(Center(
        child: Magnifier(
          key: magnifierKey,
          child: SizedBox.fromSize(
            size: maxSpaceSize,
          ),
        ),
      ));

      expect(magnifierKey.currentContext!.size, maxSpaceSize);     
    });

    testWidgets('should expand to fill constraint area with no child',
        (WidgetTester tester) async {
      final GlobalKey magnifierKey = GlobalKey();
      const Size maxSpaceSize = Size(100, 200);

      await tester.pumpWidget(Center(
        child: SizedBox.fromSize(
          size: maxSpaceSize,
          child: Magnifier(key: magnifierKey),
        ),
      ));

      expect(magnifierKey.currentContext!.size, maxSpaceSize);
    });

    testWidgets('should have child overlay itself', (WidgetTester tester) async {
      const double totalHeight = 100;
      const Key rootKey = Key('rootSizedBox');

      /// Should be green stripe, than orange stripe,
      /// since the magnifiers child completely overlays the magnifier.
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          key: rootKey,
          children: <Widget>[
            Container(
              height: totalHeight / 2,
              color: const Color.fromARGB(255, 14, 255, 98),
            ),
            SizedBox(
                height: totalHeight / 2,
                width: double.infinity,
                child: Magnifier(
                  focalPoint: const Offset(0, totalHeight / 2),
                  child: Container(
                    color: const Color.fromARGB(255, 255, 128, 0),
                    width: double.infinity,
                    height: totalHeight / 2,
                  ),
                )),
          ],
        ),
      ));

      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('magnifier.child_overlay.png'),
      );
    });
  });

  testWidgets('should overlay other widgets', (WidgetTester tester) async {
    const double totalHeight = 100;
    const Key rootKey = Key('rootSizedBox');

    /// Should be solid green, since the magnifier is completely
    /// overlapping the orange.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        key: rootKey,
        children: <Widget>[
          Container(
            height: totalHeight / 2,
            color: const Color.fromARGB(255, 14, 255, 98),
          ),
          Stack(children: <Widget>[
            Container(
              color: const Color.fromARGB(255, 255, 128, 0),
              width: double.infinity,
              height: totalHeight / 2,
            ),
             SizedBox(
                height: totalHeight / 2,
                width: double.infinity,
                child: Magnifier(
                  focalPoint: const Offset(0, totalHeight / 2),
                )),
          ]),
        ],
      ),
    ));

    await expectLater(
      find.byKey(rootKey),
      matchesGoldenFile('magnifier.overlay_widget.png'),
    );
  });
}
