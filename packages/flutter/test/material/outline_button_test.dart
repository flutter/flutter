// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('OutlineButton implements debugFillProperties', (WidgetTester tester) async {
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
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'textColor: Color(0xff00ff00)',
      'disabledTextColor: Color(0xffff0000)',
      'color: Color(0xff000000)',
      'highlightColor: Color(0xff1565c0)',
      'splashColor: Color(0xff9e9e9e)',
    ]);
  });

  testWidgets('Default OutlineButton meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              child: const Text('OutlineButton'),
              onPressed: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    // Default, not disabled.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Hovered.
    final Offset center = tester.getCenter(find.byType(OutlineButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  },
    semanticsEnabled: true,
    skip: isBrowser,
  );

  testWidgets('OutlineButton with colored theme meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    final ColorScheme colorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.blue);

    Color getTextColor(Set<MaterialState> states) {
      final Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue[900];
      }
      return Colors.blue[800];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ButtonTheme(
              colorScheme: colorScheme,
              textTheme: ButtonTextTheme.primary,
              child: OutlineButton(
                child: const Text('OutlineButton'),
                onPressed: () {},
                focusNode: focusNode,
                textColor: MaterialStateColor.resolveWith(getTextColor),
              ),
            ),
          ),
        ),
      ),
    );

    // Default, not disabled.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Hovered.
    final Offset center = tester.getCenter(find.byType(OutlineButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  },
    skip: isBrowser,
    semanticsEnabled: true,
  );

  testWidgets('OutlineButton uses stateful color for text color in different states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              child: const Text('OutlineButton'),
              onPressed: () {},
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('OutlineButton')).text.style.color;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(OutlineButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(textColor(), hoverColor);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    expect(textColor(), pressedColor);
  });

  testWidgets('OutlineButton uses stateful color for icon color in different states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final Key buttonKey = UniqueKey();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton.icon(
              key: buttonKey,
              icon: const Icon(Icons.add),
              label: const Text('OutlineButton'),
              onPressed: () {},
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
            ),
          ),
        ),
      ),
    );

    Color iconColor() => _iconStyle(tester, Icons.add).color;
    // Default, not disabled.
    expect(iconColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(iconColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byKey(buttonKey));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(iconColor(), hoverColor);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    expect(iconColor(), pressedColor);
  });

  testWidgets('OutlineButton ignores disabled text color if text color is stateful', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color disabledColor = Color(0x00000001);
    const Color defaultColor = Color(0x00000002);
    const Color unusedDisabledTextColor = Color(0x00000003);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return disabledColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              onPressed: null,
              child: const Text('OutlineButton'),
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
              disabledTextColor: unusedDisabledTextColor,
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('OutlineButton')).text.style.color;
    }

    // Disabled.
    expect(textColor(), equals(disabledColor));
    expect(textColor(), isNot(unusedDisabledTextColor));
  });

  testWidgets('OutlineButton uses stateful color for border color in different states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getBorderColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              child: const Text('OutlineButton'),
              onPressed: () {},
              focusNode: focusNode,
              borderSide: BorderSide(color: MaterialStateColor.resolveWith(getBorderColor)),
            ),
          ),
        ),
      ),
    );

    final Finder outlineButton = find.byType(OutlineButton);

    // Default, not disabled.
    expect(outlineButton, paints..path(color: defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(outlineButton, paints..path(color: focusedColor));

    // Hovered.
    final Offset center = tester.getCenter(find.byType(OutlineButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(outlineButton, paints..path(color: hoverColor));

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pumpAndSettle();
    expect(outlineButton, paints..path(color: pressedColor));
  });

  testWidgets('OutlineButton ignores highlightBorderColor if border color is stateful', (WidgetTester tester) async {
    const Color pressedColor = Color(0x00000001);
    const Color defaultColor = Color(0x00000002);
    const Color ignoredPressedColor = Color(0x00000003);

    Color getBorderColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              child: const Text('OutlineButton'),
              onPressed: () {},
              borderSide: BorderSide(color: MaterialStateColor.resolveWith(getBorderColor)),
              highlightedBorderColor: ignoredPressedColor,
            ),
          ),
        ),
      ),
    );

    final Finder outlineButton = find.byType(OutlineButton);

    // Default, not disabled.
    expect(outlineButton, paints..path(color: defaultColor));

    // Highlighted (pressed).
    await tester.press(outlineButton);
    await tester.pumpAndSettle();
    expect(outlineButton, paints..path(color: pressedColor));
  });

  testWidgets('OutlineButton ignores disabledBorderColor if border color is stateful', (WidgetTester tester) async {
    const Color disabledColor = Color(0x00000001);
    const Color defaultColor = Color(0x00000002);
    const Color ignoredDisabledColor = Color(0x00000003);

    Color getBorderColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return disabledColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              child: const Text('OutlineButton'),
              onPressed: null,
              borderSide: BorderSide(color: MaterialStateColor.resolveWith(getBorderColor)),
              highlightedBorderColor: ignoredDisabledColor,
            ),
          ),
        ),
      ),
    );

    // Disabled.
    expect(find.byType(OutlineButton), paints..path(color: disabledColor));
  });

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

  testWidgets('Outline button doesn\'t crash if disabled during a gesture', (WidgetTester tester) async {
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

    await tester.pumpWidget(buildFrame(() {}));
    await tester.press(find.byType(OutlineButton));
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
  });

  testWidgets('OutlineButton shape and border component overrides', (WidgetTester tester) async {
    const Color fillColor = Color(0xFF00FF00);
    const Color borderColor = Color(0xFFFF0000);
    const Color highlightedBorderColor = Color(0xFF0000FF);
    const Color disabledBorderColor = Color(0xFFFF00FF);
    const double borderWidth = 4.0;

    Widget buildFrame({ VoidCallback onPressed }) {
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
              // Causes the button to be filled with the theme's canvasColor
              // instead of Colors.transparent before the button material's
              // elevation is animated to 2.0.
              highlightElevation: 2.0,
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

    const Rect clipRect = Rect.fromLTRB(0.0, 0.0, 116.0, 36.0);
    final Path clipPath = Path()..addRect(clipRect);

    final Finder outlineButton = find.byType(OutlineButton);

    // Pump a button with a null onPressed callback to make it disabled.
    await tester.pumpWidget(
      buildFrame(onPressed: null),
    );

    // Expect that the button is disabled and painted with the disabled border color.
    expect(tester.widget<OutlineButton>(outlineButton).enabled, false);
    expect(
      outlineButton,
      paints
        ..path(color: disabledBorderColor, strokeWidth: borderWidth));
    _checkPhysicalLayer(
      tester.element(outlineButton),
      const Color(0x00000000),
      clipPath: clipPath,
      clipRect: clipRect,
    );

    // Pump a new button with a no-op onPressed callback to make it enabled.
    await tester.pumpWidget(
      buildFrame(onPressed: () {}),
    );

    // Wait for the border color to change from disabled to enabled.
    await tester.pumpAndSettle();

    // Expect that the button is enabled and painted with the enabled border color.
    expect(tester.widget<OutlineButton>(outlineButton).enabled, true);
    expect(
      outlineButton,
      paints
        ..path(color: borderColor, strokeWidth: borderWidth));
    // initially, the interior of the button is transparent
    _checkPhysicalLayer(
      tester.element(outlineButton),
      fillColor.withAlpha(0x00),
      clipPath: clipPath,
      clipRect: clipRect,
    );

    final Offset center = tester.getCenter(outlineButton);
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    // Wait for the border's color to change to highlightedBorderColor and
    // the fillColor to become opaque.
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      outlineButton,
      paints
        ..path(color: highlightedBorderColor, strokeWidth: borderWidth));
    _checkPhysicalLayer(
      tester.element(outlineButton),
      fillColor.withAlpha(0xFF),
      clipPath: clipPath,
      clipRect: clipRect,
    );

    // Tap gesture completes, button returns to its initial configuration.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      outlineButton,
      paints
        ..path(color: borderColor, strokeWidth: borderWidth));
    _checkPhysicalLayer(
      tester.element(outlineButton),
      fillColor.withAlpha(0x00),
      clipPath: clipPath,
      clipRect: clipRect,
    );
  }, skip: isBrowser);

  testWidgets('OutlineButton has no clip by default', (WidgetTester tester) async {
    final GlobalKey buttonKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton(
              key: buttonKey,
              onPressed: () {},
              child: const Text('ABC'),
            ),
          ),
        ),
      ),
    );

    expect(
        tester.renderObject(find.byKey(buttonKey)),
        paintsExactlyCountTimes(#clipPath, 0),
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
              onPressed: () {},
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
            rect: const Rect.fromLTRB(0.0, 0.0, 88.0, 48.0),
            transform: Matrix4.translationValues(356.0, 276.0, 0.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isButton,
              SemanticsFlag.isEnabled,
              SemanticsFlag.isFocusable,
            ],
          ),
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
                onPressed: () {},
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
                onPressed: () {},
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
                onPressed: () {},
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
  }, skip: isBrowser);

  testWidgets('OutlineButton pressed fillColor default', (WidgetTester tester) async {
    Widget buildFrame(ThemeData theme) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: OutlineButton(
              onPressed: () {},
              // Causes the button to be filled with the theme's canvasColor
              // instead of Colors.transparent before the button material's
              // elevation is animated to 2.0.
              highlightElevation: 2.0,
              child: const Text('Hello'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(ThemeData.dark()));
    final Finder button = find.byType(OutlineButton);
    final Element buttonElement = tester.element(button);
    final Offset center = tester.getCenter(button);

    // Default value for dark Theme.of(context).canvasColor as well as
    // the OutlineButton fill color when the button has been pressed.
    Color fillColor = Colors.grey[850];

    // Initially the interior of the button is transparent.
    _checkPhysicalLayer(buttonElement, fillColor.withAlpha(0x00));

    // Tap-press gesture on the button triggers the fill animation.
    TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // Start the button fill animation.
    await tester.pump(const Duration(milliseconds: 200)); // Animation is complete.
    _checkPhysicalLayer(buttonElement, fillColor.withAlpha(0xFF));

    // Tap gesture completes, button returns to its initial configuration.
    await gesture.up();
    await tester.pumpAndSettle();
    _checkPhysicalLayer(buttonElement, fillColor.withAlpha(0x00));

    await tester.pumpWidget(buildFrame(ThemeData.light()));
    await tester.pumpAndSettle(); // Finish the theme change animation.

    // Default value for light Theme.of(context).canvasColor as well as
    // the OutlineButton fill color when the button has been pressed.
    fillColor = Colors.grey[50];

    // Initially the interior of the button is transparent.
    // expect(button, paints..path(color: fillColor.withAlpha(0x00)));

    // Tap-press gesture on the button triggers the fill animation.
    gesture = await tester.startGesture(center);
    await tester.pump(); // Start the button fill animation.
    await tester.pump(const Duration(milliseconds: 200)); // Animation is complete.
    _checkPhysicalLayer(buttonElement, fillColor.withAlpha(0xFF));

    // Tap gesture completes, button returns to its initial configuration.
    await gesture.up();
    await tester.pumpAndSettle();
    _checkPhysicalLayer(buttonElement, fillColor.withAlpha(0x00));
  });
}

PhysicalModelLayer _findPhysicalLayer(Element element) {
  expect(element, isNotNull);
  RenderObject object = element.renderObject;
  while (object != null && object is! RenderRepaintBoundary && object is! RenderView) {
    object = object.parent;
  }
  expect(object.debugLayer, isNotNull);
  expect(object.debugLayer.firstChild, isInstanceOf<PhysicalModelLayer>());
  final PhysicalModelLayer layer = object.debugLayer.firstChild;
  return layer.firstChild is PhysicalModelLayer ? layer.firstChild : layer;
}

void _checkPhysicalLayer(Element element, Color expectedColor, { Path clipPath, Rect clipRect }) {
  final PhysicalModelLayer expectedLayer = _findPhysicalLayer(element);
  expect(expectedLayer.elevation, 0.0);
  expect(expectedLayer.color, expectedColor);
  if (clipPath != null) {
    expect(clipRect, isNotNull);
    expect(expectedLayer.clipPath, coversSameAreaAs(clipPath, areaToCompare: clipRect.inflate(10.0)));
  }
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}
