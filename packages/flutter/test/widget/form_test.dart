// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sky_services/editing/editing.mojom.dart' as mojom;
import 'package:test/test.dart';

class MockKeyboard implements mojom.Keyboard {
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
  WidgetsFlutterBinding.ensureInitialized(); // for serviceMocker
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(mojom.Keyboard.serviceName, mockKeyboard);

  void enterText(String testValue) {
    // Simulate entry of text through the keyboard.
    expect(mockKeyboard.client, isNotNull);
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = testValue
      ..composingBase = 0
      ..composingExtent = testValue.length);
  }

  test('Setter callback is called', () {
    testWidgets((WidgetTester tester) {
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

      tester.pumpWidget(builder());

      void checkText(String testValue) {
        enterText(testValue);

        // Check that the FormField's setter was called.
        expect(fieldValue, equals(testValue));
        tester.pumpWidget(builder());
      }

      checkText('Test');
      checkText('');
    });
  });

  test('Validator sets the error text', () {
    testWidgets((WidgetTester tester) {
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

      tester.pumpWidget(builder());

      void checkErrorText(String testValue) {
        enterText(testValue);
        tester.pumpWidget(builder());

        // Check for a new Text widget with our error text.
        expect(tester, hasWidget(find.text(errorText(testValue))));
      }

      checkErrorText('Test');
      checkErrorText('');
    });
  });

  test('Multiple Inputs communicate', () {
    testWidgets((WidgetTester tester) {
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

      tester.pumpWidget(builder());
      Focus.moveTo(inputKey);
      tester.pump();

      void checkErrorText(String testValue) {
        enterText(testValue);
        tester.pumpWidget(builder());

        expect(fieldValue, equals(testValue));

        // Check for a new Text widget with our error text.
        expect(tester, hasWidget(find.text(errorText(testValue))));
      }

      checkErrorText('Test');
      checkErrorText('');
    });
  });
}
