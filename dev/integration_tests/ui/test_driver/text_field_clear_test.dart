// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:integration_ui/keys.dart' as keys;
import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver?.close();
    });

    test('Ensure marked text can be cleared with no crash', () async {
      // This is a regression test for https://github.com/flutter/flutter/issues/24276

      final SerializableFinder defaultTextField = find.byValueKey(keys.kDefaultTextField);
      await driver.waitFor(defaultTextField);

      // Focus the text field to show the keyboard.
      await driver.tap(defaultTextField);
      await Future<void>.delayed(const Duration(seconds: 5));

      // Set the state of the input to include some marked text
      const String text = 'hello world';
      final String textEditingValue = json.encode(<String, dynamic>{
        'text': text,
        'selectionBase': text.length,
        'selectionExtent': text.length,
        'markedBase': 0,
        'markedExtent': text.length,
      });
      // TODO this needs to indicate the textfield somehow. Maybe pass the key...
      await driver.setEditingState(textEditingValue);
      /*
      await driver.setMarkedText(json.encode(<String, dynamic>{
        'markedText': text,
        'markedBase': text.length,
        'markedExtent': 0,
      }));
      */
      final String textEditingValueClear = json.encode(<String, dynamic>{
        'composingBase': -1,
        'composingExtent': -1,
        'selectionAffinity': 'TextAffinity.downstream',
        'selectionBase': -1,
        'selectionExtent': -1,
        'selectionIsDirectional': 0,
        'text': text,
      });
      await driver.setEditingState(textEditingValueClear);
      await Future<void>.delayed(const Duration(seconds: 5));
      //await driver.waitFor(find.text(text));
      final String textAfterSet = await driver.getTextFieldText(defaultTextField);
      expect(textAfterSet, text);

      // Press the clear button
      final SerializableFinder clearButton = find.byValueKey(keys.kClearButton);
      await driver.waitFor(clearButton);
      await driver.tap(clearButton);
      await Future<void>.delayed(const Duration(seconds: 5));

      // The text should be gone
      //await driver.waitForAbsent(find.text(text));
      final String textAfterClear = await driver.getTextFieldText(defaultTextField);
      expect(textAfterClear, '');
    });
  });
}
