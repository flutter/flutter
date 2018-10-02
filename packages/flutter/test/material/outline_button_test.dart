// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Outline button responds to tap when enabled', (WidgetTester tester) async {
    int pressedCount = 0;

    Widget buildFrame(VoidCallback onPressed) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(),
          child: Center(
            child: OutlineButton(onPressed: onPressed),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildFrame(() { pressedCount += 1; }),
    );
    expect(tester.widget<OutlineButton>(find.byType(OutlineButton)).enabled, true);
    await tester.tap(find.byType(OutlineButton));
    await tester.pumpAndSettle();
    expect(pressedCount, 1);

    await tester.pumpWidget(
      buildFrame(null),
    );
    final Finder outlineButton = find.byType(OutlineButton);
    expect(tester.widget<OutlineButton>(outlineButton).enabled, false);
    await tester.tap(outlineButton);
    await tester.pumpAndSettle();
    expect(pressedCount, 1);
  });


  testWidgets('OutlineButton shape and border component overrides', (WidgetTester tester) async {
    const Color fillColor = Color(0xFF00FF00);
    const Color borderColor = Color(0xFFFF0000);
    const Color highlightedBorderColor = Color(0xFF0000FF);
    const Color disabledBorderColor = Color(0xFFFF00FF);
    const double borderWidth = 4.0;

    Widget buildFrame({VoidCallback onPressed}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Container(
            alignment: Alignment.topLeft,
            child: OutlineButton(
              shape: const RoundedRectangleBorder(), // default border radius is 0
              clipBehavior: Clip.antiAlias,
              color: fillColor,
              highlightedBorderColor: highlightedBorderColor,
              disabledBorderColor: disabledBorderColor,
              borderSide: const BorderSide(
                width: borderWidth,
                color: borderColor,
              ),
              onPressed: onPressed,
              child: const Text('button'),
            ),
          ),
        ),
      );
    }

    final Rect clipRect = Rect.fromLTRB(0.0, 0.0, 116.0, 36.0);
    final Path clipPath = Path()..addRect(clipRect);

    final Finder outlineButton = find.byType(OutlineButton);

    // Pump a button with a null onPressed callback to make it disabled.
    await tester.pumpWidget(
      buildFrame(onPressed: null),
    );

    // Expect that the button is disabled and painted with the disabled border color.
    expect(tester.widget<OutlineButton>(outlineButton).enabled, false);
    expect(
      outlineButton, //find.byType(OutlineButton),
      paints
        ..clipPath(pathMatcher: coversSameAreaAs(clipPath, areaToCompare: clipRect.inflate(10.0)))
        ..path(color: disabledBorderColor, strokeWidth: borderWidth));

    // Pump a new button with a no-op onPressed callback to make it enabled.
    await tester.pumpWidget(
      buildFrame(onPressed: () { }),
    );

    // Wait for the border color to change from disabled to enabled.
    await tester.pumpAndSettle();

    // Expect that the button is disabled and painted with the enabled border color.
    expect(tester.widget<OutlineButton>(outlineButton).enabled, true);
    expect(
      outlineButton,
      paints
        // initially the interior of the button is transparent
        ..path(color: fillColor.withAlpha(0x00))
        ..clipPath(pathMatcher: coversSameAreaAs(clipPath, areaToCompare: clipRect.inflate(10.0)))
        ..path(color: borderColor, strokeWidth: borderWidth));

    final Offset center = tester.getCenter(outlineButton);
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    // Wait for the border's color to change to highlightedBorderColor and
    // the fillColor to become opaque.
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      outlineButton,
      paints
        ..path(color: fillColor.withAlpha(0xFF))
        ..clipPath(pathMatcher: coversSameAreaAs(clipPath, areaToCompare: clipRect.inflate(10.0)))
        ..path(color: highlightedBorderColor, strokeWidth: borderWidth));

    // Tap gesture completes, button returns to its initial configuration.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      outlineButton,
      paints
        ..path(color: fillColor.withAlpha(0x00))
        ..clipPath(pathMatcher: coversSameAreaAs(clipPath, areaToCompare: clipRect.inflate(10.0)))
        ..path(color: borderColor, strokeWidth: borderWidth));
  });

  testWidgets('OutlineButton has no clip by default', (WidgetTester tester) async {
    final GlobalKey buttonKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton(
                key: buttonKey,
                onPressed: () { },
                child: const Text('ABC'),
            ),
          ),
        ),
      ),
    );

    expect(
        tester.renderObject(find.byKey(buttonKey)),
        paintsExactlyCountTimes(#clipPath, 0)
    );
  });

  testWidgets('OutlineButton contributes semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton(
              onPressed: () { },
              child: const Text('ABC'),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            actions: <SemanticsAction>[
              SemanticsAction.tap,
            ],
            label: 'ABC',
            rect: Rect.fromLTRB(0.0, 0.0, 88.0, 48.0),
            transform: Matrix4.translationValues(356.0, 276.0, 0.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isEnabled,
            ],
          )
        ],
      ),
      ignoreId: true,
    ));

    semantics.dispose();
  });


  testWidgets('OutlineButton scales textScaleFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.0),
            child: Center(
              child: OutlineButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(OutlineButton)), equals(const Size(88.0, 48.0)));
    expect(tester.getSize(find.byType(Text)), equals(const Size(42.0, 14.0)));

    // textScaleFactor expands text, but not button.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.3),
            child: Center(
              child: FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FlatButton)), equals(const Size(88.0, 48.0)));
    // Scaled text rendering is different on Linux and Mac by one pixel.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.byType(Text)).width, isIn(<double>[54.0, 55.0]));
    expect(tester.getSize(find.byType(Text)).height, isIn(<double>[18.0, 19.0]));

    // Set text scale large enough to expand text and button.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 3.0),
            child: Center(
              child: FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    // Scaled text rendering is different on Linux and Mac by one pixel.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.byType(FlatButton)).width, isIn(<double>[158.0, 159.0]));
    expect(tester.getSize(find.byType(FlatButton)).height, equals(48.0));
    expect(tester.getSize(find.byType(Text)).width, isIn(<double>[126.0, 127.0]));
    expect(tester.getSize(find.byType(Text)).height, equals(42.0));
  });

  testWidgets('OutlineButton implements debugFillDescription', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    OutlineButton(
        onPressed: () {},
        textColor: const Color(0xFF00FF00),
        disabledTextColor: const Color(0xFFFF0000),
        color: const Color(0xFF000000),
        highlightColor: const Color(0xFF1565C0),
        splashColor: const Color(0xFF9E9E9E),
        child: const Text('Hello'),
    ).debugFillProperties(builder);
    final List<String> description = builder.properties
        .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode n) => n.toString()).toList();
    expect(description, <String>[
      'textColor: Color(0xff00ff00)',
      'disabledTextColor: Color(0xffff0000)',
      'color: Color(0xff000000)',
      'highlightColor: Color(0xff1565c0)',
      'splashColor: Color(0xff9e9e9e)',
    ]);
  });
}
