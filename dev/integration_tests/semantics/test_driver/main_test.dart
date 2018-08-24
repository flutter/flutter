// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'android_testing.dart';

void main() {
  group('semantics suite', () {
    FlutterDriver driver;

    Future<AndroidSemanticsNode> getSemantics(SerializableFinder finder) async {
      final int id = await driver.getSemanticsId(finder);
      final String data = await driver.requestData('getSemanticsNode#$id');
      return new AndroidSemanticsNode.deserialize(data);
    }

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await driver.setSemantics(true);
    });

    group('SelectionControls', () {
      setUpAll(() async {
        await driver.tap(find.text('SelectionControls'));
      });

      test('Checkbox has correct Android semantics', () async {
        const String checkboxKey = 'SelectionControls#Checkbox1';
        const String disabledKey = 'SelectionControls#Checkbox2';
        expect(await getSemantics(find.byValueKey(checkboxKey)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));

        await driver.tap(find.byValueKey(checkboxKey));
        expect(await getSemantics(find.byValueKey(checkboxKey)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isChecked: true,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));

        expect(await getSemantics(find.byValueKey(disabledKey)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isCheckable: true,
          isEnabled: false,
          actions: const <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));
      });

      test('Radio has correct Android semantics', () async {
        const String radioKey = 'SelectionControls#Radio2';
        expect(await getSemantics(find.byValueKey(radioKey)), hasAndroidSemantics(
          className: AndroidClassName.radio,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));

        await driver.tap(find.byValueKey(radioKey));
        expect(await getSemantics(find.byValueKey(radioKey)), hasAndroidSemantics(
          className: AndroidClassName.radio,
          isChecked: true,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));
      });

      test('Switch has correct Android semantics', () async {
        const String switchKey = 'SelectionControls#Switch';
        expect(await getSemantics(find.byValueKey(switchKey)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));

        await driver.tap(find.byValueKey(switchKey));
        expect(await getSemantics(find.byValueKey(switchKey)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isChecked: true,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.accessibilityFocus,
          ],
        ));
      });

      tearDownAll(() async {
        await driver.tap(find.byValueKey('back'));
      });
    });

    group('TextFields', () {
      setUpAll(() async {
        await driver.tap(find.text('TextFields'));
      });

      test('TextField has correct semantics', () async {
        const String textFieldKey = 'TextFields#TextField1';
        expect(await getSemantics(find.byValueKey(textFieldKey)),
          hasAndroidSemantics(
            text: 'Name',
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: false,
            isEnabled: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.accessibilityFocus,
            ],
          ));

        await driver.tap(find.byValueKey(textFieldKey));
        expect(await getSemantics(find.byValueKey(textFieldKey)),
          hasAndroidSemantics(
            text: 'Name\nWhat is your name?',
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEnabled: true,
            isEditable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.setSelection,
              AndroidSemanticsAction.copy,
            ],
          ));

        await driver.enterText('testing');
        expect(await getSemantics(find.byValueKey(textFieldKey)),
          hasAndroidSemantics(
            text: 'testing, Name',
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEnabled: true,
            isEditable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.setSelection,
              AndroidSemanticsAction.copy,
            ],
          ));
      });

      test('Obscured TextField has correct semantics', () async {
        const String textFieldKey = 'TextFields#TextField2';
        expect(await getSemantics(find.byValueKey(textFieldKey)),
          hasAndroidSemantics(
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: false,
            isEnabled: true,
            isPassword: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.accessibilityFocus,
            ],
          ));

        await driver.tap(find.byValueKey(textFieldKey));
        await driver.enterText('hunter2');
        expect(await getSemantics(find.byValueKey(textFieldKey)),
          hasAndroidSemantics(
            text: '•••••••',
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEnabled: true,
            isEditable: true,
            isPassword: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.setSelection,
              AndroidSemanticsAction.copy,
            ],
          ));
      });

      tearDownAll(() async {
        await driver.tap(find.byValueKey('back'));
      });
    });

    tearDownAll(() async {
      driver?.close();
    });
  });
}
