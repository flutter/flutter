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
    });

    test('test hasAndroidSemantics', () async {
      await driver.setSemantics(true);

      /// Retrieve a text widget.
      expect(await getSemantics(find.text('California')), hasAndroidSemantics(
        text: 'California',
        className: AndroidClassName.view,
        actions: <AndroidSemanticsAction>[
          AndroidSemanticsAction.accessibilityFocus,
        ],
      ));

      /// Retrieve the [CheckBox] widget.
      final AndroidSemanticsNode node = await getSemantics(find.byValueKey('California'));
      expect(node, hasAndroidSemantics(
        className: AndroidClassName.checkBox,
        isCheckable: true,
        isChecked: true,
        isEnabled: true,
        isLongClickable: false,
        isFocusable: true,
        size: const Size(40.0, 40.0),
        actions: <AndroidSemanticsAction>[
          AndroidSemanticsAction.click,
          AndroidSemanticsAction.accessibilityFocus,
        ],
      ));
    });

    tearDownAll(() async {
      driver?.close();
    });
  });
}
