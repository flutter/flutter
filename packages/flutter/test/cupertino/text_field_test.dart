// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
        const Size(200, 29), // 29 is the height of the default font + padding etc.
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
          matching: find.byType(DecoratedBox)
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
          matching: find.byType(DecoratedBox)
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
      "j'aime la poutine"
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
    'long press tap is not a double tap',
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

      // Collapsed toolbar shows 2 buttons.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

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
}
