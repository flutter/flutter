// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:js_util' as js_util;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/text_editing_main.dart' as app;
import 'package:flutter/material.dart';

import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;

  testWidgets('Focused text field creates a native input element',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    SystemChannels.textInput.setMockMethodCallHandler(null);

    // Focus on a TextFormField.
    final Finder finder = find.byKey(const Key('input'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('input')));

    // A native input element will be appended to the DOM.
    final List<Node> nodeList = document.getElementsByTagName('input');
    expect(nodeList.length, equals(1));
    final InputElement input =
        document.getElementsByTagName('input')[0] as InputElement;
    // The element's value will be the same as the textFormField's value.
    expect(input.value, 'Text1');

    // Change the value of the TextFormField.
    final TextFormField textFormField = tester.widget(finder);
    textFormField.controller.text = 'New Value';
    // DOM element's value also changes.
    expect(input.value, 'New Value');
  });

  testWidgets('Input field with no initial value works',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    SystemChannels.textInput.setMockMethodCallHandler(null);

    // Focus on a TextFormField.
    final Finder finder = find.byKey(const Key('empty-input'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('empty-input')));

    // A native input element will be appended to the DOM.
    final List<Node> nodeList = document.getElementsByTagName('input');
    expect(nodeList.length, equals(1));
    final InputElement input =
        document.getElementsByTagName('input')[0] as InputElement;
    // The element's value will be empty.
    expect(input.value, '');

    // Change the value of the TextFormField.
    final TextFormField textFormField = tester.widget(finder);
    textFormField.controller.text = 'New Value';
    // DOM element's value also changes.
    expect(input.value, 'New Value');
  });

  testWidgets('Pressing enter on the text field triggers submit',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    SystemChannels.textInput.setMockMethodCallHandler(null);

    // This text will show no-enter initially. It will have 'enter-pressed'
    // after `onFieldSubmitted` of TextField is triggered.
    final Finder textFinder = find.byKey(const Key('text'));
    expect(textFinder, findsOneWidget);
    final Text text = tester.widget(textFinder);
    expect(text.data, 'no-enter');

    // Focus on a TextFormField.
    final Finder textFormFielsFinder = find.byKey(const Key('input2'));
    expect(textFormFielsFinder, findsOneWidget);
    await tester.tap(find.byKey(const Key('input2')));

    // // Press Tab. This should trigger `onFieldSubmitted` of TextField.
    final InputElement input =
        document.getElementsByTagName('input')[0] as InputElement;
    dispatchKeyboardEvent(input, 'keydown', <String, dynamic>{
      'keyCode': 13, // Enter.
      'cancelable': true,
    });

    await tester.pumpAndSettle();

    final Finder textFinder2 = find.byKey(const Key('text'));
    expect(textFinder2, findsOneWidget);
    final Text text2 = tester.widget(textFinder2);
    expect(text2.data, 'enter pressed');
  });

  testWidgets('Jump between TextFormFields with tab key',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    SystemChannels.textInput.setMockMethodCallHandler(null);

    // Focus on a TextFormField.
    final Finder finder = find.byKey(const Key('input'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('input')));

    // A native input element will be appended to the DOM.
    final List<Node> nodeList = document.getElementsByTagName('input');
    expect(nodeList.length, equals(1));
    final InputElement input =
        document.getElementsByTagName('input')[0] as InputElement;

    // Press Tab. The focus should move to the next TextFormField.
    dispatchKeyboardEvent(input, 'keydown', <String, dynamic>{
      'key': 'Tab',
      'code': 'Tab',
      'bubbles': true,
      'cancelable': true,
    });

    await tester.pumpAndSettle();

    // A native input element for the next TextField should be attached to the
    // DOM.
    final InputElement input2 =
        document.getElementsByTagName('input')[0] as InputElement;
    expect(input2.value, 'Text2');
  });
}

KeyboardEvent dispatchKeyboardEvent(
    EventTarget target, String type, Map<String, dynamic> args) {
  final dynamic jsKeyboardEvent = js_util.getProperty(window, 'KeyboardEvent');
  final List<dynamic> eventArgs = <dynamic>[
    type,
    args,
  ];

  final KeyboardEvent event = js_util.callConstructor(
          jsKeyboardEvent, js_util.jsify(eventArgs) as List<dynamic>)
      as KeyboardEvent;
  target.dispatchEvent(event);

  return event;
}
