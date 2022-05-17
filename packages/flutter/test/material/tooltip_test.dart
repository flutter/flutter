// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

const String tooltipText = 'TIP';

Finder _findTooltipContainer(String tooltipText) {
  return find.ancestor(
    of: find.text(tooltipText),
    matching: find.byType(Container),
  );
}

void main() {
  testWidgets('Does tooltip end up in the right place - center', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 300.0,
                      top: 0.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 20.0,
                        padding: const EdgeInsets.all(5.0),
                        verticalOffset: 20.0,
                        preferBelow: false,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *      o            * y=0
     *      |            * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *   +----+          * \- (5.0 padding in height)
     *   |    |          * |- 20 height
     *   +----+          * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    final Offset tipInGlobal = tip.localToGlobal(tip.size.topCenter(Offset.zero));
    // The exact position of the left side depends on the font the test framework
    // happens to pick, so we don't test that.
    expect(tipInGlobal.dx, 300.0);
    expect(tipInGlobal.dy, 20.0);
  });

  testWidgets('Does tooltip end up in the right place - center with padding outside overlay', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) {
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        left: 300.0,
                        top: 0.0,
                        child: Tooltip(
                          key: tooltipKey,
                          message: tooltipText,
                          height: 20.0,
                          padding: const EdgeInsets.all(5.0),
                          verticalOffset: 20.0,
                          preferBelow: false,
                          child: const SizedBox(
                            width: 0.0,
                            height: 0.0,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /************************ 800x600 screen
     *   ________________   * }- 20.0 padding outside overlay
     *  |    o           |  * y=0
     *  |    |           |  * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *  | +----+         |  * \- (5.0 padding in height)
     *  | |    |         |  * |- 20 height
     *  | +----+         |  * /- (5.0 padding in height)
     *  |________________|  *
     *                      * } - 20.0 padding outside overlay
     ************************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    final Offset tipInGlobal = tip.localToGlobal(tip.size.topCenter(Offset.zero));
    // The exact position of the left side depends on the font the test framework
    // happens to pick, so we don't test that.
    expect(tipInGlobal.dx, 320.0);
    expect(tipInGlobal.dy, 40.0);
  });

  testWidgets('Does tooltip end up in the right place - top left', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0.0,
                      top: 0.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 20.0,
                        padding: const EdgeInsets.all(5.0),
                        verticalOffset: 20.0,
                        preferBelow: false,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *o                  * y=0
     *|                  * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *+----+             * \- (5.0 padding in height)
     *|    |             * |- 20 height
     *+----+             * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(24.0)); // 14.0 height + 5.0 padding * 2 (top, bottom)
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)), equals(const Offset(10.0, 20.0)));
  });

  testWidgets('Does tooltip end up in the right place - center prefer above fits', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 300.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 100.0,
                        padding: EdgeInsets.zero,
                        verticalOffset: 100.0,
                        preferBelow: false,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *        ___        * }- 10.0 margin
     *       |___|       * }-100.0 height
     *         |         * }-100.0 vertical offset
     *         o         * y=300.0
     *                   *
     *                   *
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(100.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(100.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(200.0));
  });

  testWidgets('Does tooltip end up in the right place - center prefer above does not fit', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 299.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 190.0,
                        padding: EdgeInsets.zero,
                        verticalOffset: 100.0,
                        preferBelow: false,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    // we try to put it here but it doesn't fit:
    /********************* 800x600 screen
     *        ___        * }- 10.0 margin
     *       |___|       * }-190.0 height (starts at y=9.0)
     *         |         * }-100.0 vertical offset
     *         o         * y=299.0
     *                   *
     *                   *
     *                   *
     *********************/

    // so we put it here:
    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=299.0
     *        _|_        * }-100.0 vertical offset
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(399.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(589.0));
  });

  testWidgets('Does tooltip end up in the right place - center prefer below fits', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 300.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 190.0,
                        padding: EdgeInsets.zero,
                        verticalOffset: 100.0,
                        preferBelow: true,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=300.0
     *        _|_        * }-100.0 vertical offset
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(400.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(590.0));
  });

  testWidgets('Does tooltip end up in the right place - way off to the right', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 1600.0,
                      top: 300.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 10.0,
                        padding: EdgeInsets.zero,
                        verticalOffset: 10.0,
                        preferBelow: true,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *                   * y=300.0;   target -->   o
     *              ___| * }-10.0 vertical offset
     *             |___| * }-10.0 height
     *                   *
     *                   * }-10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(14.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(310.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dx, equals(790.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(324.0));
  });

  testWidgets('Does tooltip end up in the right place - near the edge', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 780.0,
                      top: 300.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        height: 10.0,
                        padding: EdgeInsets.zero,
                        verticalOffset: 10.0,
                        preferBelow: true,
                        child: const SizedBox(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *                o  * y=300.0
     *              __|  * }-10.0 vertical offset
     *             |___| * }-10.0 height
     *                   *
     *                   * }-10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(14.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(310.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dx, equals(790.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(324.0));
  });

  testWidgets('Custom tooltip margin', (WidgetTester tester) async {
    const double customMarginValue = 10.0;
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Tooltip(
                  key: tooltipKey,
                  message: tooltipText,
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.all(customMarginValue),
                  child: const SizedBox(
                    width: 0.0,
                    height: 0.0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final Offset topLeftTipInGlobal = tester.getTopLeft(
      _findTooltipContainer(tooltipText),
    );
    final Offset topLeftTooltipContentInGlobal = tester.getTopLeft(find.text(tooltipText));
    expect(topLeftTooltipContentInGlobal.dx, topLeftTipInGlobal.dx + customMarginValue);
    expect(topLeftTooltipContentInGlobal.dy, topLeftTipInGlobal.dy + customMarginValue);

    final Offset topRightTipInGlobal = tester.getTopRight(
      _findTooltipContainer(tooltipText),
    );
    final Offset topRightTooltipContentInGlobal = tester.getTopRight(find.text(tooltipText));
    expect(topRightTooltipContentInGlobal.dx, topRightTipInGlobal.dx - customMarginValue);
    expect(topRightTooltipContentInGlobal.dy, topRightTipInGlobal.dy + customMarginValue);

    final Offset bottomLeftTipInGlobal = tester.getBottomLeft(
      _findTooltipContainer(tooltipText),
    );
    final Offset bottomLeftTooltipContentInGlobal = tester.getBottomLeft(find.text(tooltipText));
    expect(bottomLeftTooltipContentInGlobal.dx, bottomLeftTipInGlobal.dx + customMarginValue);
    expect(bottomLeftTooltipContentInGlobal.dy, bottomLeftTipInGlobal.dy - customMarginValue);

    final Offset bottomRightTipInGlobal = tester.getBottomRight(
      _findTooltipContainer(tooltipText),
    );
    final Offset bottomRightTooltipContentInGlobal = tester.getBottomRight(find.text(tooltipText));
    expect(bottomRightTooltipContentInGlobal.dx, bottomRightTipInGlobal.dx - customMarginValue);
    expect(bottomRightTooltipContentInGlobal.dy, bottomRightTipInGlobal.dy - customMarginValue);
  });

  testWidgets('Default tooltip message textStyle - light', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(MaterialApp(
      home: Tooltip(
        key: tooltipKey,
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<Text>(find.text(tooltipText)).style!;
    expect(textStyle.color, Colors.white);
    expect(textStyle.fontFamily, 'Roboto');
    expect(textStyle.decoration, TextDecoration.none);
    expect(textStyle.debugLabel, '((englishLike bodyMedium 2014).merge(blackMountainView bodyMedium)).copyWith');
  });

  testWidgets('Default tooltip message textStyle - dark', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: Tooltip(
        key: tooltipKey,
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<Text>(find.text(tooltipText)).style!;
    expect(textStyle.color, Colors.black);
    expect(textStyle.fontFamily, 'Roboto');
    expect(textStyle.decoration, TextDecoration.none);
    expect(textStyle.debugLabel, '((englishLike bodyMedium 2014).merge(whiteMountainView bodyMedium)).copyWith');
  });

  testWidgets('Custom tooltip message textStyle', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(MaterialApp(
      home: Tooltip(
        key: tooltipKey,
        textStyle: const TextStyle(
          color: Colors.orange,
          decoration: TextDecoration.underline,
        ),
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<Text>(find.text(tooltipText)).style!;
    expect(textStyle.color, Colors.orange);
    expect(textStyle.fontFamily, null);
    expect(textStyle.decoration, TextDecoration.underline);
  });

  testWidgets('Tooltip overlay respects ambient Directionality', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/40702.
    Widget buildApp(String text, TextDirection textDirection) {
      return MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: Center(
            child: Tooltip(
              message: text,
              child: Container(
                width: 100.0,
                height: 100.0,
                color: Colors.green[500],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(tooltipText, TextDirection.rtl));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    RenderParagraph tooltipRenderParagraph = tester.renderObject<RenderParagraph>(find.text(tooltipText));
    expect(tooltipRenderParagraph.textDirection, TextDirection.rtl);

    await tester.pumpWidget(buildApp(tooltipText, TextDirection.ltr));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    tooltipRenderParagraph = tester.renderObject<RenderParagraph>(find.text(tooltipText));
    expect(tooltipRenderParagraph.textDirection, TextDirection.ltr);
  });

  testWidgets('Tooltip overlay wrapped with a non-fallback DefaultTextStyle widget', (WidgetTester tester) async {
    // A Material widget is needed as an ancestor of the Text widget.
    // It is invalid to have text in a Material application that
    // does not have a Material ancestor.
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(MaterialApp(
      home: Tooltip(
        key: tooltipKey,
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<DefaultTextStyle>(
      find.ancestor(
        of: find.text(tooltipText),
        matching: find.byType(DefaultTextStyle),
      ).first,
    ).style;

    // The default fallback text style results in a text with a
    // double underline of Color(0xffffff00).
    expect(textStyle.decoration, isNot(TextDecoration.underline));
    expect(textStyle.decorationColor, isNot(const Color(0xffffff00)));
    expect(textStyle.decorationStyle, isNot(TextDecorationStyle.double));
  });

  testWidgets('Does tooltip end up with the right default size, shape, and color', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Tooltip(
                  key: tooltipKey,
                  message: tooltipText,
                  child: const SizedBox(
                    width: 0.0,
                    height: 0.0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(32.0));
    expect(tip.size.width, equals(74.0));
    expect(tip, paints..rrect(
      rrect: RRect.fromRectAndRadius(tip.paintBounds, const Radius.circular(4.0)),
      color: const Color(0xe6616161),
    ));
  });

  testWidgets('Tooltip default size, shape, and color test for Desktop', (WidgetTester tester) async {
    // Regressing test for https://github.com/flutter/flutter/issues/68601
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Tooltip(
          key: tooltipKey,
          message: tooltipText,
          child: const SizedBox(
            width: 0.0,
            height: 0.0,
          ),
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderParagraph tooltipRenderParagraph = tester.renderObject<RenderParagraph>(find.text(tooltipText));
    expect(tooltipRenderParagraph.textSize.height, equals(10.0));

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(24.0));
    expect(tip.size.width, equals(46.0));
    expect(tip, paints..rrect(
      rrect: RRect.fromRectAndRadius(tip.paintBounds, const Radius.circular(4.0)),
      color: const Color(0xe6616161),
    ));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.windows}));

  testWidgets('Can tooltip decoration be customized', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    const Decoration customDecoration = ShapeDecoration(
      shape: StadiumBorder(),
      color: Color(0x80800000),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Tooltip(
                  key: tooltipKey,
                  decoration: customDecoration,
                  message: tooltipText,
                  child: const SizedBox(
                    width: 0.0,
                    height: 0.0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(32.0));
    expect(tip.size.width, equals(74.0));
    expect(tip, paints..path(
      color: const Color(0x80800000),
    ));
  });

  testWidgets('Tooltip stays after long press', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
    TestGesture gesture = await tester.startGesture(tester.getCenter(tooltip));

    // long press reveals tooltip
    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);
    await gesture.up();

    // tap (down, up) gesture hides tooltip, since its not
    // a long press
    await tester.tap(tooltip);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsNothing);

    // long press once more
    gesture = await tester.startGesture(tester.getCenter(tooltip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(tooltipText), findsNothing);

    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);

    // keep holding the long press, should still show tooltip
    await tester.pump(kLongPressTimeout);
    expect(find.text(tooltipText), findsOneWidget);
    await gesture.up();
  });

  testWidgets('Dispatch the mouse events before tip overlay detached', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/96890
    const Duration waitDuration = Duration.zero;
    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      if (gesture != null)
        return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            waitDuration: waitDuration,
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    // Trigger the tip overlay.
    final Finder tooltip = find.byType(Tooltip);
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(waitDuration);

    // Remove the `Tooltip` widget.
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox.shrink(),
        ),
      ),
    );

    // The tooltip overlay still on the tree and it will removed in the next frame.

    // Dispatch the mouse in and out events before the overlay detached.
    await gesture.moveTo(tester.getCenter(find.text(tooltipText)));
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    // Go without crashes.
    await gesture.removePointer();
    gesture = null;
  });

  testWidgets('Tooltip shows/hides when hovered', (WidgetTester tester) async {
    const Duration waitDuration = Duration.zero;
    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      if (gesture != null)
        return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            waitDuration: waitDuration,
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(waitDuration);
    expect(find.text(tooltipText), findsOneWidget);

    // Wait a looong time to make sure that it doesn't go away if the mouse is
    // still over the widget.
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    // Wait for it to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip text is also hoverable', (WidgetTester tester) async {
    const Duration waitDuration = Duration.zero;
    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      gesture?.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            waitDuration: waitDuration,
            child: Text('I am tool tip'),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(waitDuration);
    expect(find.text(tooltipText), findsOneWidget);

    // Wait a looong time to make sure that it doesn't go away if the mouse is
    // still over the widget.
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    // Hover to the tool tip text and verify the tooltip doesn't go away.
    await gesture.moveTo(tester.getTopLeft(find.text(tooltipText)));
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    // Wait for it to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip should not show more than one tooltip when hovered', (WidgetTester tester) async {
    const Duration waitDuration = Duration(milliseconds: 500);
    final UniqueKey innerKey = UniqueKey();
    final UniqueKey outerKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Outer',
            child: Container(
              key: outerKey,
              width: 100,
              height: 100,
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'Inner',
                child: SizedBox(
                  key: innerKey,
                  width: 25,
                  height: 100,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async { gesture?.removePointer(); });

    // Both the inner and outer containers have tooltips associated with them, but only
    // the currently hovered one should appear, even though the pointer is inside both.
    final Finder outer = find.byKey(outerKey);
    final Finder inner = find.byKey(innerKey);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(outer));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(inner));
    await tester.pump();

    // Wait for it to appear.
    await tester.pump(waitDuration);

    expect(find.text('Outer'), findsNothing);
    expect(find.text('Inner'), findsOneWidget);
    await gesture.moveTo(tester.getCenter(outer));
    await tester.pump();
    // Wait for it to switch.
    await tester.pump(waitDuration);
    expect(find.text('Outer'), findsOneWidget);
    expect(find.text('Inner'), findsNothing);

    await gesture.moveTo(Offset.zero);

    // Wait for all tooltips to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
    expect(find.text('Outer'), findsNothing);
    expect(find.text('Inner'), findsNothing);
  });

  testWidgets('Tooltip can be dismissed by escape key', (WidgetTester tester) async {
    const Duration waitDuration = Duration.zero;
    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      if (gesture != null)
        return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            waitDuration: waitDuration,
            child: Text('I am tool tip'),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(waitDuration);
    expect(find.text(tooltipText), findsOneWidget);

    // Try to dismiss the tooltip with the shortcut key
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsNothing);

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
  });

  testWidgets('Multiple Tooltips are dismissed by escape key', (WidgetTester tester) async {
    const Duration waitDuration = Duration.zero;
    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      if (gesture != null)
        return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Column(
            children: const <Widget>[
              Tooltip(
                message: 'message1',
                waitDuration: waitDuration,
                showDuration: Duration(days: 1),
                child: Text('tooltip1'),
              ),
              Spacer(flex: 2),
              Tooltip(
                message: 'message2',
                waitDuration: waitDuration,
                showDuration: Duration(days: 1),
                child: Text('tooltip2'),
              )
            ],
          ),
        ),
      ),
    );

    final Finder tooltip = find.text('tooltip1');
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    await tester.pump(waitDuration);
    expect(find.text('message1'), findsOneWidget);

    final Finder secondTooltip = find.text('tooltip2');
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(secondTooltip));
    await tester.pump();
    await tester.pump(waitDuration);
    // Make sure both messages are on the screen.
    expect(find.text('message1'), findsOneWidget);
    expect(find.text('message2'), findsOneWidget);

    // Try to dismiss the tooltip with the shortcut key
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('message1'), findsNothing);
    expect(find.text('message2'), findsNothing);

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
  });

  testWidgets('Tooltip does not attempt to show after unmount', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/54096.
    const Duration waitDuration = Duration(seconds: 1);
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      if (gesture != null)
        return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            waitDuration: waitDuration,
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();

    // Pump another random widget to unmount the Tooltip widget.
    await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(),
        ),
      ),
    );

    // If the issue regresses, an exception will be thrown while we are waiting.
    await tester.pump(waitDuration);
  });

  testWidgets('Does tooltip contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 780.0,
                      top: 300.0,
                      child: Tooltip(
                        key: tooltipKey,
                        message: tooltipText,
                        child: const SizedBox(width: 10.0, height: 10.0),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    final TestSemantics expected = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          label: 'TIP',
          textDirection: TextDirection.ltr,
        ),
      ],
    );

    expect(semantics, hasSemantics(expected, ignoreTransform: true, ignoreRect: true));

    // This triggers a rebuild of the semantics because the tree changes.
    tooltipKey.currentState?.ensureTooltipVisible();

    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    expect(semantics, hasSemantics(expected, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Tooltip overlay does not update', (WidgetTester tester) async {
    Widget buildApp(String text) {
      return MaterialApp(
        home: Center(
          child: Tooltip(
            message: text,
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(tooltipText));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    await tester.pumpWidget(buildApp('NEW'));
    expect(find.text(tooltipText), findsOneWidget);
    await tester.tapAt(const Offset(5.0, 5.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(tooltipText), findsNothing);
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip text scales with textScaleFactor', (WidgetTester tester) async {
    Widget buildApp(String text, { required double textScaleFactor }) {
      return MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return Center(
                    child: Tooltip(
                      message: text,
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        color: Colors.green[500],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(tooltipText, textScaleFactor: 1.0));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    expect(tester.getSize(find.text(tooltipText)), equals(const Size(42.0, 14.0)));
    RenderBox tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(32.0));

    await tester.pumpWidget(buildApp(tooltipText, textScaleFactor: 4.0));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    expect(tester.getSize(find.text(tooltipText)), equals(const Size(168.0, 56.0)));
    tip = tester.renderObject(
      _findTooltipContainer(tooltipText),
    );
    expect(tip.size.height, equals(56.0));
  });

  testWidgets('Tooltip text displays with richMessage', (WidgetTester tester) async {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    const String textSpan1Text = 'I am a rich tooltip message. ';
    const String textSpan2Text = 'I am another span of a rich tooltip message';
    await tester.pumpWidget(
      MaterialApp(
        home: Tooltip(
          key: tooltipKey,
          richMessage: const TextSpan(
            text: textSpan1Text,
            children: <InlineSpan>[
              TextSpan(
                text: textSpan2Text,
              ),
            ],
          ),
          child: Container(
            width: 100.0,
            height: 100.0,
            color: Colors.green[500],
          ),
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RichText richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), equals('$textSpan1Text$textSpan2Text'));
  });

  testWidgets('Tooltip throws assertion error when both message and richMessage are specified', (WidgetTester tester) async {
    expect(
      () {
        MaterialApp(
          home: Tooltip(
            message: 'I am a tooltip message.',
            richMessage: const TextSpan(
              text: 'I am a rich tooltip.',
              children: <InlineSpan>[
                TextSpan(
                  text: 'I am another span of a rich tooltip.',
                ),
              ],
            ),
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        );
      },
      throwsA(const TypeMatcher<AssertionError>()),
    );
  });

  testWidgets('Haptic feedback', (WidgetTester tester) async {
    final FeedbackTester feedback = FeedbackTester();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(Tooltip));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.hapticCount, 1);

    feedback.dispose();
  });

  testWidgets('Semantics included', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Text('Bar'),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      label: 'Foo\nBar',
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Semantics excluded', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            excludeFromSemantics: true,
            child: Text('Bar'),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      label: 'Bar',
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    final List<dynamic> semanticEvents = <dynamic>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (dynamic message) async {
      semanticEvents.add(message);
    });
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(Tooltip));
    final RenderObject object = tester.firstRenderObject(find.byType(Tooltip));

    expect(semanticEvents, unorderedEquals(<dynamic>[
      <String, dynamic>{
        'type': 'longPress',
        'nodeId': findDebugSemantics(object).id,
        'data': <String, dynamic>{},
      },
      <String, dynamic>{
        'type': 'tooltip',
        'data': <String, dynamic>{
          'message': 'Foo',
        },
      },
    ]));
    semantics.dispose();
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null);
  });
  testWidgets('default Tooltip debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const Tooltip(message: 'message').debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      '"message"',
    ]);
  });
  testWidgets('default Tooltip debugFillProperties with richMessage', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const Tooltip(
      richMessage: TextSpan(
        text: 'This is a ',
        children: <InlineSpan>[
          TextSpan(
            text: 'richMessage',
          ),
        ],
      ),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      '"This is a richMessage"',
    ]);
  });
  testWidgets('Tooltip implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    // Not checking controller, inputFormatters, focusNode
    const Tooltip(
      key: ValueKey<String>('foo'),
      message: 'message',
      decoration: BoxDecoration(),
      waitDuration: Duration(seconds: 1),
      showDuration: Duration(seconds: 2),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.all(5.0),
      height: 100.0,
      excludeFromSemantics: true,
      preferBelow: false,
      verticalOffset: 50.0,
      triggerMode: TooltipTriggerMode.manual,
      enableFeedback: true,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      '"message"',
      'height: 100.0',
      'padding: EdgeInsets.zero',
      'margin: EdgeInsets.all(5.0)',
      'vertical offset: 50.0',
      'position: above',
      'semantics: excluded',
      'wait duration: 0:00:01.000000',
      'show duration: 0:00:02.000000',
      'triggerMode: TooltipTriggerMode.manual',
      'enableFeedback: true',
    ]);
  });

  testWidgets('Tooltip triggers on tap when trigger mode is tap', (WidgetTester tester) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap);

    final Finder tooltip = find.byType(Tooltip);
    expect(find.text(tooltipText), findsNothing);

    await testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip triggers on long press when mode is long press', (WidgetTester tester) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress);

    final Finder tooltip = find.byType(Tooltip);
    expect(find.text(tooltipText), findsNothing);

    await testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);

    await testGestureLongPress(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip does not trigger on tap when trigger mode is longPress', (WidgetTester tester) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress);

    final Finder tooltip = find.byType(Tooltip);
    expect(find.text(tooltipText), findsNothing);

    await testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip does not trigger when trigger mode is manual', (WidgetTester tester) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.manual);

    final Finder tooltip = find.byType(Tooltip);
    expect(find.text(tooltipText), findsNothing);

    await testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);

    await testGestureLongPress(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip should not be shown with empty message (with child)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Tooltip(
          message: tooltipText,
          child: Text(tooltipText),
        ),
      ),
    );
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip should not be shown with empty message (without child)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Tooltip(
          message: tooltipText,
        ),
      ),
    );
    expect(find.text(tooltipText), findsNothing);
    if (tooltipText.isEmpty) {
      expect(find.byType(SizedBox), findsOneWidget);
    }
  });
}

Future<void> setWidgetForTooltipMode(WidgetTester tester, TooltipTriggerMode triggerMode) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Tooltip(
        message: tooltipText,
        triggerMode: triggerMode,
        child: const SizedBox(width: 100.0, height: 100.0),
      ),
    ),
  );
}

Future<void> testGestureLongPress(WidgetTester tester, Finder tooltip) async {
  final TestGesture gestureLongPress = await tester.startGesture(tester.getCenter(tooltip));
  await tester.pump();
  await tester.pump(kLongPressTimeout);
  await gestureLongPress.up();
  await tester.pump();
}

Future<void> testGestureTap(WidgetTester tester, Finder tooltip) async {
  await tester.tap(tooltip);
  await tester.pump(const Duration(milliseconds: 10));
}

SemanticsNode findDebugSemantics(RenderObject object) {
  if (object.debugSemantics != null)
    return object.debugSemantics!;
  return findDebugSemantics(object.parent! as RenderObject);
}
