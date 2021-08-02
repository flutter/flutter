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
  testWidgets('TextButton, TextButton.icon defaults', (WidgetTester tester) async {
    const ColorScheme colorScheme = ColorScheme.light();

    // Enabled TextButton
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: Center(
          child: TextButton(
            onPressed: () { },
            child: const Text('button'),
          ),
        ),
      ),
    );

    final Finder buttonMaterial = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    );

    Material material = tester.widget<Material>(buttonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.primary);
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    final Align align = tester.firstWidget<Align>(find.ancestor(of: find.text('button'), matching: find.byType(Align)));
    expect(align.alignment, Alignment.center);

    final Offset center = tester.getCenter(find.byType(TextButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start the splash animation
    await tester.pump(const Duration(milliseconds: 100)); // splash is underway
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..circle(color: colorScheme.primary.withAlpha(0x1f))); // splash color is primary(0.12)

    await gesture.up();
    await tester.pumpAndSettle();
    material = tester.widget<Material>(buttonMaterial);
    // No change vs enabled and not pressed.
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.primary);
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Enabled TextButton.icon
    final Key iconButtonKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: Center(
          child: TextButton.icon(
            key: iconButtonKey,
            onPressed: () { },
            icon: const Icon(Icons.add),
            label: const Text('label'),
          ),
        ),
      ),
    );

    final Finder iconButtonMaterial = find.descendant(
      of: find.byKey(iconButtonKey),
      matching: find.byType(Material),
    );

    material = tester.widget<Material>(iconButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.primary);
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Disabled TextButton
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: const Center(
          child: TextButton(
            onPressed: null,
            child: Text('button'),
          ),
        ),
      ),
    );

    material = tester.widget<Material>(buttonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.onSurface.withOpacity(0.38));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Default TextButton meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()),
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () { },
              focusNode: focusNode,
              child: const Text('TextButton'),
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
    final Offset center = tester.getCenter(find.byType(TextButton));
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

  testWidgets('TextButton with colored theme meets a11y contrast guidelines', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

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
            child: TextButtonTheme(
              data: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(getTextColor),
                ),
              ),
              child: Builder(
                builder: (BuildContext context) {
                  return TextButton(
                    onPressed: () {},
                    focusNode: focusNode,
                    child: const Text('TextButton'),
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
    final Offset center = tester.getCenter(find.byType(TextButton));
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

  testWidgets('TextButton uses stateful color for text color in different states', (WidgetTester tester) async {
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
            child: TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>(getTextColor),
              ),
              onPressed: () {},
              focusNode: focusNode,
              child: const Text('TextButton'),
            ),
          ),
        ),
      ),
    );

    Color? textColor() {
      return tester.renderObject<RenderParagraph>(find.text('TextButton')).text.style?.color;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(TextButton));
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

  testWidgets('TextButton uses stateful color for icon color in different states', (WidgetTester tester) async {
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
            child: TextButton.icon(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>(getTextColor),
              ),
              key: buttonKey,
              icon: const Icon(Icons.add),
              label: const Text('TextButton'),
              onPressed: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    Color? iconColor() => _iconStyle(tester, Icons.add)?.color;
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

  testWidgets('TextButton has no clip by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: TextButton(
            child: Container(),
            onPressed: () { /* to make sure the button is enabled */ },
          ),
        ),
      ),
    );

    expect(
        tester.renderObject(find.byType(TextButton)),
        paintsExactlyCountTimes(#clipPath, 0),
    );
  });

  testWidgets('Does TextButton work with hover', (WidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    Color? getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.hovered) ? hoverColor : null;
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.resolveWith<Color?>(getOverlayColor),
            ),
            child: Container(),
            onPressed: () { /* to make sure the button is enabled */ },
          ),
        ),
      ),
    );


    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(TextButton)));
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));
  });

  testWidgets('Does TextButton work with focus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    Color? getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.focused) ? focusColor : null;
    }

    final FocusNode focusNode = FocusNode(debugLabel: 'TextButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TextButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color?>(getOverlayColor),
          ),
          focusNode: focusNode,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    WidgetsBinding.instance!.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets('Does TextButton contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: TextButton(
              style: ButtonStyle(
                // Specifying minimumSize to mimic the original minimumSize for
                // RaisedButton so that the semantics tree's rect and transform
                // match the original version of this test.
                minimumSize: MaterialStateProperty.all<Size>(const Size(88, 36)),
              ),
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

  testWidgets('Does TextButton scale with font scale changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.0),
            child: Center(
              child: TextButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(TextButton)), equals(const Size(64.0, 48.0)));
    expect(tester.getSize(find.byType(Text)), equals(const Size(42.0, 14.0)));

    // textScaleFactor expands text, but not button.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.3),
            child: Center(
              child: TextButton(
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
    expect(tester.getSize(find.byType(TextButton)).width, isIn(<double>[70.0, 71.0]));
    expect(tester.getSize(find.byType(TextButton)).height, isIn(<double>[47.0, 48.0]));
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
              child: TextButton(
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
    expect(tester.getSize(find.byType(TextButton)).width, isIn(<double>[133.0, 134.0]));
    expect(tester.getSize(find.byType(TextButton)).height, equals(48.0));
    expect(tester.getSize(find.byType(Text)).width, isIn(<double>[126.0, 127.0]));
    expect(tester.getSize(find.byType(Text)).height, equals(42.0));
  });


  testWidgets('TextButton size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    Widget buildFrame(MaterialTapTargetSize tapTargetSize, Key key) {
      return Theme(
        data: ThemeData(materialTapTargetSize: tapTargetSize),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: TextButton(
                key: key,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () { },
              ),
            ),
          ),
        ),
      );
    }

    final Key key1 = UniqueKey();
    await tester.pumpWidget(buildFrame(MaterialTapTargetSize.padded, key1));
    expect(tester.getSize(find.byKey(key1)), const Size(66.0, 48.0));

    final Key key2 = UniqueKey();
    await tester.pumpWidget(buildFrame(MaterialTapTargetSize.shrinkWrap, key2));
    expect(tester.getSize(find.byKey(key2)), const Size(66.0, 36.0));
  });

  testWidgets('TextButton onPressed and onLongPress callbacks are correctly called when non-null', (WidgetTester tester) async {
    bool wasPressed;
    Finder textButton;

    Widget buildFrame({ VoidCallback? onPressed, VoidCallback? onLongPress }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TextButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: const Text('button'),
        ),
      );
    }

    // onPressed not null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: () { wasPressed = true; }, onLongPress: null),
    );
    textButton = find.byType(TextButton);
    expect(tester.widget<TextButton>(textButton).enabled, true);
    await tester.tap(textButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: () { wasPressed = true; }),
    );
    textButton = find.byType(TextButton);
    expect(tester.widget<TextButton>(textButton).enabled, true);
    await tester.longPress(textButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: null),
    );
    textButton = find.byType(TextButton);
    expect(tester.widget<TextButton>(textButton).enabled, false);
  });

  testWidgets('TextButton onPressed and onLongPress callbacks are distinctly recognized', (WidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TextButton(
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

    final Finder textButton = find.byType(TextButton);
    expect(tester.widget<TextButton>(textButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(textButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(textButton);
    expect(didLongPressButton, isTrue);
  });

  testWidgets('TextButton responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    const Key childKey = Key('test child');

    Future<void> buildTest(VisualDensity visualDensity, { bool useText = false }) async {
      return tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: TextButton(
                style: ButtonStyle(
                  visualDensity: visualDensity,
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

    await buildTest(VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byKey(key));
    Rect childRect = tester.getRect(find.byKey(childKey));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(116, 116)));
    expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(140, 140)));
    expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(116, 100)));
    expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

    await buildTest(VisualDensity.standard, useText: true);
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(72, 48)));
    expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0), useText: true);
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(96, 60)));
    expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0), useText: true);
    await tester.pumpAndSettle();
    childRect = tester.getRect(find.byKey(childKey));
    expect(box.size, equals(const Size(72, 36)));
    expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));
  });

  group('Default TextButton padding for textScaleFactor, textDirection', () {
    const ValueKey<String> buttonKey = ValueKey<String>('button');
    const ValueKey<String> labelKey = ValueKey<String>('label');
    const ValueKey<String> iconKey = ValueKey<String>('icon');

    const List<double> textScaleFactorOptions = <double>[0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0];
    const List<TextDirection> textDirectionOptions = <TextDirection>[TextDirection.ltr, TextDirection.rtl];
    const List<Widget?> iconOptions = <Widget?>[null, Icon(Icons.add, size: 18, key: iconKey)];

    // Expected values for each textScaleFactor.
    final Map<double, double> paddingVertical = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 6,
      1.5: 4,
      2: 0,
      2.5: 0,
      3: 0,
      4: 0,
    };
    final Map<double, double> paddingWithIconGap = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 7,
      1.5: 6,
      2: 4,
      2.5: 4,
      3: 4,
      4: 4,
    };
    final Map<double, double> textPaddingWithoutIconHorizontal = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 8,
      1.5: 8,
      2: 8,
      2.5: 6,
      3: 4,
      4: 4,
    };
    final Map<double, double> textPaddingWithIconHorizontal = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 7,
      1.5: 6,
      2: 4,
      2.5: 4,
      3: 4,
      4: 4,
    };

    Rect globalBounds(RenderBox renderBox) {
      final Offset topLeft = renderBox.localToGlobal(Offset.zero);
      return topLeft & renderBox.size;
    }

    /// Computes the padding between two [Rect]s, one inside the other.
    EdgeInsets paddingBetween({ required Rect parent, required Rect child }) {
      assert (parent.intersect(child) == child);
      return EdgeInsets.fromLTRB(
        child.left - parent.left,
        child.top - parent.top,
        parent.right - child.right,
        parent.bottom - child.bottom,
      );
    }

    for (final double textScaleFactor in textScaleFactorOptions) {
      for (final TextDirection textDirection in textDirectionOptions) {
        for (final Widget? icon in iconOptions) {
          final String testName = <String>[
            'TextButton, text scale $textScaleFactor',
            if (icon != null)
              'with icon',
            if (textDirection == TextDirection.rtl)
              'RTL',
          ].join(', ');

          testWidgets(testName, (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData.from(colorScheme: const ColorScheme.light()),
                home: Builder(
                  builder: (BuildContext context) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaleFactor: textScaleFactor,
                      ),
                      child: Directionality(
                        textDirection: textDirection,
                        child: Scaffold(
                          body: Center(
                            child: icon == null
                              ? TextButton(
                                  key: buttonKey,
                                  onPressed: () {},
                                  child: const Text('button', key: labelKey),
                                )
                              : TextButton.icon(
                                  key: buttonKey,
                                  onPressed: () {},
                                  icon: icon,
                                  label: const Text('button', key: labelKey),
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );

            final Element paddingElement = tester.element(
              find.descendant(
                of: find.byKey(buttonKey),
                matching: find.byType(Padding),
              ),
            );
            expect(Directionality.of(paddingElement), textDirection);
            final Padding paddingWidget = paddingElement.widget as Padding;

            // Compute expected padding, and check.

            final double expectedPaddingTop = paddingVertical[textScaleFactor]!;
            final double expectedPaddingBottom = paddingVertical[textScaleFactor]!;

            final double expectedPaddingStart = icon != null
              ? textPaddingWithIconHorizontal[textScaleFactor]!
              : textPaddingWithoutIconHorizontal[textScaleFactor]!;
            final double expectedPaddingEnd = expectedPaddingStart;

            final EdgeInsets expectedPadding = EdgeInsetsDirectional.fromSTEB(
              expectedPaddingStart,
              expectedPaddingTop,
              expectedPaddingEnd,
              expectedPaddingBottom,
            ).resolve(textDirection);

            expect(paddingWidget.padding.resolve(textDirection), expectedPadding);

            // Measure padding in terms of the difference between the button and its label child
            // and check that.

            final RenderBox labelRenderBox = tester.renderObject<RenderBox>(find.byKey(labelKey));
            final Rect labelBounds = globalBounds(labelRenderBox);
            final RenderBox? iconRenderBox = icon == null ? null : tester.renderObject<RenderBox>(find.byKey(iconKey));
            final Rect? iconBounds = icon == null ? null : globalBounds(iconRenderBox!);
            final Rect childBounds = icon == null ? labelBounds : labelBounds.expandToInclude(iconBounds!);

            // We measure the `InkResponse` descendant of the button
            // element, because the button has a larger `RenderBox`
            // which accommodates the minimum tap target with a height
            // of 48.
            final RenderBox buttonRenderBox = tester.renderObject<RenderBox>(
              find.descendant(
                of: find.byKey(buttonKey),
                matching: find.byWidgetPredicate(
                  (Widget widget) => widget is InkResponse,
                ),
              ),
            );
            final Rect buttonBounds = globalBounds(buttonRenderBox);
            final EdgeInsets visuallyMeasuredPadding = paddingBetween(
              parent: buttonBounds,
              child: childBounds,
            );

            // Since there is a requirement of a minimum width of 64
            // and a minimum height of 36 on material buttons, the visual
            // padding of smaller buttons may not match their settings.
            // Therefore, we only test buttons that are large enough.
            if (buttonBounds.width > 64) {
              expect(
                visuallyMeasuredPadding.left,
                expectedPadding.left,
              );
              expect(
                visuallyMeasuredPadding.right,
                expectedPadding.right,
              );
            }

            if (buttonBounds.height > 36) {
              expect(
                visuallyMeasuredPadding.top,
                expectedPadding.top,
              );
              expect(
                visuallyMeasuredPadding.bottom,
                expectedPadding.bottom,
              );
            }

            // Check the gap between the icon and the label
            if (icon != null) {
              final double gapWidth = textDirection == TextDirection.ltr
                ? labelBounds.left - iconBounds!.right
                : iconBounds!.left - labelBounds.right;
              expect(gapWidth, paddingWithIconGap[textScaleFactor]);
            }

            // Check the text's height - should be consistent with the textScaleFactor.
            final RenderBox textRenderObject = tester.renderObject<RenderBox>(
              find.descendant(
                of: find.byKey(labelKey),
                matching: find.byElementPredicate(
                  (Element element) => element.widget is RichText,
                ),
              ),
            );
            final double textHeight = textRenderObject.paintBounds.size.height;
            final double expectedTextHeight = 14 * textScaleFactor;
            expect(textHeight, moreOrLessEquals(expectedTextHeight, epsilon: 0.5));
          });
        }
      }
    }
  });

  testWidgets('Override TextButton default padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()),
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 2,
              ),
              child: Scaffold(
                body: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.all(22)),
                    onPressed: () {},
                    child: const Text('TextButton'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final Padding paddingWidget = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TextButton),
        matching: find.byType(Padding),
      ),
    );
    expect(paddingWidget.padding, const EdgeInsets.all(22));
  });

  testWidgets('Fixed size TextButtons', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(fixedSize: const Size(100, 100)),
                onPressed: () {},
                child: const Text('100x100'),
              ),
              TextButton(
                style: TextButton.styleFrom(fixedSize: const Size.fromWidth(200)),
                onPressed: () {},
                child: const Text('200xh'),
              ),
              TextButton(
                style: TextButton.styleFrom(fixedSize: const Size.fromHeight(200)),
                onPressed: () {},
                child: const Text('wx200'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.widgetWithText(TextButton, '100x100')), const Size(100, 100));
    expect(tester.getSize(find.widgetWithText(TextButton, '200xh')).width, 200);
    expect(tester.getSize(find.widgetWithText(TextButton, 'wx200')).height, 200);
  });

  testWidgets('TextButton with NoSplash splashFactory paints nothing', (WidgetTester tester) async {
    Widget buildFrame({ InteractiveInkFeatureFactory? splashFactory }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              style: TextButton.styleFrom(
                splashFactory: splashFactory,
              ),
              onPressed: () { },
              child: const Text('test'),
            ),
          ),
        ),
      );
    }

    // NoSplash.splashFactory, no splash circles drawn
    await tester.pumpWidget(buildFrame(splashFactory: NoSplash.splashFactory));
    {
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('test')));
      final MaterialInkController material = Material.of(tester.element(find.text('test')))!;
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    // Default splashFactory (from Theme.of().splashFactory), one splash circle drawn.
    await tester.pumpWidget(buildFrame());
    {
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('test')));
      final MaterialInkController material = Material.of(tester.element(find.text('test')))!;
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 1));
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('TextButton.icon does not overflow', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/77815
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text( // Much wider than 200
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut a euismod nibh. Morbi laoreet purus.',
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), null);
  });

  testWidgets('TextButton.icon icon,label layout', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    final Key iconKey = UniqueKey();
    final Key labelKey = UniqueKey();
    final ButtonStyle style = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard, // dx=0, dy=0
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: TextButton.icon(
              key: buttonKey,
              style: style,
              onPressed: () {},
              icon: SizedBox(key: iconKey, width: 50, height: 100),
              label: SizedBox(key: labelKey, width: 50, height: 100),
            ),
          ),
        ),
      ),
    );

    // The button's label and icon are separated by a gap of 8:
    // 46 [icon 50] 8 [label 50] 46
    // The overall button width is 200. So:
    // icon.x = 46
    // label.x = 46 + 50 + 8 = 104

    expect(tester.getRect(find.byKey(buttonKey)), const Rect.fromLTRB(0.0, 0.0, 200.0, 100.0));
    expect(tester.getRect(find.byKey(iconKey)), const Rect.fromLTRB(46.0, 0.0, 96.0, 100.0));
    expect(tester.getRect(find.byKey(labelKey)), const Rect.fromLTRB(104.0, 0.0, 154.0, 100.0));
  });

  testWidgets('TextButton maximumSize', (WidgetTester tester) async {
    final Key key0 = UniqueKey();
    final Key key1 = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton(
                  key: key0,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(24, 36),
                    maximumSize: const Size.fromWidth(64),
                  ),
                  onPressed: () { },
                  child: const Text('A B C D E F G H I J K L M N O P'),
                ),
                TextButton.icon(
                  key: key1,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(24, 36),
                    maximumSize: const Size.fromWidth(104),
                  ),
                  onPressed: () {},
                  icon: Container(color: Colors.red, width: 32, height: 32),
                  label: const Text('A B C D E F G H I J K L M N O P'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key0)), const Size(64.0, 128.0));
    expect(tester.getSize(find.byKey(key1)), const Size(104.0, 128.0));
  });

  testWidgets('Fixed size TextButton, same as minimumSize == maximumSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(fixedSize: const Size(200, 200)),
                onPressed: () { },
                child: const Text('200x200'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(200, 200),
                  maximumSize: const Size(200, 200),
                ),
                onPressed: () { },
                child: const Text('200,200'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.widgetWithText(TextButton, '200x200')), const Size(200, 200));
    expect(tester.getSize(find.widgetWithText(TextButton, '200,200')), const Size(200, 200));
  });

}

TextStyle? _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}
