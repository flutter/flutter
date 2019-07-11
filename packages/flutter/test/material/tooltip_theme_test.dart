// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/src/material/tooltip_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

// This file uses "as dynamic" in a few places to defeat the static
// analysis. In general you want to avoid using this style in your
// code, as it will cause the analyzer to be unable to help you catch
// errors.
//
// In this case, we do it because we are trying to call internal
// methods of the tooltip code in order to test it. Normally, the
// state of a tooltip is a private class, but by using a GlobalKey we
// can get a handle to that object and by using "as dynamic" we can
// bypass the analyzer's type checks and call methods that we aren't
// supposed to be able to know about.
//
// It's ok to do this in tests, but you really don't want to do it in
// production code.

const String tooltipText = 'TIP';

void main() {
  testWidgets('Tooltip verticalOffset, preferBelow; center prefer above fits - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            tooltipTheme: const TooltipThemeData(
              height: 100.0,
              padding: EdgeInsets.all(0.0),
              verticalOffset: 100.0,
              preferBelow: false,
            ),
          ),
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
                          key: key,
                          message: tooltipText,
                          child: Container(
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
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
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

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(100.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(100.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(200.0));
  });

  testWidgets('Tooltip verticalOffset, preferBelow; center prefer above fits - TooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TooltipTheme(
          height: 100.0,
          padding: const EdgeInsets.all(0.0),
          verticalOffset: 100.0,
          preferBelow: false,
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
                          key: key,
                          message: tooltipText,
                          child: Container(
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
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
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

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(100.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(100.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(200.0));
  });

  testWidgets('Tooltip verticalOffset, preferBelow; center prefer above does not fit - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            tooltipTheme: const TooltipThemeData(
              height: 190.0,
              padding: EdgeInsets.all(0.0),
              verticalOffset: 100.0,
              preferBelow: false,
            ),
          ),
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
                          key: key,
                          message: tooltipText,
                          child: Container(
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
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
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

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(399.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(589.0));
  });

  testWidgets('Tooltip verticalOffset, preferBelow; center prefer above does not fit - TooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TooltipTheme(
          height: 190.0,
          padding: const EdgeInsets.all(0.0),
          verticalOffset: 100.0,
          preferBelow: false,
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
                          key: key,
                          message: tooltipText,
                          child: Container(
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
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
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

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(399.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(589.0));
  });

  testWidgets('Tooltip verticalOffset, preferBelow; center preferBelow fits - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            tooltipTheme: const TooltipThemeData(
              height: 190.0,
              padding: EdgeInsets.all(0.0),
              verticalOffset: 100.0,
              preferBelow: true,
            ),
          ),
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
                          key: key,
                          message: tooltipText,
                          child: Container(
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
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pumpAndSettle(); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=300.0
     *        _|_        * }-100.0 vertical offset
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(400.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(590.0));
  });

  testWidgets('Tooltip verticalOffset, preferBelow; center prefer below fits - TooltipTheme', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TooltipTheme(
          height: 190.0,
          padding: const EdgeInsets.all(0.0),
          verticalOffset: 100.0,
          preferBelow: true,
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
                          key: key,
                          message: tooltipText,
                          child: Container(
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
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pumpAndSettle(); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=300.0
     *        _|_        * }-100.0 vertical offset
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(400.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(590.0));
  });

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

  // test wait and show duration - themedata
  testWidgets('', (WidgetTester tester) async {});

  // test wait and show duration - theme widget
  testWidgets('', (WidgetTester tester) async {});

  testWidgets('Semantics included by default - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: const Center(
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
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Semantics included by default - TooltipTheme', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: TooltipTheme(
          child: const Center(
            child: Tooltip(
              message: 'Foo',
              child: Text('Bar'),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
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
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Semantics excluded - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          tooltipTheme: const TooltipThemeData(
            excludeFromSemantics: true,
          ),
        ),
        home: const Center(
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
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Semantics excluded - TooltipTheme', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: TooltipTheme(
          excludeFromSemantics: true,
          child: const Center(
            child: Tooltip(
              message: 'Foo',
              child: Text('Bar'),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
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
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('has semantic events by default - ThemeData.tooltipTheme', (WidgetTester tester) async {
    final List<dynamic> semanticEvents = <dynamic>[];
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvents.add(message);
    });
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
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
    SystemChannels.accessibility.setMockMessageHandler(null);
  });

  testWidgets('has semantic events by default - TooltipTheme', (WidgetTester tester) async {
    final List<dynamic> semanticEvents = <dynamic>[];
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvents.add(message);
    });
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: TooltipTheme(
          child: Center(
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
    SystemChannels.accessibility.setMockMessageHandler(null);
  });

  testWidgets('default Tooltip debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const Tooltip(message: 'message',).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      '"message"',
    ]);
  });
}

SemanticsNode findDebugSemantics(RenderObject object) {
  if (object.debugSemantics != null)
    return object.debugSemantics;
  return findDebugSemantics(object.parent);
}
