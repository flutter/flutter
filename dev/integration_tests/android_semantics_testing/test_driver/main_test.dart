// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:android_semantics_testing/test_constants.dart';
import 'package:android_semantics_testing/android_semantics_testing.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;

String adbPath() {
  final String androidHome = io.Platform.environment['ANDROID_HOME'] ?? io.Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome == null) {
    return 'adb';
  } else {
    return path.join(androidHome, 'platform-tools', 'adb');
  }
}

void main() {
  group('AccessibilityBridge', () {
    FlutterDriver driver;
    Future<AndroidSemanticsNode> getSemantics(SerializableFinder finder) async {
      final int id = await driver.getSemanticsId(finder);
      final String data = await driver.requestData('getSemanticsNode#$id');
      return AndroidSemanticsNode.deserialize(data);
    }

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      // Say the magic words..
      final io.Process run = await io.Process.start(adbPath(), const <String>[
        'shell',
        'settings',
        'put',
        'secure',
        'enabled_accessibility_services',
        'com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService',
      ]);
      await run.exitCode;
    });

    tearDownAll(() async {
      // ... And turn it off again
      final io.Process run = await io.Process.start(adbPath(), const <String>[
        'shell',
        'settings',
        'put',
        'secure',
        'enabled_accessibility_services',
        'null',
      ]);
      await run.exitCode;
      driver?.close();
    });

    group('TextField', () {
      setUpAll(() async {
        await driver.tap(find.text(textFieldRoute));
      });

      test('TextField has correct Android semantics', () async {
        final SerializableFinder normalTextField = find.descendant(
          of: find.byValueKey(normalTextFieldKeyValue),
          matching: find.byType('Semantics'),
          firstMatchOnly: true,
        );
        expect(
          await getSemantics(normalTextField),
          hasAndroidSemantics(
            className: AndroidClassName.editText,
            isEditable: true,
            isFocusable: true,
            isFocused: false,
            isPassword: false,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(normalTextField);
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(
          await getSemantics(normalTextField),
          hasAndroidSemantics(
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEditable: true,
            isPassword: false,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.clearAccessibilityFocus,
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.copy,
              AndroidSemanticsAction.setSelection,
            ],
          ),
        );

        await driver.enterText('hello world');
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(
          await getSemantics(normalTextField),
          hasAndroidSemantics(
            text: 'hello world',
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEditable: true,
            isPassword: false,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.clearAccessibilityFocus,
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.copy,
              AndroidSemanticsAction.setSelection,
            ],
          ),
        );
      });

      test('password TextField has correct Android semantics', () async {
        final SerializableFinder passwordTextField = find.descendant(
          of: find.byValueKey(passwordTextFieldKeyValue),
          matching: find.byType('Semantics'),
          firstMatchOnly: true,
        );
        expect(
          await getSemantics(passwordTextField),
          hasAndroidSemantics(
            className: AndroidClassName.editText,
            isEditable: true,
            isFocusable: true,
            isFocused: false,
            isPassword: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(passwordTextField);

        expect(
          await getSemantics(passwordTextField),
          hasAndroidSemantics(
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEditable: true,
            isPassword: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.clearAccessibilityFocus,
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.copy,
              AndroidSemanticsAction.setSelection,
            ],
          ),
        );

        await driver.enterText('hello world');

        expect(
          await getSemantics(passwordTextField),
          hasAndroidSemantics(
            text: '\u{2022}' * ('hello world'.length),
            className: AndroidClassName.editText,
            isFocusable: true,
            isFocused: true,
            isEditable: true,
            isPassword: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.clearAccessibilityFocus,
              AndroidSemanticsAction.click,
              AndroidSemanticsAction.copy,
              AndroidSemanticsAction.setSelection,
            ],
          ),
        );
      });

      tearDownAll(() async {
        await driver.tap(find.byValueKey('back'));
      });
    });

    group('SelectionControls', () {
      setUpAll(() async {
        await driver.tap(find.text(selectionControlsRoute));
      });

      test('Checkbox has correct Android semantics', () async {
        expect(
          await getSemantics(find.byValueKey(checkboxKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.checkBox,
            isChecked: false,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(find.byValueKey(checkboxKeyValue));

        expect(
          await getSemantics(find.byValueKey(checkboxKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.checkBox,
            isChecked: true,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );
        expect(
          await getSemantics(find.byValueKey(disabledCheckboxKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.checkBox,
            isCheckable: true,
            isEnabled: false,
            actions: const <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
            ],
          ),
        );
      });
      test('Radio has correct Android semantics', () async {
        expect(
          await getSemantics(find.byValueKey(radio2KeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.radio,
            isChecked: false,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(find.byValueKey(radio2KeyValue));

        expect(
          await getSemantics(find.byValueKey(radio2KeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.radio,
            isChecked: true,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );
      });
      test('Switch has correct Android semantics', () async {
        expect(
          await getSemantics(find.byValueKey(switchKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.toggleSwitch,
            isChecked: false,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(find.byValueKey(switchKeyValue));

        expect(
          await getSemantics(find.byValueKey(switchKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.toggleSwitch,
            isChecked: true,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );
      });

      // Regression test for https://github.com/flutter/flutter/issues/20820.
      test('Switch can be labeled', () async {
        expect(
          await getSemantics(find.byValueKey(labeledSwitchKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.toggleSwitch,
            isChecked: false,
            isCheckable: true,
            isEnabled: true,
            isFocusable: true,
            contentDescription: switchLabel,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );
      });

      tearDownAll(() async {
        await driver.tap(find.byValueKey('back'));
      });
    });

    group('Popup Controls', () {
      setUpAll(() async {
        await driver.tap(find.text(popupControlsRoute));
      });

      test('Popup Menu has correct Android semantics', () async {
        expect(
          await getSemantics(find.byValueKey(popupButtonKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.button,
            isChecked: false,
            isCheckable: false,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(find.byValueKey(popupButtonKeyValue));
        try {
          // We have to wait wall time here because we're waiting for TalkBack to
          // catch up.
          await Future<void>.delayed(const Duration(milliseconds: 1500));

          for (String item in popupItems) {
            expect(
                await getSemantics(find.byValueKey('$popupKeyValue.$item')),
                hasAndroidSemantics(
                  className: AndroidClassName.view,
                  isChecked: false,
                  isCheckable: false,
                  isEnabled: true,
                  isFocusable: true,
                  actions: <AndroidSemanticsAction>[
                    if (item == popupItems.first) AndroidSemanticsAction.clearAccessibilityFocus,
                    if (item != popupItems.first) AndroidSemanticsAction.accessibilityFocus,
                    AndroidSemanticsAction.click,
                  ],
                ),
                reason: "Popup $item doesn't have the right semantics");
          }
          await driver.tap(find.byValueKey('$popupKeyValue.${popupItems.first}'));

          // Pop up the menu again, to verify that TalkBack gets the right answer
          // more than just the first time.
          await driver.tap(find.byValueKey(popupButtonKeyValue));
          await Future<void>.delayed(const Duration(milliseconds: 1500));

          for (String item in popupItems) {
            expect(
                await getSemantics(find.byValueKey('$popupKeyValue.$item')),
                hasAndroidSemantics(
                  className: AndroidClassName.view,
                  isChecked: false,
                  isCheckable: false,
                  isEnabled: true,
                  isFocusable: true,
                  actions: <AndroidSemanticsAction>[
                    // TODO(gspencergoog): This should really be identical to the first time,
                    // but TalkBack doesn't find it the second time for some reason.
                    AndroidSemanticsAction.accessibilityFocus,
                    AndroidSemanticsAction.click,
                  ],
                ),
                reason: "Popup $item doesn't have the right semantics the second time");
          }
        } finally {
          await driver.tap(find.byValueKey('$popupKeyValue.${popupItems.first}'));
        }
      });

      test('Dropdown Menu has correct Android semantics', () async {
        expect(
          await getSemantics(find.byValueKey(dropdownButtonKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.button,
            isChecked: false,
            isCheckable: false,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(find.byValueKey(dropdownButtonKeyValue));
        try {
          await Future<void>.delayed(const Duration(milliseconds: 1500));

          for (String item in popupItems) {
            // There are two copies of each item, so we want to find the version
            // that is in the overlay, not the one in the dropdown.
            expect(
                await getSemantics(find.descendant(
                  of: find.byType('Scrollable'),
                  matching: find.byValueKey('$dropdownKeyValue.$item'),
                )),
                hasAndroidSemantics(
                  className: AndroidClassName.view,
                  isChecked: false,
                  isCheckable: false,
                  isEnabled: true,
                  isFocusable: true,
                  actions: <AndroidSemanticsAction>[
                    // TODO(gspencergoog): This should really be different for the first item:
                    // It should have clearAccessibilityFocus instead, but for some reason
                    // TalkBack doesn't ask to focus it.
                    AndroidSemanticsAction.accessibilityFocus,
                    AndroidSemanticsAction.click,
                  ],
                ),
                reason: "Dropdown $item doesn't have the right semantics");
          }
          await driver.tap(
            find.descendant(
              of: find.byType('Scrollable'),
              matching: find.byValueKey('$dropdownKeyValue.${popupItems.first}'),
            ),
          );

          // Pop up the dropdown again, to verify that TalkBack gets the right answer
          // more than just the first time.
          await driver.tap(find.byValueKey(dropdownButtonKeyValue));
          await Future<void>.delayed(const Duration(milliseconds: 1500));

          for (String item in popupItems) {
            // There are two copies of each item, so we want to find the version
            // that is in the overlay, not the one in the dropdown.
            expect(
                await getSemantics(find.descendant(
                  of: find.byType('Scrollable'),
                  matching: find.byValueKey('$dropdownKeyValue.$item'),
                )),
                hasAndroidSemantics(
                  className: AndroidClassName.view,
                  isChecked: false,
                  isCheckable: false,
                  isEnabled: true,
                  isFocusable: true,
                  actions: <AndroidSemanticsAction>[
                    // TODO(gspencergoog): This should really be different for the first item:
                    // It should have clearAccessibilityFocus instead, but for some reason
                    // TalkBack doesn't ask to focus it.
                    AndroidSemanticsAction.accessibilityFocus,
                    AndroidSemanticsAction.click,
                  ],
                ),
                reason: "Dropdown $item doesn't have the right semantics the second time.");
          }
        } finally {
          await driver.tap(
            find.descendant(
              of: find.byType('Scrollable'),
              matching: find.byValueKey('$dropdownKeyValue.${popupItems.first}'),
            ),
          );
        }
      });

      test('Modal alert dialog has correct Android semantics', () async {
        expect(
          await getSemantics(find.byValueKey(alertButtonKeyValue)),
          hasAndroidSemantics(
            className: AndroidClassName.button,
            isChecked: false,
            isCheckable: false,
            isEnabled: true,
            isFocusable: true,
            actions: <AndroidSemanticsAction>[
              AndroidSemanticsAction.accessibilityFocus,
              AndroidSemanticsAction.click,
            ],
          ),
        );

        await driver.tap(find.byValueKey(alertButtonKeyValue));
        try {
          await Future<void>.delayed(const Duration(milliseconds: 1500));

          expect(
              await getSemantics(find.byValueKey('$alertKeyValue.OK')),
              hasAndroidSemantics(
                className: AndroidClassName.button,
                isChecked: false,
                isCheckable: false,
                isEnabled: true,
                isFocusable: true,
                actions: <AndroidSemanticsAction>[
                  AndroidSemanticsAction.accessibilityFocus,
                  AndroidSemanticsAction.click,
                ],
              ),
              reason: "Alert OK button doesn't have the right semantics");

          for (String item in <String>['Title', 'Body1', 'Body2']) {
            expect(
                await getSemantics(find.byValueKey('$alertKeyValue.$item')),
                hasAndroidSemantics(
                  className: AndroidClassName.view,
                  isChecked: false,
                  isCheckable: false,
                  isEnabled: true,
                  isFocusable: true,
                  actions: <AndroidSemanticsAction>[
                    if (item == 'Body1') AndroidSemanticsAction.clearAccessibilityFocus,
                    if (item != 'Body1') AndroidSemanticsAction.accessibilityFocus,
                  ],
                ),
                reason: "Alert $item button doesn't have the right semantics");
          }

          await driver.tap(find.byValueKey('$alertKeyValue.OK'));

          // Pop up the alert again, to verify that TalkBack gets the right answer
          // more than just the first time.
          await driver.tap(find.byValueKey(alertButtonKeyValue));
          await Future<void>.delayed(const Duration(milliseconds: 1500));

          expect(
              await getSemantics(find.byValueKey('$alertKeyValue.OK')),
              hasAndroidSemantics(
                className: AndroidClassName.button,
                isChecked: false,
                isCheckable: false,
                isEnabled: true,
                isFocusable: true,
                actions: <AndroidSemanticsAction>[
                  AndroidSemanticsAction.accessibilityFocus,
                  AndroidSemanticsAction.click,
                ],
              ),
              reason: "Alert OK button doesn't have the right semantics");

          for (String item in <String>['Title', 'Body1', 'Body2']) {
            expect(
                await getSemantics(find.byValueKey('$alertKeyValue.$item')),
                hasAndroidSemantics(
                  className: AndroidClassName.view,
                  isChecked: false,
                  isCheckable: false,
                  isEnabled: true,
                  isFocusable: true,
                  actions: <AndroidSemanticsAction>[
                    // TODO(gspencergoog): This should really be identical to the first time,
                    // but TalkBack doesn't find it the second time for some reason.
                    AndroidSemanticsAction.accessibilityFocus,
                  ],
                ),
                reason: "Alert $item button doesn't have the right semantics");
          }
        } finally {
          await driver.tap(find.byValueKey('$alertKeyValue.OK'));
        }
      });

      tearDownAll(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await driver.tap(find.byValueKey('back'));
      });
    });
  });
}
