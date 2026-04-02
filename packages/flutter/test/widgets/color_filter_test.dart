// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
@TestOn('!chrome')
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

void main() {
  const debugRed = Color(0xFFFF0000);
  const debugGreen = Color(0xFF00FF00);
  const debugBlue = Color(0xFF0000FF);
  const debugWhite = Color(0xFFFFFFFF);

  testWidgets('Color filter - red', (WidgetTester tester) async {
    await tester.pumpWidget(
      const RepaintBoundary(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(debugRed, BlendMode.color),
          child: Placeholder(),
        ),
      ),
    );
    await expectLater(find.byType(ColorFiltered), matchesGoldenFile('color_filter_red.png'));
  });

  testWidgets('Color filter - sepia', (WidgetTester tester) async {
    // A lighter blue so the sepia matrix
    // produces a visible warm brown instead of near-black.
    const debugLightBlue = Color(0xFF2196F3);
    const sepia = ColorFilter.matrix(<double>[
      0.39, 0.769, 0.189, 0, 0, //
      0.349, 0.686, 0.168, 0, 0, //
      0.272, 0.534, 0.131, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
    await tester.pumpWidget(
      const RepaintBoundary(
        child: ColorFiltered(
          colorFilter: sepia,
          child: TestWidgetsApp(
            home: ColoredBox(
              color: debugWhite,
              child: Column(
                children: <Widget>[
                  ColoredBox(
                    color: debugLightBlue,
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: Center(child: Text('Sepia ColorFilter Test')),
                    ),
                  ),
                  Expanded(child: Center(child: Text('Hooray!'))),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: debugLightBlue, shape: BoxShape.circle),
                          child: Center(child: Text('+')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byType(ColorFiltered), matchesGoldenFile('color_filter_sepia.png'));
  });

  testWidgets('ColorFilter.saturation', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: ColorFiltered(
          colorFilter: ColorFilter.saturation(0),
          child: const ColoredBox(color: debugWhite, child: FlutterLogo()),
        ),
      ),
    );
    await expectLater(find.byType(ColorFiltered), matchesGoldenFile('color_filter_saturation.png'));
  });

  testWidgets('Color filter - reuses its layer', (WidgetTester tester) async {
    Future<void> pumpWithColor(Color color) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.color),
            child: const Placeholder(),
          ),
        ),
      );
    }

    await pumpWithColor(debugRed);
    final RenderObject renderObject = tester.firstRenderObject(find.byType(ColorFiltered));
    final originalLayer = renderObject.debugLayer! as ColorFilterLayer;
    expect(originalLayer, isNotNull);

    // Change color to force a repaint.
    await pumpWithColor(debugGreen);
    expect(renderObject.debugLayer, same(originalLayer));
  });

  testWidgets('ColorFiltered does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: ColorFiltered(colorFilter: ColorFilter.mode(debugBlue, BlendMode.color)),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ColorFiltered)), Size.zero);
  });
}
