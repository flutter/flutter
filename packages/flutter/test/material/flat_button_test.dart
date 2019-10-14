// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('FlatButton implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    FlatButton(
        onPressed: () { },
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

  testWidgets('Default FlatButton meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlatButton(
              child: const Text('FlatButton'),
              onPressed: () { },
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
    final Offset center = tester.getCenter(find.byType(FlatButton));
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

  testWidgets('FlatButton with colored theme meets a11y contrast guidelines', (WidgetTester tester) async {
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
              child: FlatButton(
                child: const Text('FlatButton'),
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
    final Offset center = tester.getCenter(find.byType(FlatButton));
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

  testWidgets('FlatButton uses stateful color for text color in different states', (WidgetTester tester) async {
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
            child: FlatButton(
              child: const Text('FlatButton'),
              onPressed: () {},
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('FlatButton')).text.style.color;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(FlatButton));
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

  testWidgets('FlatButton uses stateful color for icon color in different states', (WidgetTester tester) async {
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
            child: FlatButton.icon(
              key: buttonKey,
              icon: const Icon(Icons.add),
              label: const Text('FlatButton'),
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

  testWidgets('FlatButton ignores disabled text color if text color is stateful', (WidgetTester tester) async {
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
            child: FlatButton(
              onPressed: null,
              child: const Text('FlatButton'),
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
              disabledTextColor: unusedDisabledTextColor,
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('FlatButton')).text.style.color;
    }

    // Disabled.
    expect(textColor(), equals(disabledColor));
    expect(textColor(), isNot(unusedDisabledTextColor));
  });

  testWidgets('FlatButton has no clip by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: FlatButton(
            child: Container(),
            onPressed: () { /* to make sure the button is enabled */ },
          ),
        ),
      ),
    );

    expect(
        tester.renderObject(find.byType(FlatButton)),
        paintsExactlyCountTimes(#clipPath, 0),
    );
  });
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}
