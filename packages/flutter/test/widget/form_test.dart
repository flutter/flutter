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
  void show() {}

  @override
  void hide() {}

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
    String fieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Input(
              formField: new FormField<String>(
                setter: (String value) { fieldValue = value; }
              )
            )
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    expect(fieldValue, isNull);

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    String errorText(String input) => input + '/error';

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Input(
              key: inputKey,
              formField: new FormField<String>(
                validator: errorText
              )
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
    // Input 1's text value.
    String fieldValue;
    // Input 2's validator depends on a input 1's value.
    String errorText(String input) => fieldValue.toString() + '/error';

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
                    formField: new FormField<String>(
                      setter: (String value) { fieldValue = value; }
                    )
                  ),
                  new Input(
                    formField: new FormField<String>(
                      validator: errorText
                    )
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

      expect(fieldValue, equals(testValue));

      // Check for a new Text widget with our error text.
      expect(find.text(errorText(testValue)), findsOneWidget);
      return null;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input', (WidgetTester tester) async {
    String initialValue = 'hello';
    String currentValue;

    Widget builder() {
      return new Center(
          child: new Material(
              child: new Form(
                  child: new Input(
                      value: new InputValue(text: initialValue),
                      formField: new FormField<String>(
                          setter: (String value) { currentValue = value; }
                      )
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
    RawInputLineState editableText = tester.state(find.byType(RawInputLine));
    expect(editableText.config.value.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(currentValue, isNull);
    enterText('world');
    expect(currentValue, equals('world'));
    await tester.pump();
    expect(editableText.config.value.text, equals('world'));

  });
}
