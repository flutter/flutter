// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter.services.editing/editing.mojom.dart' as mojom;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockKeyboard extends mojom.KeyboardProxy {
  MockKeyboard() : super.unbound();

  mojom.KeyboardClient client;

  @override
  void setClient(mojom.KeyboardClientStub client, mojom.KeyboardConfiguration configuraiton) {
    this.client = client.impl;
  }

  @override
  void show() {}

  @override
  void hide() {}

  @override
  void setEditingState(mojom.EditingState state) {}
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
    GlobalKey inputKey = new GlobalKey();
    String fieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new Input(
              key: inputKey,
              formField: new FormField<String>(
                setter: (String val) { fieldValue = val; }
              )
            )
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    Future<Null> checkText(String testValue) {
      enterText(testValue);

      // Check that the FormField's setter was called.
      expect(fieldValue, equals(testValue));
      return tester.pumpWidget(builder());
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
      await tester.pumpWidget(builder());

      // Check for a new Text widget with our error text.
      expect(find.text(errorText(testValue)), findsOneWidget);
      return null;
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
                      setter: (String val) { fieldValue = val; }
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
      await tester.pumpWidget(builder());

      expect(fieldValue, equals(testValue));

      // Check for a new Text widget with our error text.
      expect(find.text(errorText(testValue)), findsOneWidget);
      return null;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });
}
