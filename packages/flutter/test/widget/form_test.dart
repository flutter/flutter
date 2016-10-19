// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_services/editing.dart' as mojom;
import 'package:meta/meta.dart';

class MockKeyboard extends mojom.KeyboardProxy {
  MockKeyboard() : super.unbound();

  mojom.KeyboardClient client;
  mojom.EditingState currentState;

  @override
  void setClient(@checked mojom.KeyboardClientStub client, mojom.KeyboardConfiguration configuraiton) {
    this.client = client.impl;
  }

  @override
  void show() { }

  @override
  void hide() { }

  @override
  void setEditingState(mojom.EditingState state) {
    currentState = state;
  }

}

void main() {
  MockKeyboard mockKeyboard = new MockKeyboard();

  setUpAll(() {
    serviceMocker.registerMockService(mockKeyboard);
  });

  void enterText(String testValue) {
    // Simulate entry of text through the keyboard.
    expect(mockKeyboard.client, isNotNull);
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = testValue
      ..composingBase = 0
      ..composingExtent = testValue.length);
  }

  testWidgets('Setter callback is called', (WidgetTester tester) async {
    FormField<InputValue> field = new FormField<InputValue>();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Input(
              formField: field,
            )
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    expect(field.value, isNull);

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(field.value.text, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    String errorText(String input) => '$input/error';

    FormField<InputValue> field = new FormField<InputValue>(
      validator: (InputValue value) => errorText(value.text)
    );

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Input(
              key: inputKey,
              formField: field,
            )
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    Future<Null> checkErrorText(String testValue) async {
      enterText(testValue);
      await tester.pump();
      // Check for a new Text widget with our error text.
      expect(find.text(errorText(testValue)), findsOneWidget);
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Multiple Inputs communicate', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    GlobalKey focusKey = new GlobalKey();

    String errorText(String value) => '$value/error';

    FormField<InputValue> field1 = new FormField<InputValue>();

    FormField<InputValue> field2 = new FormField<InputValue>(
      // Input 2's validator depends on a input 1's value.
      validator: (InputValue input) => errorText(field1.value?.text),
    );

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Focus(
              key: focusKey,
              child: new Block(
                children: <Widget>[
                  new Input(
                    key: inputKey,
                    formField: field1,
                  ),
                  new Input(
                    formField: field2,
                  )
                ]
              )
            )
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    Focus.moveTo(inputKey);
    await tester.pump();

    Future<Null> checkErrorText(String testValue) async {
      enterText(testValue);
      await tester.pump();

      expect(field1.value.text, equals(testValue));

      // Check for a new Text widget with our error text.
      expect(find.text(errorText(testValue)), findsOneWidget);
      return null;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input', (WidgetTester tester) async {
    String initialValue = 'hello';

    FormField<InputValue> field = new FormField<InputValue>(
      initialValue: new InputValue(text: initialValue),
    );

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Input(
              formField: field,
            )
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    // initial value should be loaded into keyboard editing state
    expect(mockKeyboard.currentState, isNotNull);
    expect(mockKeyboard.currentState.text, equals(initialValue));

    // initial value should also be visible in the raw input line
    RawInputState editableText = tester.state(find.byType(RawInput));
    expect(editableText.config.value.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(field.value.text, initialValue);
    enterText('world');
    expect(field.value.text, 'world');
    await tester.pump();
    expect(editableText.config.value.text, 'world');

  });
}
