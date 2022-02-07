// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('OutlineButton defaults', (WidgetTester tester) async {
    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(OutlineButton),
      matching: find.byType(Material),
    );

    // Enabled OutlineButton
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );
    Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 75));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x00000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.textStyle!.color, const Color(0xdd000000));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    final Offset center = tester.getCenter(find.byType(OutlineButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // No change vs enabled and not pressed.
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 75));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x00000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.textStyle!.color, const Color(0xdd000000));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Disabled OutlineButton
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          onPressed: null,
          child: Text('button'),
        ),
      ),
    );
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 75));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x00000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.textStyle!.color, const Color(0x61000000));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Does OutlineButton work with hover', (WidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          hoverColor: hoverColor,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(OutlineButton)));
    await tester.pumpAndSettle();
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));

    await gesture.removePointer();
  });

  testWidgets('OutlineButton changes mouse cursor when hovered', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: OutlineButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Hello'),
            onPressed: () {},
            mouseCursor: SystemMouseCursors.text,
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: const Offset(1, 1));
    addTearDown(gesture.removePointer);

    await tester.pump();
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: OutlineButton(
            onPressed: () {},
            mouseCursor: SystemMouseCursors.text,
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: OutlineButton(
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

    // Test default cursor when disabled
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: OutlineButton(
            onPressed: null,
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });

  testWidgets('Does OutlineButton work with focus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    final FocusNode focusNode = FocusNode(debugLabel: 'OutlineButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          focusColor: focusColor,
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

  testWidgets('Does OutlineButton work with autofocus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    final FocusNode focusNode = FocusNode(debugLabel: 'OutlineButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          autofocus: true,
          focusColor: focusColor,
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
              onPressed: () {},
              focusNode: focusNode,
              child: const Text('OutlineButton'),
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
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
  );

  testWidgets('OutlineButton with colored theme meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    final ColorScheme colorScheme = ColorScheme.fromSwatch();

    Color getTextColor(Set<MaterialState> states) {
      final Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue[900]!;
      }
      return Colors.blue[800]!;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ButtonTheme(
              colorScheme: colorScheme,
              textTheme: ButtonTextTheme.primary,
              child: OutlineButton(
                onPressed: () {},
                focusNode: focusNode,
                textColor: MaterialStateColor.resolveWith(getTextColor),
                child: const Text('OutlineButton'),
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
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
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
              onPressed: () {},
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
              child: const Text('OutlineButton'),
            ),
          ),
        ),
      ),
    );

    Color? textColor() {
      return tester.renderObject<RenderParagraph>(find.text('OutlineButton')).text.style!.color;
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

    Color? iconColor() => _iconStyle(tester, Icons.add).color;
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
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
              disabledTextColor: unusedDisabledTextColor,
              child: const Text('OutlineButton'),
            ),
          ),
        ),
      ),
    );

    Color? textColor() {
      return tester.renderObject<RenderParagraph>(find.text('OutlineButton')).text.style!.color;
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
              onPressed: () {},
              focusNode: focusNode,
              borderSide: BorderSide(color: MaterialStateColor.resolveWith(getBorderColor)),
              child: const Text('OutlineButton'),
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
              onPressed: () {},
              borderSide: BorderSide(color: MaterialStateColor.resolveWith(getBorderColor)),
              highlightedBorderColor: ignoredPressedColor,
              child: const Text('OutlineButton'),
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
              onPressed: null,
              borderSide: BorderSide(color: MaterialStateColor.resolveWith(getBorderColor)),
              highlightedBorderColor: ignoredDisabledColor,
              child: const Text('OutlineButton'),
            ),
          ),
        ),
      ),
    );

    // Disabled.
    expect(find.byType(OutlineButton), paints..path(color: disabledColor));
  });

  testWidgets('OutlineButton onPressed and onLongPress callbacks are correctly called when non-null', (WidgetTester tester) async {

    bool wasPressed;
    Finder outlineButton;

    Widget buildFrame({ VoidCallback? onPressed, VoidCallback? onLongPress }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: const Text('button'),
        ),
      );
    }

    // onPressed not null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: () { wasPressed = true; }),
    );
    outlineButton = find.byType(OutlineButton);
    expect(tester.widget<OutlineButton>(outlineButton).enabled, true);
    await tester.tap(outlineButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onLongPress: () { wasPressed = true; }),
    );
    outlineButton = find.byType(OutlineButton);
    expect(tester.widget<OutlineButton>(outlineButton).enabled, true);
    await tester.longPress(outlineButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    await tester.pumpWidget(
      buildFrame(),
    );
    outlineButton = find.byType(OutlineButton);
    expect(tester.widget<OutlineButton>(outlineButton).enabled, false);
  });

  testWidgets("Outline button doesn't crash if disabled during a gesture", (WidgetTester tester) async {
    Widget buildFrame(VoidCallback? onPressed) {
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

    Widget buildFrame({ VoidCallback? onPressed }) {
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
      buildFrame(),
    );

    // Expect that the button is disabled and painted with the disabled border color.
    expect(tester.widget<OutlineButton>(outlineButton).enabled, false);
    expect(
      outlineButton,
      paints..path(color: disabledBorderColor, strokeWidth: borderWidth),
    );
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
      paints..path(color: borderColor, strokeWidth: borderWidth),
    );
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
      paints..path(color: highlightedBorderColor, strokeWidth: borderWidth),
    );
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
      paints..path(color: borderColor, strokeWidth: borderWidth),
    );
    _checkPhysicalLayer(
      tester.element(outlineButton),
      fillColor.withAlpha(0x00),
      clipPath: clipPath,
      clipRect: clipRect,
    );
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
            data: const MediaQueryData(),
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
  });

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
    Color fillColor = Colors.grey[850]!;

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
    fillColor = Colors.grey[50]!;

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

  testWidgets('OutlineButton respects the provided materialTapTargetSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onPressed: () {},
              child: const SizedBox(width: 50.0, height: 8.0),
            ),
          ),
        ),
      ),
    );

    // Default Width of OutlineButton with MaterialTapTargetSize (88)
    expect(tester.getSize(find.byType(OutlineButton)), const Size(88.0, 48.0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {},
              child: const SizedBox(width: 50.0, height: 8.0),
            ),
          ),
        ),
      ),
    );

    // Default Width of OutlineButton with MaterialTapTargetSize (88)
    expect(tester.getSize(find.byType(OutlineButton)), const Size(88.0, 36.0));

    final LocalKey key1 = UniqueKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton.icon(
              key: key1,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              icon: const Icon(Icons.add_alarm),
              label: const SizedBox(width: 50.0, height: 8.0),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    final Size addAlarmIconSize = tester.getSize(find.byIcon(Icons.add_alarm));

    // The expected width is the sum of:
    // the width of the icon
    // the gap between the icon and the label (8)
    // the width of the label (50)
    // the horizontal padding: start (12), end (16)
    expect(tester.getSize(find.byKey(key1)), Size(86 + addAlarmIconSize.width, 48.0));

    final LocalKey key2 = UniqueKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: OutlineButton.icon(
              key: key2,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              icon: const Icon(Icons.add),
              label: const SizedBox(width: 50.0, height: 8.0),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    // The expected width is the sum of:
    // the width of the icon
    // the gap between the icon and the label (8)
    // the width of the label (50)
    // the horizontal padding: start (12), end (16)
    final Size addIconSize = tester.getSize(find.byIcon(Icons.add));
    expect(tester.getSize(find.byKey(key2)), Size(86 + addIconSize.width, 36.0));
  });

  testWidgets('OutlineButton onPressed and onLongPress callbacks are distinctly recognized', (WidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
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

    final Finder outlineButton = find.byType(OutlineButton);
    expect(tester.widget<OutlineButton>(outlineButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(outlineButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(outlineButton);
    expect(didLongPressButton, isTrue);
  });

  testWidgets('OutlineButton responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    const Key childKey = Key('test child');

    Future<void> buildTest(VisualDensity visualDensity, {bool useText = false}) async {
      return tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: OutlineButton(
                visualDensity: visualDensity,
                key: key,
                onPressed: () {},
                child: useText ? const Text('Text', key: childKey) : Container(key: childKey, width: 100, height: 100, color: const Color(0xffff0000)),
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
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

    await buildTest(VisualDensity.standard, useText: true);
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
  RenderObject? object = element.renderObject;
  while (object != null && object is! RenderRepaintBoundary && object is! RenderView) {
    object = object.parent as RenderObject?;
  }
  assert(object != null);
  expect(object!.debugLayer, isNotNull);
  expect(object.debugLayer!.firstChild, isA<PhysicalModelLayer>());
  final PhysicalModelLayer layer = object.debugLayer!.firstChild! as PhysicalModelLayer;
  final Layer child = layer.firstChild!;
  return child is PhysicalModelLayer ? child : layer;
}

void _checkPhysicalLayer(Element element, Color expectedColor, { Path? clipPath, Rect? clipRect }) {
  final PhysicalModelLayer expectedLayer = _findPhysicalLayer(element);
  expect(expectedLayer.elevation, 0.0);
  expect(expectedLayer.color, expectedColor);
  if (clipPath != null) {
    expect(clipRect, isNotNull);
    expect(expectedLayer.clipPath, coversSameAreaAs(clipPath, areaToCompare: clipRect!.inflate(10.0)));
  }
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style!;
}
