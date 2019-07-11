// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/material/tooltip_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

const String tooltipText = 'TIP';

void main() {
  testWidgets('Tooltip decoration - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    const Decoration customDecoration = ShapeDecoration(
      shape: StadiumBorder(),
      color: Color(0x80800000),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            tooltipTheme: const TooltipThemeData(
              decoration: customDecoration,
            ),
          ),
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) {
                  return Tooltip(
                    key: key,
                    message: tooltipText,
                    child: Container(
                      width: 0.0,
                      height: 0.0,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent.parent.parent.parent;

    expect(tip.size.height, equals(32.0));
    expect(tip.size.width, equals(74.0));
    expect(tip, paints..path(
      color: const Color(0x80800000),
    ));
  }, skip: isBrowser);

  testWidgets('Tooltip decoration - TooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    const Decoration customDecoration = ShapeDecoration(
      shape: StadiumBorder(),
      color: Color(0x80800000),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TooltipTheme(
          decoration: customDecoration,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) {
                  return Tooltip(
                    key: key,
                    message: tooltipText,
                    child: Container(
                      width: 0.0,
                      height: 0.0,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent.parent.parent.parent;

    expect(tip.size.height, equals(32.0));
    expect(tip.size.width, equals(74.0));
    expect(tip, paints..path(
      color: const Color(0x80800000),
    ));
  }, skip: isBrowser);

  testWidgets('Tooltip height and padding - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    const double customTooltipHeight = 100.0;
    const double customPaddingVal = 20.0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            tooltipTheme: const TooltipThemeData(
              height: customTooltipHeight,
              padding: EdgeInsets.all(customPaddingVal),
            ),
          ),
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) {
                  return Tooltip(
                    key: key,
                    message: tooltipText,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pumpAndSettle();

    final RenderBox tip = tester.renderObject(find.ancestor(
      of: find.text(tooltipText),
      matching: find.byType(Padding),
    ));
    final RenderBox content = tester.renderObject(find.ancestor(
      of: find.text(tooltipText),
      matching: find.byType(Center),
    ));

    expect(tip.size.height, equals(customTooltipHeight));
    expect(content.size.height, equals(customTooltipHeight - 2 * customPaddingVal));
    expect(content.size.width, equals(tip.size.width - 2 * customPaddingVal));
  }, skip: isBrowser);

  testWidgets('Tooltip height and padding - TooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    const double customTooltipHeight = 100.0;
    const double customPaddingVal = 20.0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TooltipTheme(
          height: customTooltipHeight,
          padding: const EdgeInsets.all(customPaddingVal),
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) {
                  return Tooltip(
                    key: key,
                    message: tooltipText,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pumpAndSettle();

    final RenderBox tip = tester.renderObject(find.ancestor(
      of: find.text(tooltipText),
      matching: find.byType(Padding),
    ));
    final RenderBox content = tester.renderObject(find.ancestor(
      of: find.text(tooltipText),
      matching: find.byType(Center),
    ));

    expect(tip.size.height, equals(customTooltipHeight));
    expect(content.size.height, equals(customTooltipHeight - 2 * customPaddingVal));
    expect(content.size.width, equals(tip.size.width - 2 * customPaddingVal));
  }, skip: isBrowser);

  // test vertical offset = themedata
  testWidgets('', (WidgetTester tester) async {});

  // test vertical offset = themewidget
  testWidgets('', (WidgetTester tester) async {});

  // test preferbelow - themedata
  testWidgets('', (WidgetTester tester) async {});

  // test preferbelow - theme widget
  testWidgets('', (WidgetTester tester) async {});

  // test wait and show duration - themedata
  testWidgets('', (WidgetTester tester) async {});

  // test wait and show duration - theme widget
  testWidgets('', (WidgetTester tester) async {});

  // test semantics - themedata
  testWidgets('', (WidgetTester tester) async {});

  // test semantics = theme widget
  testWidgets('', (WidgetTester tester) async {});
}
// TODO: Add tests verifying theme behaviors