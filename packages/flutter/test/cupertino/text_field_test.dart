// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior, PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments;
        break;
    }
  }
}

void main() {
  final MockClipboard mockClipboard = MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  // Returns the first RenderEditable.
  RenderEditable findRenderEditable(WidgetTester tester) {
    final RenderObject root = tester.renderObject(find.byType(EditableText));
    expect(root, isNotNull);

    RenderEditable renderEditable;
    void recursiveFinder(RenderObject child) {
      if (child is RenderEditable) {
        renderEditable = child;
        return;
      }
      child.visitChildren(recursiveFinder);
    }
    root.visitChildren(recursiveFinder);
    expect(renderEditable, isNotNull);
    return renderEditable;
  }

  List<TextSelectionPoint> globalize(Iterable<TextSelectionPoint> points, RenderBox box) {
    return points.map<TextSelectionPoint>((TextSelectionPoint point) {
      return TextSelectionPoint(
        box.localToGlobal(point.point),
        point.direction,
      );
    }).toList();
  }

  Offset textOffsetToPosition(WidgetTester tester, int offset) {
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(
        TextSelection.collapsed(offset: offset),
      ),
      renderEditable,
    );
    expect(endpoints.length, 1);
    return endpoints[0].point + const Offset(0.0, -2.0);
  }

  testWidgets(
    'takes available space horizontally and takes intrinsic space vertically no-strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(strutStyle: StrutStyle.disabled),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 29), // 29 is the height of the default font + padding etc.
      );
    },
  );

  testWidgets(
    'takes available space horizontally and takes intrinsic space vertically',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 29), // 29 is the height of the default font (17) + decoration (12).
      );
    },
  );

  testWidgets(
    'multi-lined text fields are intrinsically taller no-strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(
                maxLines: 3,
                strutStyle: StrutStyle.disabled,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 63), // 63 is the height of the default font (17) * maxlines (3) + decoration height (12).
      );
    },
  );

  testWidgets(
    'multi-lined text fields are intrinsically taller',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(maxLines: 3),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 63),
      );
    },
  );

  testWidgets(
    'strut height override',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(
                maxLines: 3,
                strutStyle: StrutStyle(
                  fontSize: 8,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 36),
      );
    },
  );

  testWidgets(
    'strut forces field taller',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(
                maxLines: 3,
                style: TextStyle(fontSize: 10),
                strutStyle: StrutStyle(
                  fontSize: 18,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 66),
      );
    },
  );

  testWidgets(
    'default text field has a border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(),
          ),
        ),
      );

      final BoxDecoration decoration = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CupertinoTextField),
          matching: find.byType(DecoratedBox),
        ),
      ).decoration;

      expect(
        decoration.borderRadius,
        BorderRadius.circular(4.0),
      );
      expect(
        decoration.border.bottom.color,
        CupertinoColors.lightBackgroundGray,
      );
    },
  );

  testWidgets(
    'decoration can be overrriden',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              decoration: null,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CupertinoTextField),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'text entries are padded by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: TextEditingController(text: 'initial'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('initial')) - tester.getTopLeft(find.byType(CupertinoTextField)),
        const Offset(6.0, 6.0),
      );
    },
  );

  testWidgets('iOS cursor has offset', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoTextField(),
      ),
    );

    final EditableText editableText = tester.firstWidget(find.byType(EditableText));
    expect(editableText.cursorOffset, const Offset(-2.0 / 3.0, 0));
  });

  testWidgets('Cursor animates on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoTextField(),
      ),
    );

    final Finder textFinder = find.byType(CupertinoTextField);
    await tester.tap(textFinder);
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorColor.alpha, 255);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(renderEditable.cursorColor.alpha, 255);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 100));

    expect(renderEditable.cursorColor.alpha, 110);

    await tester.pump(const Duration(milliseconds: 100));

    expect(renderEditable.cursorColor.alpha, 16);
    await tester.pump(const Duration(milliseconds: 50));

    expect(renderEditable.cursorColor.alpha, 0);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Cursor radius is 2.0 on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoTextField(),
      ),
    );

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorRadius, const Radius.circular(2.0));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('cursor android golden', (WidgetTester tester) async {
    final Widget widget = CupertinoApp(
      home: Center(
        child: RepaintBoundary(
          key: const ValueKey<int>(1),
          child: ConstrainedBox(
            constraints: BoxConstraints.loose(const Size(400, 400)),
            child: const CupertinoTextField(),
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    const String testValue = 'A short phrase';
    await tester.enterText(find.byType(CupertinoTextField), testValue);

    await tester.tapAt(textOffsetToPosition(tester, testValue.length));
    await tester.pump();

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('text_field_cursor_test.0.1.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('cursor iOS golden', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Widget widget = CupertinoApp(
      home: Center(
        child: RepaintBoundary(
          key: const ValueKey<int>(1),
          child: ConstrainedBox(
            constraints: BoxConstraints.loose(const Size(400, 400)),
            child: const CupertinoTextField(),
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    const String testValue = 'A short phrase';
    await tester.enterText(find.byType(CupertinoTextField), testValue);

    await tester.tapAt(textOffsetToPosition(tester, testValue.length));
    await tester.pump();

    debugDefaultTargetPlatformOverride = null;
    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('text_field_cursor_test.1.1.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets(
    'can control text content via controller',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      controller.text = 'controller text';
      await tester.pump();

      expect(find.text('controller text'), findsOneWidget);

      controller.text = '';
      await tester.pump();

      expect(find.text('controller text'), findsNothing);
    },
  );

  testWidgets(
    'placeholders are lightly colored and disappears once typing starts',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              placeholder: 'placeholder',
            ),
          ),
        ),
      );

      final Text placeholder = tester.widget(find.text('placeholder'));
      expect(placeholder.style.color, const Color(0xFFC2C2C2));

      await tester.enterText(find.byType(CupertinoTextField), 'input');
      await tester.pump();
      expect(find.text('placeholder'), findsNothing);
    },
  );

  testWidgets(
    "placeholderStyle modifies placeholder's style and doesn't affect text's style",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              placeholder: 'placeholder',
              style: TextStyle(
                color: Color(0X00FFFFFF),
                fontWeight: FontWeight.w300,
              ),
              placeholderStyle: TextStyle(
                color: Color(0XAAFFFFFF),
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ),
      );

      final Text placeholder = tester.widget(find.text('placeholder'));
      expect(placeholder.style.color, const Color(0XAAFFFFFF));
      expect(placeholder.style.fontWeight, FontWeight.w600);

      await tester.enterText(find.byType(CupertinoTextField), 'input');
      await tester.pump();

      final EditableText inputText = tester.widget(find.text('input'));
      expect(inputText.style.color, const Color(0X00FFFFFF));
      expect(inputText.style.fontWeight, FontWeight.w300);
    },
  );

  testWidgets(
    'prefix widget is in front of the text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              prefix: const Icon(CupertinoIcons.add),
              controller: TextEditingController(text: 'input'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.add)).dx + 6.0, // 6px standard padding around input.
        tester.getTopLeft(find.byType(EditableText)).dx,
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        tester.getTopLeft(find.byType(CupertinoTextField)).dx
            + tester.getSize(find.byIcon(CupertinoIcons.add)).width
            + 6.0,
      );
    },
  );

  testWidgets(
    'prefix widget respects visibility mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              prefix: Icon(CupertinoIcons.add),
              prefixMode: OverlayVisibilityMode.editing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.add), findsNothing);
      // The position should just be the edge of the whole text field plus padding.
      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        tester.getTopLeft(find.byType(CupertinoTextField)).dx + 6.0,
      );

      await tester.enterText(find.byType(CupertinoTextField), 'text input');
      await tester.pump();

      expect(find.text('text input'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);

      // Text is now moved to the right.
      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        tester.getTopLeft(find.byType(CupertinoTextField)).dx
            + tester.getSize(find.byIcon(CupertinoIcons.add)).width
            + 6.0,
      );
    },
  );

  testWidgets(
    'suffix widget is after the text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              suffix: Icon(CupertinoIcons.add),
            ),
          ),
        ),
      );

      expect(
        tester.getTopRight(find.byType(EditableText)).dx + 6.0,
        tester.getTopLeft(find.byIcon(CupertinoIcons.add)).dx, // 6px standard padding around input.
      );

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        tester.getTopRight(find.byType(CupertinoTextField)).dx
            - tester.getSize(find.byIcon(CupertinoIcons.add)).width
            - 6.0,
      );
    },
  );

  testWidgets(
    'suffix widget respects visibility mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              suffix: Icon(CupertinoIcons.add),
              suffixMode: OverlayVisibilityMode.notEditing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);

      await tester.enterText(find.byType(CupertinoTextField), 'text input');
      await tester.pump();

      expect(find.text('text input'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.add), findsNothing);
    },
  );

  testWidgets(
    'can customize padding',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(EditableText)),
        tester.getSize(find.byType(CupertinoTextField)),
      );
    },
  );

  testWidgets(
    'padding is in between prefix and suffix no-strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              padding: EdgeInsets.all(20.0),
              prefix: SizedBox(height: 100.0, width: 100.0),
              suffix: SizedBox(height: 50.0, width: 50.0),
              strutStyle: StrutStyle.disabled,
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        // Size of prefix + padding.
        100.0 + 20.0,
      );

      expect(tester.getTopLeft(find.byType(EditableText)).dy, 291.5);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 50.0 - 20.0,
      );

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              padding: EdgeInsets.all(30.0),
              prefix: SizedBox(height: 100.0, width: 100.0),
              suffix: SizedBox(height: 50.0, width: 50.0),
              strutStyle: StrutStyle.disabled,
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        100.0 + 30.0,
      );

      // Since the highest component, the prefix box, is higher than
      // the text + paddings, the text's vertical position isn't affected.
      expect(tester.getTopLeft(find.byType(EditableText)).dy, 291.5);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 50.0 - 30.0,
      );
    },
  );

  testWidgets(
    'padding is in between prefix and suffix',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              padding: EdgeInsets.all(20.0),
              prefix: SizedBox(height: 100.0, width: 100.0),
              suffix: SizedBox(height: 50.0, width: 50.0),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        // Size of prefix + padding.
        100.0 + 20.0,
      );

      expect(tester.getTopLeft(find.byType(EditableText)).dy, 291.5);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 50.0 - 20.0,
      );

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              padding: EdgeInsets.all(30.0),
              prefix: SizedBox(height: 100.0, width: 100.0),
              suffix: SizedBox(height: 50.0, width: 50.0),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        100.0 + 30.0,
      );

      // Since the highest component, the prefix box, is higher than
      // the text + paddings, the text's vertical position isn't affected.
      expect(tester.getTopLeft(find.byType(EditableText)).dy, 291.5);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 50.0 - 30.0,
      );
    },
  );

  testWidgets(
    'clear button shows with right visibility mode',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
              clearButtonMode: OverlayVisibilityMode.always,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsOneWidget);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 30.0  /* size of button */ - 6.0 /* padding */,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsNothing);
      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 6.0 /* padding */,
      );

      await tester.enterText(find.byType(CupertinoTextField), 'text input');
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsOneWidget);
      expect(find.text('text input'), findsOneWidget);
      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 30.0 - 6.0,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
              clearButtonMode: OverlayVisibilityMode.notEditing,
            ),
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsNothing);

      controller.text = '';
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsOneWidget);
    },
  );

  testWidgets(
    'clear button removes text',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'placeholder',
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
          ),
        ),
      );

      controller.text = 'text entry';
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.clear_thick_circled));
      await tester.pump();

      expect(controller.text, '');
      expect(find.text('placeholder'), findsOneWidget);
      expect(find.text('text entry'), findsNothing);
      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsNothing);
    },
  );

  testWidgets(
    'tapping clear button also calls onChanged when text not empty',
        (WidgetTester tester) async {
      String value = 'text entry';
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'placeholder',
              onChanged: (String newValue) => value = newValue,
              clearButtonMode: OverlayVisibilityMode.always,
            ),
          ),
        ),
      );

      controller.text = value;
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.clear_thick_circled));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.text('text entry'), findsNothing);
      expect(value, isEmpty);
    },
  );

  testWidgets(
    'clear button yields precedence to suffix',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
              clearButtonMode: OverlayVisibilityMode.always,
              suffix: const Icon(CupertinoIcons.add_circled_solid),
              suffixMode: OverlayVisibilityMode.editing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.add_circled_solid), findsNothing);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 30.0  /* size of button */ - 6.0 /* padding */,
      );

      controller.text = 'non empty text';
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.clear_thick_circled), findsNothing);
      expect(find.byIcon(CupertinoIcons.add_circled_solid), findsOneWidget);

      // Still just takes the space of one widget.
      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 24.0  /* size of button */ - 6.0 /* padding */,
      );
    },
  );

  testWidgets(
    'font style controls intrinsic height no-strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              strutStyle: StrutStyle.disabled,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        29.0,
      );

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              style: TextStyle(
                // A larger font.
                fontSize: 50.0,
              ),
              strutStyle: StrutStyle.disabled,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        62.0,
      );
    },
  );

  testWidgets(
    'font style controls intrinsic height',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        29.0,
      );

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              style: TextStyle(
                // A larger font.
                fontSize: 50.0,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        62.0,
      );
    },
  );

  testWidgets(
    'RTL puts attachments to the right places',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: CupertinoTextField(
                padding: EdgeInsets.all(20.0),
                prefix: Icon(CupertinoIcons.book),
                clearButtonMode: OverlayVisibilityMode.always,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byIcon(CupertinoIcons.book)).dx,
        800.0 - 24.0,
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.clear_thick_circled)).dx,
        24.0,
      );
    },
  );

  testWidgets(
    'text fields with no max lines can grow no-strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              maxLines: null,
              strutStyle: StrutStyle.disabled,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        29.0, // Initially one line high.
      );

      await tester.enterText(find.byType(CupertinoTextField), '\n');
      await tester.pump();

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        46.0, // Initially one line high.
      );
    },
  );

  testWidgets(
    'text fields with no max lines can grow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              maxLines: null,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        29.0, // Initially one line high.
      );

      await tester.enterText(find.byType(CupertinoTextField), '\n');
      await tester.pump();

      expect(
        tester.getSize(find.byType(CupertinoTextField)).height,
        46.0, // Initially one line high.
      );
    },
  );

  testWidgets('cannot enter new lines onto single line TextField', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            controller: controller,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), 'abc\ndef');

    expect(controller.text, 'abcdef');
  });

  testWidgets('toolbar has the same visual regardless of theming', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: "j'aime la poutine",
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoTextField(
              controller: controller,
            ),
          ],
        ),
      ),
    );

    await tester.longPressAt(
      tester.getTopRight(find.text("j'aime la poutine"))
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    Text text = tester.widget<Text>(find.text('Paste'));
    expect(text.style.color, CupertinoColors.white);
    expect(text.style.fontSize, 14);
    expect(text.style.letterSpacing, -0.11);
    expect(text.style.fontWeight, FontWeight.w300);

    // Change the theme.
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(fontSize: 100, fontWeight: FontWeight.w800),
          ),
        ),
        home: Column(
          children: <Widget>[
            CupertinoTextField(
              controller: controller,
            ),
          ],
        ),
      ),
    );

    await tester.longPressAt(
      tester.getTopRight(find.text("j'aime la poutine"))
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    text = tester.widget<Text>(find.text('Paste'));
    // The toolbar buttons' text are still the same style.
    expect(text.style.color, CupertinoColors.white);
    expect(text.style.fontSize, 14);
    expect(text.style.letterSpacing, -0.11);
    expect(text.style.fontWeight, FontWeight.w300);
  });

  testWidgets('copy paste', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: const <Widget>[
            CupertinoTextField(
              placeholder: 'field 1',
            ),
            CupertinoTextField(
              placeholder: 'field 2',
            ),
          ],
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(CupertinoTextField, 'field 1'),
      "j'aime la poutine",
    );
    await tester.pump();

    // Tap an area inside the EditableText but with no text.
    await tester.longPressAt(
      tester.getTopRight(find.text("j'aime la poutine"))
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Select All'));
    await tester.pump();

    await tester.tap(find.text('Cut'));
    await tester.pump();

    // Placeholder 1 is back since the text is cut.
    expect(find.text('field 1'), findsOneWidget);
    expect(find.text('field 2'), findsOneWidget);

    await tester.longPress(find.text('field 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(find.text('field 1'), findsOneWidget);
    expect(find.text("j'aime la poutine"), findsOneWidget);
    expect(find.text('field 2'), findsNothing);
  });

  testWidgets(
    'tap moves cursor to the edge of the word it tapped on',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // We moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // But don't trigger the toolbar.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'slow double tap does not trigger double tap',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // Plain collapsed selection.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // No toolbar.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'double tap selects word and first tap of double tap moves cursor',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump();

      // Second tap selects the word around the cursor.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );

      // Selected text shows 3 toolbar buttons.
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'double tap hold selects word',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      final TestGesture gesture =
         await tester.startGesture(textfieldStart + const Offset(150.0, 5.0));
      // Hold the press.
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );

      // Selected text shows 3 toolbar buttons.
      expect(find.byType(CupertinoButton), findsNWidgets(3));

      await gesture.up();
      await tester.pump();

      // Still selected.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'tap after a double tap select is not affected',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tapAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump();

      // Plain collapsed selection at the edge of first word. In iOS 12, the
      // the first tap after a double tap ends up putting the cursor at where
      // you tapped instead of the edge like every other single tap. This is
      // likely a bug in iOS 12 and not present in other versions.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // No toolbar.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'long press moves cursor to the exact long press position and shows toolbar',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // Collapsed cursor for iOS long press.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 3, affinity: TextAffinity.upstream),
      );

      // Collapsed toolbar shows 2 buttons.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
    },
  );

  testWidgets(
    'long press tap cannot initiate a double tap',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // We ended up moving the cursor to the edge of the same word and dismissed
      // the toolbar.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // The toolbar from the long press is now dismissed by the second tap.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'long press drag moves the cursor under the drag and shows toolbar on lift',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      final TestGesture gesture =
          await tester.startGesture(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      // Long press on iOS shows collapsed selection cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 3, affinity: TextAffinity.upstream),
      );
      // Toolbar only shows up on long press up.
      expect(find.byType(CupertinoButton), findsNothing);

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // The selection position is now moved with the drag.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 6, affinity: TextAffinity.upstream),
      );
      expect(find.byType(CupertinoButton), findsNothing);

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // The selection position is now moved with the drag.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 9, affinity: TextAffinity.upstream),
      );
      expect(find.byType(CupertinoButton), findsNothing);

      await gesture.up();
      await tester.pump();

      // The selection isn't affected by the gesture lift.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 9, affinity: TextAffinity.upstream),
      );
      // The toolbar now shows up.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
    },
  );

  testWidgets('long press drag can edge scroll', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure Angrignon Peel Côte-des-Neiges',
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            controller: controller,
            maxLines: 1,
          ),
        ),
      ),
    );

    final RenderEditable renderEditable = tester.renderObject<RenderEditable>(
      find.byElementPredicate((Element element) => element.renderObject is RenderEditable)
    );

    List<TextSelectionPoint> lastCharEndpoint = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 66), // Last character's position.
    );

    expect(lastCharEndpoint.length, 1);
    // Just testing the test and making sure that the last character is off
    // the right side of the screen.
    expect(lastCharEndpoint[0].point.dx, moreOrLessEquals(1094.73486328125));

    final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

    final TestGesture gesture =
        await tester.startGesture(textfieldStart + const Offset(300, 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 18, affinity: TextAffinity.upstream),
    );
    expect(find.byType(CupertinoButton), findsNothing);

    await gesture.moveBy(const Offset(600, 0));
    // To the edge of the screen basically.
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 54, affinity: TextAffinity.upstream),
    );
    // Keep moving out.
    await gesture.moveBy(const Offset(1, 0));
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 61, affinity: TextAffinity.upstream),
    );
    await gesture.moveBy(const Offset(1, 0));
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 66, affinity: TextAffinity.upstream),
    ); // We're at the edge now.
    expect(find.byType(CupertinoButton), findsNothing);

    await gesture.up();
    await tester.pump();

    // The selection isn't affected by the gesture lift.
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 66, affinity: TextAffinity.upstream),
    );
    // The toolbar now shows up.
    expect(find.byType(CupertinoButton), findsNWidgets(2));

    lastCharEndpoint = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 66), // Last character's position.
    );

    expect(lastCharEndpoint.length, 1);
    // The last character is now on screen.
    expect(lastCharEndpoint[0].point.dx, moreOrLessEquals(786.73486328125));

    final List<TextSelectionPoint> firstCharEndpoint = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 0), // First character's position.
    );
    expect(firstCharEndpoint.length, 1);
    // The first character is now offscreen to the left.
    expect(firstCharEndpoint[0].point.dx, moreOrLessEquals(-308.20499999821186));
  });

  testWidgets(
    'long tap after a double tap select is not affected',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor to the beginning of the second word.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.longPressAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump();

      // Plain collapsed selection at the exact tap position.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 6, affinity: TextAffinity.upstream),
      );

      // Long press toolbar.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
    },
  );

  testWidgets(
    'double tap after a long tap is not affected',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump();

      // Double tap selection.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );
      // Shows toolbar.
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'double tap chains work',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: controller,
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );
      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));

      // Double tap selecting the same word somewhere else is fine.
      await tester.tapAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );
      await tester.tapAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets('force press selects word', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

    const int pointerValue = 1;
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      textfieldStart + const Offset(150.0, 5.0),
      PointerDownEvent(
        pointer: pointerValue,
        position: textfieldStart + const Offset(150.0, 5.0),
        pressure: 3.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    // We expect the force press to select a word at the given location.
    expect(
      controller.selection,
      const TextSelection(baseOffset: 8, extentOffset: 12),
    );

    await gesture.up();
    await tester.pump();
    // Shows toolbar.
    expect(find.byType(CupertinoButton), findsNWidgets(3));
  });

  testWidgets('force press on unsupported devices falls back to tap', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

    const int pointerValue = 1;
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      textfieldStart + const Offset(150.0, 5.0),
      PointerDownEvent(
        pointer: pointerValue,
        position: textfieldStart + const Offset(150.0, 5.0),
        // iPhone 6 and below report 0 across the board.
        pressure: 0,
        pressureMax: 0,
        pressureMin: 0,
      ),
    );
    await gesture.up();
    // Fall back to a single tap which selects the edge of the word.
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 8),
    );

    await tester.pump();
    // Falling back to a single tap doesn't trigger a toolbar.
    expect(find.byType(CupertinoButton), findsNothing);
  });

  testWidgets('Cannot drag one handle past the other', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            dragStartBehavior: DragStartBehavior.down,
            controller: controller,
            style: const TextStyle(
              fontFamily: 'Ahem',
              fontSize: 10.0,
            ),
          ),
        ),
      ),
    );

    // Double tap on 'e' to select 'def'.
    final Offset ePos = textOffsetToPosition(tester, 5);
    await tester.tapAt(ePos, pointer: 7);
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 4);
    await tester.tapAt(ePos, pointer: 7);
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 7);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    expect(endpoints.length, 2);

    // Drag the right handle until there's only 1 char selected.
    // We use a small offset because the endpoint is on the very corner
    // of the handle.
    final Offset handlePos = endpoints[1].point;
    Offset newHandlePos = textOffsetToPosition(tester, 5); // Position of 'e'.
    final TestGesture gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 5);

    newHandlePos = textOffsetToPosition(tester, 2); // Position of 'c'.
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, 4);
    // The selection doesn't move beyond the left handle. There's always at
    // least 1 char selected.
    expect(controller.selection.extentOffset, 5);
  });

  testWidgets('Can select text by dragging with a mouse', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            dragStartBehavior: DragStartBehavior.down,
            controller: controller,
            style: const TextStyle(
              fontFamily: 'Ahem',
              fontSize: 10.0,
            ),
          ),
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(CupertinoTextField), testValue);
    // Skip past scrolling animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

    final TestGesture gesture = await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await gesture.moveTo(gPos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, testValue.indexOf('e'));
    expect(controller.selection.extentOffset, testValue.indexOf('g'));
  });

  testWidgets('Continuous dragging does not cause flickering', (WidgetTester tester) async {
    int selectionChangedCount = 0;
    const String testValue = 'abc def ghi';
    final TextEditingController controller = TextEditingController(text: testValue);

    controller.addListener(() {
      selectionChangedCount++;
    });

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            dragStartBehavior: DragStartBehavior.down,
            controller: controller,
            style: const TextStyle(
              fontFamily: 'Ahem',
              fontSize: 10.0,
            ),
          ),
        ),
      ),
    );

    final Offset cPos = textOffsetToPosition(tester, 2); // Index of 'c'.
    final Offset gPos = textOffsetToPosition(tester, 8); // Index of 'g'.
    final Offset hPos = textOffsetToPosition(tester, 9); // Index of 'h'.

    // Drag from 'c' to 'g'.
    final TestGesture gesture = await tester.startGesture(cPos, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await gesture.moveTo(gPos);
    await tester.pumpAndSettle();

    expect(selectionChangedCount, isNonZero);
    selectionChangedCount = 0;
    expect(controller.selection.baseOffset, 2);
    expect(controller.selection.extentOffset, 8);

    // Tiny movement shouldn't cause text selection to change.
    await gesture.moveTo(gPos + const Offset(4.0, 0.0));
    await tester.pumpAndSettle();
    expect(selectionChangedCount, 0);

    // Now a text selection change will occur after a significant movement.
    await gesture.moveTo(hPos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectionChangedCount, 1);
    expect(controller.selection.baseOffset, 2);
    expect(controller.selection.extentOffset, 9);
  });

  testWidgets(
    'text field respects theme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          theme: CupertinoThemeData(
            brightness: Brightness.dark,
          ),
          home: Center(
            child: CupertinoTextField(),
          ),
        ),
      );

      final BoxDecoration decoration = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CupertinoTextField),
          matching: find.byType(DecoratedBox),
        ),
      ).decoration;

      expect(
        decoration.border.bottom.color,
        CupertinoColors.lightBackgroundGray, // Border color is the same regardless.
      );

      await tester.enterText(find.byType(CupertinoTextField), 'smoked meat');
      await tester.pump();

      expect(
        tester.renderObject<RenderEditable>(
          find.byElementPredicate((Element element) => element.renderObject is RenderEditable)
        ).text.style.color,
        CupertinoColors.white,
      );
    },
  );

  testWidgets('text field respects keyboardAppearance from theme', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.textInput.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
        ),
        home: Center(
          child: CupertinoTextField(),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    final MethodCall setClient = log.first;
    expect(setClient.method, 'TextInput.setClient');
    expect(setClient.arguments.last['keyboardAppearance'], 'Brightness.dark');
  });

  testWidgets('text field can override keyboardAppearance from theme', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.textInput.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
        ),
        home: Center(
          child: CupertinoTextField(
            keyboardAppearance: Brightness.light,
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    final MethodCall setClient = log.first;
    expect(setClient.method, 'TextInput.setClient');
    expect(setClient.arguments.last['keyboardAppearance'], 'Brightness.light');
  });

  testWidgets('cursorColor respects theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoTextField(),
      ),
    );

    final Finder textFinder = find.byType(CupertinoTextField);
    await tester.tap(textFinder);
    await tester.pump();

    final EditableTextState editableTextState =
    tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorColor, CupertinoColors.activeBlue);

    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoTextField(),
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
        ),
      ),
    );

    await tester.pump();
    expect(renderEditable.cursorColor, CupertinoColors.activeOrange);

    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoTextField(),
        theme: CupertinoThemeData(
          primaryColor: Color(0xFFF44336),
        ),
      ),
    );

    await tester.pump();
    expect(renderEditable.cursorColor, const Color(0xFFF44336));
  });

  testWidgets('cursor can override color from theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(),
        home: Center(
          child: CupertinoTextField(
            cursorColor: Color(0xFFF44336),
          ),
        ),
      ),
    );

    final EditableText editableText = tester.firstWidget(find.byType(EditableText));
    expect(editableText.cursorColor, const Color(0xFFF44336));
  });

  testWidgets('iOS shows selection handles', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const String testText = 'lorem ipsum';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(),
        home: Center(
          child: CupertinoTextField(
            controller: controller,
          ),
        ),
      ),
    );

    final RenderEditable renderEditable =
      tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;

    await tester.tapAt(textOffsetToPosition(tester, 5));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pumpAndSettle();

    final List<Widget> transitions =
      find.byType(FadeTransition).evaluate().map((Element e) => e.widget).toList();
    expect(transitions.length, 2);
    final FadeTransition left = transitions[0];
    final FadeTransition right = transitions[1];

    expect(left.opacity.value, equals(1.0));
    expect(right.opacity.value, equals(1.0));

    debugDefaultTargetPlatformOverride = null;
  });
}
