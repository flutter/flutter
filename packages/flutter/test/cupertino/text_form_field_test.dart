// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Passes textAlign to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const TextAlign alignment = TextAlign.center;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            textAlign: alignment,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlign, alignment);
  });

  testWidgets('Passes textAlignVertical to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const TextAlignVertical textAlignVertical = TextAlignVertical.bottom;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            textAlignVertical: textAlignVertical,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlignVertical, textAlignVertical);
  });

  testWidgets('Passes textInputAction to underlying CupertinoTextField',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            textInputAction: TextInputAction.next,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textInputAction, TextInputAction.next);
  });

  testWidgets('Passes onEditingComplete to underlying CupertinoTextField',
      (WidgetTester tester) async {
    final VoidCallback onEditingComplete = () {};

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            onEditingComplete: onEditingComplete,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.onEditingComplete, onEditingComplete);
  });

  testWidgets('Passes padding to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const EdgeInsetsGeometry padding = EdgeInsets.all(1.0);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            padding: padding,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.padding, padding);
  });

  testWidgets('Passes scrollPadding to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const EdgeInsetsGeometry scrollPadding = EdgeInsets.all(1.0);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            scrollPadding: scrollPadding,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.scrollPadding, scrollPadding);
  });

  testWidgets('Passes keyboardAppearance to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const Brightness keyboardAppearance = Brightness.dark;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            keyboardAppearance: keyboardAppearance,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.keyboardAppearance, keyboardAppearance);
  });

  testWidgets('Passes placeholder to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const String placeholder = 'Test Placeholder';

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            placeholder: placeholder,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.placeholder, placeholder);
  });

  testWidgets('Passes decoration to underlying CupertinoTextField',
      (WidgetTester tester) async {
    final BoxDecoration decoration = BoxDecoration(
      border: Border.all(
        color: CupertinoColors.lightBackgroundGray,
        style: BorderStyle.solid,
        width: 0.0,
      ),
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            decoration: decoration,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.decoration, decoration);
  });

  testWidgets('Passes cursor attributes to underlying CupertinoTextField',
      (WidgetTester tester) async {
    const double cursorWidth = 3.14;
    const Radius cursorRadius = Radius.circular(4);
    const Color cursorColor = CupertinoColors.white;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            cursorWidth: cursorWidth,
            cursorRadius: cursorRadius,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(CupertinoTextField);
    expect(textFieldFinder, findsOneWidget);

    final CupertinoTextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.cursorWidth, cursorWidth);
    expect(textFieldWidget.cursorRadius, cursorRadius);
    expect(textFieldWidget.cursorColor, cursorColor);
  });

  testWidgets('onFieldSubmit callbacks are called',
      (WidgetTester tester) async {
    bool _called = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            onFieldSubmitted: (String value) {
              _called = true;
            },
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(CupertinoTextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_called, true);
  });

  testWidgets('onChanged callbacks are called', (WidgetTester tester) async {
    String _value;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            onChanged: (String value) {
              _value = value;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), 'Soup');
    await tester.pump();
    expect(_value, 'Soup');
  });

  testWidgets('autovalidate is passed to super', (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            autovalidate: true,
            validator: (String value) {
              _validateCalled++;
              return null;
            },
          ),
        ),
      ),
    );

    expect(_validateCalled, 1);
    await tester.enterText(find.byType(CupertinoTextField), 'a');
    await tester.pump();
    expect(_validateCalled, 2);
  });
  testWidgets('validate is called if widget is enabled',
      (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            enabled: true,
            autovalidate: true,
            validator: (String value) {
              _validateCalled += 1;
              return null;
            },
          ),
        ),
      ),
    );

    expect(_validateCalled, 1);
    await tester.enterText(find.byType(CupertinoTextField), 'a');
    await tester.pump();
    expect(_validateCalled, 2);
  });

  testWidgets('readonly text form field will hide cursor by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            initialValue: 'readonly',
            readOnly: true,
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(CupertinoTextFormField));
    expect(tester.testTextInput.hasAnyClients, false);

    await tester.tap(find.byType(CupertinoTextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);

    await tester.longPress(find.byType(CupertinoTextFormField));
    await tester.pump();

    // Context menu should not have paste.
    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Paste'), findsNothing);

    final EditableTextState editableTextState =
        tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    // Make sure it does not paint caret for a period of time.
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));
  });

  testWidgets('onTap is called upon tap', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextFormField(
            onTap: () {
              tapCount += 1;
            },
          ),
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(CupertinoTextField));
    // Wait a bit so they're all single taps and not double taps.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(CupertinoTextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(CupertinoTextField));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapCount, 3);
  });
}
