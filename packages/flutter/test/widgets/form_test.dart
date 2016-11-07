// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'mock_text_input.dart';

void main() {
  MockTextInput mockTextInput = new MockTextInput()..register();

  void enterText(String text) {
    mockTextInput.enterText(text);
  }

  testWidgets('onSaved callback is called', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    String fieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: new InputFormField(
              onSaved: (InputValue value) { fieldValue = value.text; },
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    expect(fieldValue, isNull);

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      await tester.idle();
      formKey.currentState.save();
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    String errorText(InputValue input) => input.text + '/error';

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new InputFormField(
               key: inputKey,
               validator: errorText
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    Future<Null> checkErrorText(String testValue) async {
      enterText(testValue);
      await tester.idle();
      await tester.pump();
      // Check for a new Text widget with our error text.
      expect(find.text(errorText(new InputValue(text: testValue))), findsOneWidget);
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Multiple Inputs communicate', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    GlobalKey<FormFieldState<InputValue>> fieldKey = new GlobalKey<FormFieldState<InputValue>>();
    GlobalKey inputFocusKey = new GlobalKey();
    GlobalKey focusKey = new GlobalKey();
    // Input 2's validator depends on a input 1's value.
    String errorText(InputValue input) => fieldKey.currentState.value?.text.toString() + '/error';

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: new Focus(
              key: focusKey,
              child: new Block(
                children: <Widget>[
                  new InputFormField(
                    autofocus: true,
                    key: fieldKey,
                    focusKey: inputFocusKey,
                  ),
                  new InputFormField(
                    validator: errorText,
                  ),
                ]
              )
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await tester.pump();
    Focus.moveTo(inputFocusKey);

    Future<Null> checkErrorText(String testValue) async {
      enterText(testValue);
      await tester.idle();
      await tester.pump();

      // Check for a new Text widget with our error text.
      expect(find.text(testValue + '/error'), findsOneWidget);
      return null;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input', (WidgetTester tester) async {
    String initialValue = 'hello';
    GlobalKey<FormFieldState<InputValue>> inputKey = new GlobalKey<FormFieldState<InputValue>>();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new InputFormField(
              key: inputKey,
              initialValue: new InputValue(text: initialValue),
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    // initial value should be loaded into keyboard editing state
    expect(mockTextInput.editingState, isNotNull);
    expect(mockTextInput.editingState['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    RawInputState editableText = tester.state(find.byType(RawInput));
    expect(editableText.config.value.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState.value.text, equals(initialValue));
    enterText('world');
    await tester.idle();
    await tester.pump();
    expect(inputKey.currentState.value.text, equals('world'));
    expect(editableText.config.value.text, equals('world'));
  });

  testWidgets('No crash when a FormField is removed from the tree', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    GlobalKey fieldKey = new GlobalKey();
    String fieldValue;

    Widget builder(bool remove) {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: new InputFormField(
              key: fieldKey,
              autofocus: true,
              onSaved: (InputValue value) { fieldValue = value.text; },
              validator: (InputValue value) { return value.text.isEmpty ? null : 'yes'; }
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder(false));
    await tester.pump();

    expect(fieldValue, isNull);
    expect(formKey.currentState.hasErrors, isFalse);

    enterText('Test');
    await tester.idle();
    await tester.pumpWidget(builder(false));

    // Form wasn't saved, but validator runs immediately.
    expect(fieldValue, null);
    expect(formKey.currentState.hasErrors, isTrue);

    formKey.currentState.save();

    // Now fieldValue is saved.
    expect(fieldValue, 'Test');
    expect(formKey.currentState.hasErrors, isTrue);

    // Now remove the field with an error.
    await tester.pumpWidget(builder(true));

    // Reset the form. Should not crash.
    formKey.currentState.reset();
    formKey.currentState.save();
    expect(formKey.currentState.hasErrors, isFalse);
  });
}
