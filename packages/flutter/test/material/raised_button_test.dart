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
  testWidgets('RaisedButton defaults', (WidgetTester tester) async {
    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(RaisedButton),
      matching: find.byType(Material),
    );

    // Enabled RaisedButton
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RaisedButton(
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );
    Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0xffe0e0e0));
    expect(material.elevation, 2.0);
    expect(material.shadowColor, null);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0))));
    expect(material.textStyle!.color, const Color(0xdd000000));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    final Offset center = tester.getCenter(find.byType(RaisedButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Only elevation changes when enabled and pressed.
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0xffe0e0e0));
    expect(material.elevation, 8.0);
    expect(material.shadowColor, null);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0))));
    expect(material.textStyle!.color, const Color(0xdd000000));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Disabled RaisedButton
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RaisedButton(
          onPressed: null,
          child: Text('button'),
        ),
      ),
    );
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x61000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0))));
    expect(material.textStyle!.color, const Color(0x61000000));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);
  });

  testWidgets('RaisedButton implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    RaisedButton(
      onPressed: () { },
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

  testWidgets('Default RaisedButton meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RaisedButton(
              onPressed: () { },
              focusNode: focusNode,
              child: const Text('RaisedButton'),
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
    final Offset center = tester.getCenter(find.byType(RaisedButton));
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

  testWidgets('RaisedButton uses stateful color for text color in different states', (WidgetTester tester) async {
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
            child: RaisedButton(
              onPressed: () {},
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
              child: const Text('RaisedButton'),
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('RaisedButton')).text.style!.color!;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(RaisedButton));
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


  testWidgets('RaisedButton uses stateful color for icon color in different states', (WidgetTester tester) async {
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
            child: RaisedButton.icon(
              key: buttonKey,
              icon: const Icon(Icons.add),
              label: const Text('RaisedButton'),
              onPressed: () {},
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
            ),
          ),
        ),
      ),
    );

    Color iconColor() => _iconStyle(tester, Icons.add).color!;
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

  testWidgets('RaisedButton ignores disabled text color if text color is stateful', (WidgetTester tester) async {
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
            child: RaisedButton(
              onPressed: null,
              focusNode: focusNode,
              textColor: MaterialStateColor.resolveWith(getTextColor),
              disabledTextColor: unusedDisabledTextColor,
              child: const Text('RaisedButton'),
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('RaisedButton')).text.style!.color!;
    }

    // Disabled.
    expect(textColor(), equals(disabledColor));
    expect(textColor(), isNot(unusedDisabledTextColor));
  });

  testWidgets('RaisedButton onPressed and onLongPress callbacks are correctly called when non-null', (WidgetTester tester) async {

    bool wasPressed;
    Finder raisedButton;

    Widget buildFrame({ VoidCallback? onPressed, VoidCallback? onLongPress }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: RaisedButton(
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
    raisedButton = find.byType(RaisedButton);
    expect(tester.widget<RaisedButton>(raisedButton).enabled, true);
    await tester.tap(raisedButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onLongPress: () { wasPressed = true; }),
    );
    raisedButton = find.byType(RaisedButton);
    expect(tester.widget<RaisedButton>(raisedButton).enabled, true);
    await tester.longPress(raisedButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    await tester.pumpWidget(
      buildFrame(),
    );
    raisedButton = find.byType(RaisedButton);
    expect(tester.widget<RaisedButton>(raisedButton).enabled, false);
  });

  testWidgets('RaisedButton onPressed and onLongPress callbacks are distinctly recognized', (WidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RaisedButton(
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

    final Finder raisedButton = find.byType(RaisedButton);
    expect(tester.widget<RaisedButton>(raisedButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(raisedButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(raisedButton);
    expect(didLongPressButton, isTrue);
  });

  testWidgets('Does RaisedButton work with hover', (WidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RaisedButton(
          hoverColor: hoverColor,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(RaisedButton)));
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));

    await gesture.removePointer();
  });

  testWidgets('RaisedButton changes mouse cursor when hovered', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: RaisedButton.icon(
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
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: RaisedButton(
            onPressed: () {},
            mouseCursor: SystemMouseCursors.text,
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: RaisedButton(
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

    // Test default cursor when disabled
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: RaisedButton(
            onPressed: null,
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });


  testWidgets('Does RaisedButton work with focus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    final FocusNode focusNode = FocusNode(debugLabel: 'RaisedButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RaisedButton(
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

  testWidgets('Does RaisedButton contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RaisedButton(
            onPressed: () { },
            child: const Text('ABC'),
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

  testWidgets('RaisedButton size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = UniqueKey();
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RaisedButton(
              key: key1,
              child: const SizedBox(width: 50.0, height: 8.0),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(88.0, 48.0));

    final Key key2 = UniqueKey();
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RaisedButton(
              key: key2,
              child: const SizedBox(width: 50.0, height: 8.0),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(88.0, 36.0));
  });

  testWidgets('RaisedButton has no clip by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
          textDirection: TextDirection.ltr,
          child: RaisedButton(
            onPressed: () { /* to make sure the button is enabled */ },
          ),
      ),
    );

    expect(
        tester.renderObject(find.byType(RaisedButton)),
        paintsExactlyCountTimes(#clipPath, 0),
    );
  });

  testWidgets('RaisedButton responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    const Key childKey = Key('test child');

    Future<void> buildTest(VisualDensity visualDensity, {bool useText = false}) async {
      return tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: RaisedButton(
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

  testWidgets('RaisedButton.icon responds to applied padding', (WidgetTester tester) async {
    const Key buttonKey = Key('test');
    const Key labelKey = Key('label');
    await tester.pumpWidget(
      // When textDirection is set to TextDirection.ltr, the label appears on the
      // right side of the icon. This is important in determining whether the
      // horizontal padding is applied correctly later on
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RaisedButton.icon(
            icon: const Icon(Icons.add),
            padding: const EdgeInsets.fromLTRB(16, 5, 10, 12),
            key: buttonKey,
            onPressed: () {},
            label: const Text(
              'Hello',
              key: labelKey,
            ),
          ),
        ),
      ),
    );

    final Rect paddingRect = tester.getRect(find.byType(Padding));
    final Rect labelRect = tester.getRect(find.byKey(labelKey));
    final Rect iconRect = tester.getRect(find.byType(Icon));

    // The right padding should be applied on the right of the label, whereas the
    // left padding should be applied on the left side of the icon.
    expect(paddingRect.right, labelRect.right + 10);
    expect(paddingRect.left, iconRect.left - 16);
    // Use the taller widget to check the top and bottom padding.
    final Rect tallerWidget = iconRect.height > labelRect.height ? iconRect : labelRect;
    expect(paddingRect.top, tallerWidget.top - 5);
    expect(paddingRect.bottom, tallerWidget.bottom + 12);
  });
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style!;
}
