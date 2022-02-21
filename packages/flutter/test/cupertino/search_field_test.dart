// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'default search field has a border radius',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(),
          ),
        ),
      );

      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(CupertinoSearchTextField),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as BoxDecoration;

      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(9)),
      );
    },
  );

  testWidgets(
    'decoration overrides default background color',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              decoration: BoxDecoration(color: Color.fromARGB(1, 1, 1, 1)),
            ),
          ),
        ),
      );

      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(CupertinoSearchTextField),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as BoxDecoration;

      expect(
        decoration.color,
        const Color.fromARGB(1, 1, 1, 1),
      );
    },
  );

  testWidgets(
    'decoration overrides default border radius',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero),
            ),
          ),
        ),
      );

      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(CupertinoSearchTextField),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as BoxDecoration;

      expect(
        decoration.borderRadius,
        BorderRadius.zero,
      );
    },
  );

  testWidgets(
    'text entries are padded by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: TextEditingController(text: 'initial'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('initial')) -
            tester.getTopLeft(find.byType(CupertinoSearchTextField)),
        const Offset(29.8, 8.0),
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
            child: CupertinoSearchTextField(
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

  testWidgets('placeholder color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.dark),
        home: Center(
          child: CupertinoSearchTextField(),
        ),
      ),
    );

    Text placeholder = tester.widget(find.text('Search'));
    expect(placeholder.style!.color!.value, CupertinoColors.systemGrey.darkColor.value);

    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.light),
        home: Center(
          child: CupertinoSearchTextField(),
        ),
      ),
    );

    placeholder = tester.widget(find.text('Search'));
    expect(placeholder.style!.color!.value, CupertinoColors.systemGrey.color.value);
  });

  testWidgets(
    "placeholderStyle modifies placeholder's style and doesn't affect text's style",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              placeholder: 'placeholder',
              style: TextStyle(
                color: Color(0x00FFFFFF),
                fontWeight: FontWeight.w300,
              ),
              placeholderStyle: TextStyle(
                color: Color(0xAAFFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

      final Text placeholder = tester.widget(find.text('placeholder'));
      expect(placeholder.style!.color, const Color(0xAAFFFFFF));
      expect(placeholder.style!.fontWeight, FontWeight.w600);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'input');
      await tester.pump();

      final EditableText inputText = tester.widget(find.text('input'));
      expect(inputText.style.color, const Color(0x00FFFFFF));
      expect(inputText.style.fontWeight, FontWeight.w300);
    },
  );

  testWidgets(
    'prefix widget is in front of the text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: TextEditingController(text: 'input'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.search)).dx + 3.8,
        tester.getTopLeft(find.byType(EditableText)).dx,
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        tester.getTopLeft(find.byType(CupertinoSearchTextField)).dx +
            tester.getSize(find.byIcon(CupertinoIcons.search)).width +
            9.8,
      );
    },
  );

  testWidgets(
    'suffix widget is after the text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: TextEditingController(text: 'Hi'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopRight(find.byType(EditableText)).dx + 5.0,
        tester.getTopLeft(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx,
      );

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        tester.getTopRight(find.byType(CupertinoSearchTextField)).dx -
            tester
                .getSize(find.byIcon(CupertinoIcons.xmark_circle_fill))
                .width -
            10.0,
      );
    },
  );

  testWidgets('prefix widget visibility', (WidgetTester tester) async {
      const Key prefixIcon = Key('prefix');

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              prefixIcon: SizedBox(
                key: prefixIcon,
                width: 50,
                height: 50,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.search), findsNothing);
      expect(find.byKey(prefixIcon), findsOneWidget);

      await tester.enterText(
          find.byType(CupertinoSearchTextField), 'text input');
      await tester.pump();

      expect(find.text('text input'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.search), findsNothing);
      expect(find.byKey(prefixIcon), findsOneWidget);
  });

  testWidgets(
    'suffix widget respects visibility mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              suffixMode: OverlayVisibilityMode.notEditing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'text input');
      await tester.pump();

      expect(find.text('text input'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
    },
  );

  testWidgets(
    'clear button shows with right visibility mode',
    (WidgetTester tester) async {
      TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'text input');
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
      expect(find.text('text input'), findsOneWidget);

      controller = TextEditingController();

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
              suffixMode: OverlayVisibilityMode.notEditing,
            ),
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

      controller.text = 'input';
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
    },
  );

  testWidgets(
    'clear button removes text',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
            ),
          ),
        ),
      );

      controller.text = 'text entry';
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();

      expect(controller.text, '');
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('text entry'), findsNothing);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
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
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder',
              onChanged: (String newValue) => value = newValue,
            ),
          ),
        ),
      );

      controller.text = value;
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.text('text entry'), findsNothing);
      expect(value, isEmpty);
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
              child: CupertinoSearchTextField(
                suffixMode: OverlayVisibilityMode.always,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byIcon(CupertinoIcons.search)).dx,
        800.0 - 26.0,
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx,
        25.0,
      );
    },
  );

  testWidgets(
    'Can modify prefix and suffix insets',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              suffixMode: OverlayVisibilityMode.always,
              prefixInsets: EdgeInsets.zero,
              suffixInsets: EdgeInsets.zero,
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byIcon(CupertinoIcons.search)).dx,
        0.0,
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx,
        800.0,
      );
    },
  );

  testWidgets(
    'custom suffix onTap overrides default clearing behavior',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(text: 'Text');
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              onSuffixTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();

      expect(controller.text, isNotEmpty);
      expect(find.text('Text'), findsOneWidget);
    },
  );

  testWidgets('onTap is properly forwarded to the inner text field', (WidgetTester tester) async {
    int onTapCallCount = 0;

    // onTap can be null.
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(),
        ),
      ),
    );

    // onTap callback is called if not null.
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            onTap: () {
              onTapCallCount++;
            },
          ),
        ),
      ),
    );

    expect(onTapCallCount, 0);
    await tester.tap(find.byType(CupertinoTextField));
    expect(onTapCallCount, 1);
  });

  testWidgets('autocorrect is properly forwarded to the inner text field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            autocorrect: false,
          ),
        ),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.autocorrect, false);
  });

  testWidgets('enabled is properly forwarded to the inner text field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            enabled: false,
          ),
        ),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.enabled, false);
  });

  testWidgets('textInputAction is set to TextInputAction.search by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(),
        ),
      ),
    );

    final CupertinoTextField textField = tester.widget(find.byType(CupertinoTextField));
    expect(textField.textInputAction, TextInputAction.search);
  });

  testWidgets('autofocus:true gives focus to the widget', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoSearchTextField(
            focusNode: focusNode,
            autofocus: true,
          ),
        ),
      ),
    );

    expect(focusNode.hasFocus, isTrue);
  });
}
