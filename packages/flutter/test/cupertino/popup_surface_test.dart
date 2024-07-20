// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _FilterTest extends StatelessWidget {
  const _FilterTest(Widget child, {this.brightness = Brightness.light})
      : _child = child;
  final Brightness brightness;
  final Widget _child;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double tileHeight = size.height / 4;
    final double tileWidth = size.width / 8;
    return CupertinoApp(
      home: Stack(fit: StackFit.expand, children: <Widget>[
        // 512 color tiles
        // 4 alpha levels (0.416, 0.25, 0.5, 0.75)
        for (int a = 0; a < 4; a++)
          for (int h = 0; h < 8; h++) // 8 hues
            for (int s = 0; s < 4; s++) // 4 saturation levels
              for (int b = 0; b < 4; b++) // 4 brightness levels
                Positioned(
                  left: h * tileWidth + b * tileWidth / 4,
                  top: a * tileHeight + s * tileHeight / 4,
                  height: tileHeight,
                  width: tileWidth,
                  child: ColoredBox(
                    color: HSVColor.fromAHSV(
                      0.5 + a / 8,
                      h * 45,
                      0.5 + s / 8,
                      0.5 + b / 8,
                    ).toColor(),
                  ),
                ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: CupertinoTheme(
            data: CupertinoThemeData(brightness: brightness),
            child: _child,
          ),
        ),
      ]),
    );
  }
}

void main() {
  group('Color filter', () {
    testWidgets('Brightness.light color filter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            blurSigma: 0,
            isSurfacePainted: false,
            child: SizedBox(),
          ),
        ),
      );

      // Golden displays the color filter effect of the CupertinoPopupSurface
      // in light mode.
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.color-filter.light.png'),
      );
    });
    testWidgets('Brightness.dark color filter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            blurSigma: 0,
            isSurfacePainted: false,
            child: SizedBox(),
          ),
          brightness: Brightness.dark,
        ),
      );

      // Golden displays the color filter effect of the CupertinoPopupSurface
      // in dark mode.
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.color-filter.dark.png'),
      );
    });
    testWidgets('Setting isVibrancePainted to false removes the color filter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            blurSigma: 0,
            isSurfacePainted: false,
            isVibrancePainted: false,
            child: SizedBox(),
          ),
        ),
      );

      // The BackdropFilter widget should not be mounted when blurSigma is 0 and
      // CupertinoPopupSurface.isVibrancePainted is false.
      expect(
        find.descendant(
          of: find.byType(CupertinoPopupSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });
  });
  group('Surface Color', () {
    testWidgets('Brightness.light surface', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: ColoredBox(
            color: Color(0xff000000),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(32),
                  child: CupertinoPopupSurface(
                    blurSigma: 0,
                    isVibrancePainted: false,
                    child: SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Golden displays the surface color of the CupertinoPopupSurface
      // in light mode.
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.surface-color.light.png'),
      );
    });
    testWidgets('Brightness.dark surface', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: ColoredBox(
            color: Color(0xffffffff),
            child: Padding(
                padding: EdgeInsets.all(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CupertinoTheme(
                      data: CupertinoThemeData(brightness: Brightness.dark),
                      child: CupertinoPopupSurface(
                        blurSigma: 0,
                        isVibrancePainted: false,
                        child: SizedBox(),
                      ),
                    ),
                  ],
                )),
          ),
        ),
      );

      // Golden displays the surface color of the CupertinoPopupSurface
      // in dark mode.
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.surface-color.dark.png'),
      );
    });
    testWidgets('Setting isSurfacePainted to false removes the surface color', (WidgetTester tester) async {
      await tester.pumpWidget(const CupertinoApp(
        home: ColoredBox(
          color: Color(0xff000000),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CupertinoPopupSurface(
                blurSigma: 0,
                isVibrancePainted: false,
                isSurfacePainted: false,
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ));

      // Golden displays a CupertinoPopupSurface with the color removed (should
      // be empty).
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.surface-color.removed.png'),
      );
    });
  });
  group('Blur', () {
    testWidgets('Positive blurSigma applies blur', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            isSurfacePainted: false,
            isVibrancePainted: false,
            blurSigma: 5,
            child: SizedBox(),
          ),
        ),
      );

      // Golden displays a CupertinoPopupSurface with no vibrance or surface
      // color, and a blur sigma of 5
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.blur.5.png'),
      );

      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            isSurfacePainted: false,
            isVibrancePainted: false,
            blurSigma: 15,
            child: SizedBox(),
          ),
        ),
      );

      // Golden displays a CupertinoPopupSurface with no vibrance or surface
      // color, and a blur sigma of 30.
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.blur.30.png'),
      );

      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            isSurfacePainted: false,
            isVibrancePainted: false,
            child: SizedBox(),
          ),
        ),
      );

      // Golden displays a CupertinoPopupSurface with no vibrance or surface
      // color, and a blur sigma of 30.
      await expectLater(
        find.byType(CupertinoApp),
        // 30 is the default blur sigma
        matchesGoldenFile('cupertinoPopupSurface.blur.30.png'),
      );
    });
    testWidgets('Nonpositive blurSigma removes blur', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            isSurfacePainted: false,
            isVibrancePainted: false,
            blurSigma: 0,
            child: SizedBox(),
          ),
        ),
      );

      // The BackdropFilter widget should not be mounted when blurSigma is 0 and
      // CupertinoPopupSurface.isVibrancePainted is false.
      expect(
        find.descendant(
          of: find.byType(CupertinoPopupSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );

      // Golden displays a CupertinoPopupSurface with a blur sigma of 0. Because
      // the blur sigma == 0 and vibrance and surface are not painted, no popup
      // surface is displayed.
      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.blur.0.png'),
      );

      await tester.pumpWidget(
        const _FilterTest(
          CupertinoPopupSurface(
            isSurfacePainted: false,
            isVibrancePainted: false,
            blurSigma: -100,
            child: SizedBox(),
          ),
        ),
      );

      // Golden displays a CupertinoPopupSurface with a blur sigma of -100. Because
      // the blur sigma < 0 and vibrance and surface are not painted, no popup
      // surface is displayed.
      expect(
        find.descendant(
          of: find.byType(CupertinoPopupSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );

      await expectLater(
        find.byType(CupertinoApp),
        matchesGoldenFile('cupertinoPopupSurface.blur.0.png'),
      );
    });
  });

  // Because ImageFilter.compose is used to apply multiple filters, the order
  // of the filters matters. As such, test that the surface effects are stacked
  // in the correct order.
  testWidgets('Composition', (WidgetTester tester) async {
    await tester.pumpWidget(
      const _FilterTest(
        CupertinoPopupSurface(
          child: SizedBox(),
        ),
      ),
    );

    await expectLater(
      find.byType(CupertinoApp),
      matchesGoldenFile('cupertinoPopupSurface.composition.png'),
    );
  });
}
