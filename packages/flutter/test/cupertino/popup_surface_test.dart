// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('light painted appearance', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: buildRainbowPopupSurface(isSurfacePainted: true),
      ),
    );

    // Golden verifies the backdrop filter effect of the CupertinoPopupSurface
    // in dark mode when the popup surface is painted.
    await expectLater(
      find.byType(CupertinoApp),
      matchesGoldenFile('cupertinoPopupSurface.light.filter-effects.png'),
    );
  });

  testWidgets('dark painted appearance', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: buildRainbowPopupSurface(isSurfacePainted: true),
      ),
    );

    // Golden matches the backdrop filter effect of the CupertinoPopupSurface
    // in dark mode when the popup surface is painted.
    await expectLater(
      find.byType(CupertinoApp),
      matchesGoldenFile('cupertinoPopupSurface.dark.filter-effects.png'),
    );
  });

  testWidgets('unpainted appearance', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: buildRainbowPopupSurface(isSurfacePainted: false),
      ),
    );

    // Golden matches the backdrop filter effect of the CupertinoPopupSurface in
    // dark mode and light mode when the popup surface is unpainted. The
    // brightness should not affect the appearance of the popup surface.
    await expectLater(
      find.byType(CupertinoApp),
      matchesGoldenFile('cupertinoPopupSurface.unpainted.filter-effects.png'),
    );

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: buildRainbowPopupSurface(isSurfacePainted: false),
      ),
    );

    await expectLater(
      find.byType(CupertinoApp),
      matchesGoldenFile('cupertinoPopupSurface.unpainted.filter-effects.png'),
    );
  });
}

Widget buildRainbowPopupSurface({required bool isSurfacePainted}) {
  return ColoredBox(
    color: const Color(0xFF000000),
    child: Builder(
      builder: (BuildContext context) {
        final Size size = MediaQuery.sizeOf(context);
        final double tileHeight = size.height / 2;
        final double tileWidth = size.width / 18;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (int i = 0; i < 18; i++)
              Positioned(
                left: i * tileWidth,
                top: i.isOdd ? tileHeight : 0,
                height: tileHeight,
                width: tileWidth,
                child: i.isOdd
                    ? Container(
                        color: HSVColor.fromAHSV(0.7, i * 20, 0.7, 1).toColor(),
                      )
                    : Container(
                        color: HSVColor.fromAHSV(1, i * 20, 1, 1).toColor(),
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoPopupSurface(isSurfacePainted: isSurfacePainted),
            ),
            for (int i = 0; i < 18; i += 1)
              Positioned(
                left: i * tileWidth,
                top: i.isEven ? tileHeight : 0,
                height: tileHeight,
                width: tileWidth,
                child: i.isEven
                    ? Container(
                        color: HSVColor.fromAHSV(0.7, i * 20, 0.7, 1).toColor(),
                      )
                    : Container(
                        color: HSVColor.fromAHSV(0.5, i * 20, 1.0, 1).toColor(),
                      ),
              ),
          ],
        );
      },
    ),
  );
}
