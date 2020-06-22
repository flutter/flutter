// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('OutlinedButton defaults', (WidgetTester tester) async {
    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(OutlinedButton),
      matching: find.byType(Material),
    );

    const ColorScheme colorScheme = ColorScheme.light();

    // Enabled OutlinedButton
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: Center(
          child: OutlinedButton(
            onPressed: () { },
            child: const Text('button'),
          ),
        ),
      ),
    );

    Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(
      side: BorderSide(
        width: 1,
        color: colorScheme.onSurface.withOpacity(0.12),
      ),
      borderRadius: BorderRadius.circular(4.0),
    ));
    expect(material.textStyle.color, colorScheme.primary);
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    final Offset center = tester.getCenter(find.byType(OutlinedButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // No change vs enabled and not pressed.
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(
      side: BorderSide(
        width: 1,
        color: colorScheme.onSurface.withOpacity(0.12),
      ),
      borderRadius: BorderRadius.circular(4.0),
    ));
    expect(material.textStyle.color, colorScheme.primary);
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Disabled OutlinedButton
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: Center(
          child: OutlinedButton(
            onPressed: null,
            child: const Text('button'),
          ),
        ),
      ),
    );

    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(
      side: BorderSide(
        width: 1,
        color: colorScheme.onSurface.withOpacity(0.12),
      ),
      borderRadius: BorderRadius.circular(4.0),
    ));
    expect(material.textStyle.color, colorScheme.onSurface.withOpacity(0.38));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Does OutlinedButton work with hover', (WidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    Color getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.hovered) ? hoverColor : null;
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlinedButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color>(getOverlayColor),
          ),
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(OutlinedButton)));
    await tester.pumpAndSettle();
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));

    gesture.removePointer();
  });

  testWidgets('Does OutlinedButton work with focus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    Color getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.focused) ? focusColor : null;
    }

    final FocusNode focusNode = FocusNode(debugLabel: 'OutlinedButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlinedButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color>(getOverlayColor),
          ),
          focusNode: focusNode,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets('Does OutlinedButton work with autofocus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    Color getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.focused) ? focusColor : null;
    }

    final FocusNode focusNode = FocusNode(debugLabel: 'OutlinedButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlinedButton(
          autofocus: true,
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color>(getOverlayColor),
          ),
          focusNode: focusNode,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets('Default OutlinedButton meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()),
        home: Scaffold(
          body: Center(
            child: OutlinedButton(
              child: const Text('OutlinedButton'),
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
    final Offset center = tester.getCenter(find.byType(OutlinedButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await gesture.removePointer();
  },
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
    semanticsEnabled: true,
  );

  testWidgets('OutlinedButton with colored theme meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

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
        theme: ThemeData.from(colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: OutlinedButtonTheme(
              data: OutlinedButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(getTextColor),
                ),
              ),
              child: Builder(
                builder: (BuildContext context) {
                  return OutlinedButton(
                    child: const Text('OutlinedButton'),
                    onPressed: () {},
                    focusNode: focusNode,
                  );
                },
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
    final Offset center = tester.getCenter(find.byType(OutlinedButton));
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
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
    semanticsEnabled: true,
  );

  testWidgets('OutlinedButton uses stateful color for text color in different states', (WidgetTester tester) async {
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
            child: OutlinedButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>(getTextColor),
              ),
              onPressed: () {},
              focusNode: focusNode,
              child: const Text('OutlinedButton'),
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('OutlinedButton')).text.style.color;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(OutlinedButton));
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

  testWidgets('OutlinedButton uses stateful color for icon color in different states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final Key buttonKey = UniqueKey();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getIconColor(Set<MaterialState> states) {
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
            child: OutlinedButton.icon(
              key: buttonKey,
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>(getIconColor),
              ),
              icon: const Icon(Icons.add),
              label: const Text('OutlinedButton'),
              onPressed: () {},
              focusNode: focusNode,
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

  testWidgets('OutlinedButton uses stateful color for border color in different states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    BorderSide getBorderSide(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return BorderSide(color: pressedColor, width: 1);
      }
      if (states.contains(MaterialState.hovered)) {
        return BorderSide(color: hoverColor, width: 1);
      }
      if (states.contains(MaterialState.focused)) {
        return BorderSide(color: focusedColor, width: 1);
      }
      return BorderSide(color: defaultColor, width: 1);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlinedButton(
              style: ButtonStyle(
                side: MaterialStateProperty.resolveWith<BorderSide>(getBorderSide),
              ),
              onPressed: () {},
              focusNode: focusNode,
              child: const Text('OutlinedButton'),
            ),
          ),
        ),
      ),
    );

    final Finder outlinedButton = find.byType(OutlinedButton);

    // Default, not disabled.
    expect(outlinedButton, paints..drrect(color: defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(outlinedButton, paints..drrect(color: focusedColor));

    // Hovered.
    final Offset center = tester.getCenter(find.byType(OutlinedButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(outlinedButton, paints..drrect(color: hoverColor));

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pumpAndSettle();
    expect(outlinedButton, paints..drrect(color: pressedColor));
  });

  testWidgets('OutlinedButton onPressed and onLongPress callbacks are correctly called when non-null', (WidgetTester tester) async {

    bool wasPressed;
    Finder outlinedButton;

    Widget buildFrame({ VoidCallback onPressed, VoidCallback onLongPress }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: OutlinedButton(
          child: const Text('button'),
          onPressed: onPressed,
          onLongPress: onLongPress,
        ),
      );
    }

    // onPressed not null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: () { wasPressed = true; }, onLongPress: null),
    );
    outlinedButton = find.byType(OutlinedButton);
    expect(tester.widget<OutlinedButton>(outlinedButton).enabled, true);
    await tester.tap(outlinedButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: () { wasPressed = true; }),
    );
    outlinedButton = find.byType(OutlinedButton);
    expect(tester.widget<OutlinedButton>(outlinedButton).enabled, true);
    await tester.longPress(outlinedButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: null),
    );
    outlinedButton = find.byType(OutlinedButton);
    expect(tester.widget<OutlinedButton>(outlinedButton).enabled, false);
  });

  testWidgets("Outline button doesn't crash if disabled during a gesture", (WidgetTester tester) async {
    Widget buildFrame(VoidCallback onPressed) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(),
          child: Center(
            child: OutlinedButton(onPressed: onPressed, child: Text('button')),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(() {}));
    await tester.press(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
  });

  testWidgets('OutlinedButton shape and border component overrides', (WidgetTester tester) async {
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
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: fillColor,
                shape: const RoundedRectangleBorder(), // default border radius is 0
              ).copyWith(
                side: MaterialStateProperty.resolveWith<BorderSide>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled))
                    return BorderSide(color: disabledBorderColor, width: borderWidth);
                  if (states.contains(MaterialState.pressed))
                    return BorderSide(color: highlightedBorderColor, width: borderWidth);
                  return BorderSide(color: borderColor, width: borderWidth);
                }),
              ),
              clipBehavior: Clip.antiAlias,
              onPressed: onPressed,
              child: const Text('button'),
            ),
          ),
        ),
      );
    }

    const Rect clipRect = Rect.fromLTRB(0.0, 0.0, 116.0, 36.0);
    final Path clipPath = Path()..addRect(clipRect);
    final Finder outlinedButton = find.byType(OutlinedButton);

    // Pump a button with a null onPressed callback to make it disabled.
    await tester.pumpWidget(
      buildFrame(onPressed: null),
    );

    // Expect that the button is disabled and painted with the disabled border color.
    expect(tester.widget<OutlinedButton>(outlinedButton).enabled, false);
    expect(outlinedButton, paints..drrect(color: disabledBorderColor));
    _checkPhysicalLayer(
      tester.element(outlinedButton),
      fillColor,
      clipPath: clipPath,
      clipRect: clipRect,
    );

    // Pump a new button with a no-op onPressed callback to make it enabled.
    await tester.pumpWidget(
      buildFrame(onPressed: () {}),
    );

    // Wait for the border color to change from disabled to enabled.
    await tester.pumpAndSettle();

    final Offset center = tester.getCenter(outlinedButton);
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    // Wait for the border's color to change to highlightedBorderColor and
    // the fillColor to become opaque.
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      outlinedButton,
      paints
        ..drrect(color: highlightedBorderColor/*,strokeWidth: borderWidth*/));
    _checkPhysicalLayer(
      tester.element(outlinedButton),
      fillColor,
      clipPath: clipPath,
      clipRect: clipRect,
    );

    // Tap gesture completes, button returns to its initial configuration.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      outlinedButton,
      paints
        ..drrect(color: borderColor/*, strokeWidth: borderWidth*/));
    _checkPhysicalLayer(
      tester.element(outlinedButton),
      fillColor,
      clipPath: clipPath,
      clipRect: clipRect,
    );
  });

  testWidgets('OutlinedButton has no clip by default', (WidgetTester tester) async {
    final GlobalKey buttonKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlinedButton(
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


  testWidgets('OutlinedButton contributes semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlinedButton(
              style: ButtonStyle(
                // Specifying minimumSize to mimic the original minimumSize for
                // RaisedButton so that the corresponding button size matches
                // the original version of this test.
                minimumSize: MaterialStateProperty.all<Size>(const Size(88, 36)),
              ),
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

  testWidgets('OutlinedButton scales textScaleFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.0),
            child: Center(
              child: OutlinedButton(
                style: ButtonStyle(
                  // Specifying minimumSize to mimic the original minimumSize for
                  // RaisedButton so that the corresponding button size matches
                  // the original version of this test.
                  minimumSize: MaterialStateProperty.all<Size>(const Size(88, 36)),
                ),
                onPressed: () {},
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(OutlinedButton)), equals(const Size(88.0, 48.0)));
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
  });


  testWidgets('OutlinedButton onPressed and onLongPress callbacks are distinctly recognized', (WidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlinedButton(
          onPressed: () {
            didPressButton = true;
          },
          onLongPress: () {
            didLongPressButton = true;
          },
          child: const Text('button'),
        ),
      ),
    );

    final Finder outlinedButton = find.byType(OutlinedButton);
    expect(tester.widget<OutlinedButton>(outlinedButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(outlinedButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(outlinedButton);
    expect(didLongPressButton, isTrue);
  });

  testWidgets('OutlinedButton responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    const Key childKey = Key('test child');

    Future<void> buildTest(VisualDensity visualDensity, {bool useText = false}) async {
      return await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: OutlinedButton(
                style: ButtonStyle(
                  visualDensity: visualDensity,
                  // Specifying minimumSize to mimic the original minimumSize for
                  // RaisedButton so that the corresponding button size matches
                  // the original version of this test.
                  minimumSize: MaterialStateProperty.all<Size>(const Size(88, 36)),
                ),
                key: key,
                onPressed: () {},
                child: useText
                  ? const Text('Text', key: childKey)
                  : Container(key: childKey, width: 100, height: 100, color: const Color(0xffff0000)),
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(const VisualDensity());
    final RenderBox box = tester.renderObject(find.byKey(key));
    Rect childRect = tester.getRect(find.byKey(childKey));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(132, 100)));
    expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(156, 124)));
    expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(108, 100)));
    expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

    await buildTest(const VisualDensity(), useText: true);
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(88, 48)));
    expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0), useText: true);
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(112, 60)));
    expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0), useText: true);
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(76, 36)));
    expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));
  });
}

PhysicalModelLayer _findPhysicalLayer(Element element) {
  expect(element, isNotNull);
  RenderObject object = element.renderObject;
  while (object != null && object is! RenderRepaintBoundary && object is! RenderView) {
    object = object.parent as RenderObject;
  }
  expect(object.debugLayer, isNotNull);
  expect(object.debugLayer.firstChild, isA<PhysicalModelLayer>());
  final PhysicalModelLayer layer = object.debugLayer.firstChild as PhysicalModelLayer;
  final Layer child = layer.firstChild;
  return child is PhysicalModelLayer ? child : layer;
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
