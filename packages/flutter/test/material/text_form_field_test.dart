// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Passes textAlign to underlying TextField', (WidgetTester tester) async {
    const TextAlign alignment = TextAlign.center;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              textAlign: alignment,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlign, alignment);
  });

  testWidgets('Passes textAlignVertical to underlying TextField', (WidgetTester tester) async {
    const TextAlignVertical textAlignVertical = TextAlignVertical.bottom;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              textAlignVertical: textAlignVertical,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlignVertical, textAlignVertical);
  });

  testWidgets('Passes textInputAction to underlying TextField', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textInputAction, TextInputAction.next);
  });

  testWidgets('Passes onEditingComplete to underlying TextField', (WidgetTester tester) async {
    final VoidCallback onEditingComplete = () { };

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onEditingComplete: onEditingComplete,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.onEditingComplete, onEditingComplete);
  });

  testWidgets('Passes cursor attributes to underlying TextField', (WidgetTester tester) async {
    const double cursorWidth = 3.14;
    const Radius cursorRadius = Radius.circular(4);
    const Color cursorColor = Colors.purple;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              cursorWidth: cursorWidth,
              cursorRadius: cursorRadius,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.cursorWidth, cursorWidth);
    expect(textFieldWidget.cursorRadius, cursorRadius);
    expect(textFieldWidget.cursorColor, cursorColor);
  });

  testWidgets('onFieldSubmit callbacks are called', (WidgetTester tester) async {
    bool _called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onFieldSubmitted: (String value) { _called = true; },
            ),
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_called, true);
  });

  testWidgets('onChanged callbacks are called', (WidgetTester tester) async {
    String _value;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onChanged: (String value) {
                _value = value;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Soup');
    await tester.pump();
    expect(_value, 'Soup');
  });

  testWidgets('autovalidate is passed to super', (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              autovalidate: true,
              validator: (String value) { _validateCalled++; return null; },
            ),
          ),
        ),
      ),
    );

    expect(_validateCalled, 1);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(_validateCalled, 2);
  });

  testWidgets('validate is called if widget is enabled', (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              enabled: true,
              autovalidate: true,
              validator: (String value) { _validateCalled += 1; return null; },
            ),
          ),
        ),
      ),
    );

    expect(_validateCalled, 1);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(_validateCalled, 2);
  });

  testWidgets('passing a buildCounter shows returned widget', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
            child: TextFormField(
              buildCounter: (BuildContext context, { int currentLength, int maxLength, bool isFocused }) {
                return Text('${currentLength.toString()} of ${maxLength.toString()}');
              },
              maxLength: 10,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 of 10'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01234');
    await tester.pump();

    expect(find.text('5 of 10'), findsOneWidget);
  });

  testWidgets('readonly text form field will hide cursor by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              initialValue: 'readonly',
              readOnly: true,
            ),
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextFormField));
    expect(tester.testTextInput.hasAnyClients, false);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);

    await tester.longPress(find.byType(TextFormField));
    await tester.pump();

    // Context menu should not have paste.
    expect(find.text('SELECT ALL'), findsOneWidget);
    expect(find.text('PASTE'), findsNothing);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
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
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onTap: () {
                tapCount += 1;
              },
            ),
          ),
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(TextField));
    // Wait a bit so they're all single taps and not double taps.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapCount, 3);
  });
}
