// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Default contetn sensitivity setting for testing.
  const ContentSensitivity defaultContentSensitivitySetting = ContentSensitivity.autoSensitive;

  setUp(() async {
    // Mock calls to the sensitive content method channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
          expect(methodCall.arguments, isA<int>());
        } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
          return defaultContentSensitivitySetting;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      null,
    );
  });

  test('one SenstiveContent widget sets content sensitivity for tree as expected', () {});

  test(
      'disposing only SensitiveContent widget in the tree sets content sensitivity back to the default as expected',
      () {});

  group(
      'one sensitive SensitiveContent widget in the tree determines content sensitivity for tree as expected',
      () {
    // Tests with other sensitive widget(s):
    test('with another sensitive widget', () {});

    test('when it gets disposed with another sensitive widget', () {});

    test('with two other sensitive widgets', () {});

    test('with two other sensitive widgets and one gets disposed', () {});

    // Tests with auto sensitive widget(s):
    test('with one auto sensitive widget', () {});

    test('when it gets disposed with one auto sensitive widget', () {});

    test('with one auto sensitive widget that gets disposed', () {});

    test('with two auto sensitive widgets and one gets disposed', () {});

    // Tests with not sensitive widget(s):
    test('with one not sensitive widget', () {});

    test('when it gets disposed with one not sensitive widget', () {});

    test('with one not sensitive widget that gets disposed', () {});

    test('with two not sensitive widgets and one gets disposed', () {});

    // Tests with an auto sensitive and a not sensitive widget(s):
    test('with one not sensitive widget and one auto sensitive widget', () {});

    test(
        'when it gets disposed with one not sensitive widget and one auto sensitive widget', () {});

    test(
        'with one not sensitive widget and one auto sensitive widget and auto sensitive widget gets disposed',
        () {});

    test(
        'with one not sensitive widget and one auto sensitive widget and not sensitive widget gets disposed',
        () {});

    // Tests with another sensitive widget, an auto sensitive, and a not sensitive widget:
    test('with another sensitive widget, one not sensitive widget, and one auto sensitive widget',
        () {});

    test(
        'when it gets disposed with another sensitive widget, one not sensitive widget, and one auto sensitive widget',
        () {});

    test(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget and the auto sensitive widget is disposed',
        () {});

    test(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget and the not sensitive widget is disposed',
        () {});

    // Tests with mutliple non-sensitive (auto sensitive, not sensitive) widgets:
    test(
        'with two auto sensitive widgets and one not sensitive widget and one auto sensitive widget gets disposed',
        () {});

    test(
        'with one auto sensitive widgets and two not sensitive widgets and one not sensitive widget gets disposed',
        () {});
  });

  group(
      'one auto-sensitive (with no sensitive SensitiveContent widgets in the tree) determines content sensitivity for tree as expected',
      () {
    // Tests with other auto sensitive widget(s):
    test('with another auto sensitive widget', () {});

    test('when it gets disposed with another auto sensitive widget', () {});

    // Tests with not sensitive widget(s):
    test('with one not sensitive widget', () {});

    test('when it gets disposed with one not sensitive widget', () {});

    test('with one not sensitive widget that gets disposed', () {});

    test('with two not sensitive widgets and one gets disposed', () {});

    // Tests with another auto sensitive widget and a not sensitive widget(s):
    test('with another auto sensitive widget and one not sensitive widget', () {});

    test('when it gets disposed with another auto sensitive widget and one not sensitive widget',
        () {});

    test(
        'with another auto sensitive widget and one not sensitive widget and the not sensitive widget gets disposed',
        () {});
  });

  group(
      'one not sensitive (with no sensitive or auto sensitive SensitiveContent widgets in the tree) SensitiveContent widget in the tree determines content sensitivity for tree as expected',
      () {
    test('with another not sensitive widget', () {});

    test('when it gets disposed with one not sensitive widget', () {});
  });
}
