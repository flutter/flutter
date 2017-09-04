// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('onSaved callback is called', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    String fieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: new TextFormField(
              onSaved: (String value) { fieldValue = value; },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    expect(fieldValue, isNull);

    Future<Null> checkText(String testValue) async {
      await tester.enterText(find.byType(TextFormField), testValue);
      formKey.currentState.save();
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('onChanged callback is called', (WidgetTester tester) async {
    String fieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new TextField(
              onChanged: (String value) { fieldValue = value; },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    expect(fieldValue, isNull);

    Future<Null> checkText(String testValue) async {
      await tester.enterText(find.byType(TextField), testValue);
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text only when validate is called', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    String errorText(String value) => value + '/error';

    Widget builder(bool autovalidate) {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            autovalidate: autovalidate,
            child: new TextFormField(
              validator: errorText,
            ),
          ),
        ),
      );
    }

    // Start off not autovalidating.
    await tester.pumpWidget(builder(false));

    Future<Null> checkErrorText(String testValue) async {
      formKey.currentState.reset();
      await tester.enterText(find.byType(TextFormField), testValue);
      await tester.pumpWidget(builder(false));

      // We have to manually validate if we're not autovalidating.
      expect(find.text(errorText(testValue)), findsNothing);
      formKey.currentState.validate();
      await tester.pump();
      expect(find.text(errorText(testValue)), findsOneWidget);

      // Try again with autovalidation. Should validate immediately.
      formKey.currentState.reset();
      await tester.enterText(find.byType(TextFormField), testValue);
      await tester.pumpWidget(builder(true));

      expect(find.text(errorText(testValue)), findsOneWidget);
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Multiple TextFormFields communicate', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    final GlobalKey<FormFieldState<String>> fieldKey = new GlobalKey<FormFieldState<String>>();
    // Input 2's validator depends on a input 1's value.
    String errorText(String input) => fieldKey.currentState.value?.toString() + '/error';

    Widget builder() {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Material(
            child: new Form(
              key: formKey,
              autovalidate: true,
              child: new ListView(
                children: <Widget>[
                  new TextFormField(
                    key: fieldKey,
                  ),
                  new TextFormField(
                    validator: errorText,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    Future<Null> checkErrorText(String testValue) async {
      await tester.enterText(find.byType(TextFormField).first, testValue);
      await tester.pump();

      // Check for a new Text widget with our error text.
      expect(find.text(testValue + '/error'), findsOneWidget);
      return null;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input', (WidgetTester tester) async {
    final String initialValue = 'hello';
    final TextEditingController controller = new TextEditingController(text: initialValue);
    final GlobalKey<FormFieldState<String>> inputKey = new GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new TextFormField(
              key: inputKey,
              controller: controller,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextFormField));

    // initial value should be loaded into keyboard editing state
    expect(tester.testTextInput.editingState, isNotNull);
    expect(tester.testTextInput.editingState['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState.value, equals(initialValue));
    await tester.enterText(find.byType(TextFormField), 'world');
    await tester.pump();
    expect(inputKey.currentState.value, equals('world'));
    expect(editableText.widget.controller.text, equals('world'));
  });

  testWidgets('No crash when a TextFormField is removed from the tree', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    String fieldValue;

    Widget builder(bool remove) {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: remove ? new Container() : new TextFormField(
              autofocus: true,
              onSaved: (String value) { fieldValue = value; },
              validator: (String value) { return value.isEmpty ? null : 'yes'; }
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder(false));

    expect(fieldValue, isNull);
    expect(formKey.currentState.validate(), isTrue);

    await tester.enterText(find.byType(TextFormField), 'Test');
    await tester.pumpWidget(builder(false));

    // Form wasn't saved yet.
    expect(fieldValue, null);
    expect(formKey.currentState.validate(), isFalse);

    formKey.currentState.save();

    // Now fieldValue is saved.
    expect(fieldValue, 'Test');
    expect(formKey.currentState.validate(), isFalse);

    // Now remove the field with an error.
    await tester.pumpWidget(builder(true));

    // Reset the form. Should not crash.
    formKey.currentState.reset();
    formKey.currentState.save();
    expect(formKey.currentState.validate(), isTrue);
  });
}
