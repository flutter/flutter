// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/sensitive_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The state of content sensitivity in the app.
  final SensitiveContentHost sensitiveContentHost = SensitiveContentHost.instance;

  setUp(() {
    // Mock calls to the sensitive content method channel with calls `getContentSensitivity` returning
    // the unknown value.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
          // The enum name for ContentSensitivity._unknown.
          return '_unknown';
        } else if (methodCall.method == 'SensitiveContent.isSupported') {
          return true;
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

  testWidgets(
    'when SensitiveContentService.getContentSensitivity returns ContentSensitivity.unknown, the fallback ContentSensitivity is notSensitive',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
      );
      await tester.pumpWidget(Container());

      expect(
        sensitiveContentHost.calculatedContentSensitivityLevel,
        equals(ContentSensitivity.notSensitive),
      );
    },
  );
}
