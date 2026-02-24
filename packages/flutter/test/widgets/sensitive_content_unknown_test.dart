// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final SensitiveContentHost sensitiveContentHost = SensitiveContentHost.instance;
  testWidgets(
    'when SensitiveContentService.getContentSensitivity returns ContentSensitivity.unknown, FlutterError is thrown and the fallback ContentSensitivity is notSensitive',
    (WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            // Return the enum index for ContentSensitivity._unknown.
            return 3;
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return true;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        SensitiveContent(sensitivity: ContentSensitivity.notSensitive, child: Container()),
      );
      expect(tester.takeException(), isA<FlutterError>());

      expect(
        sensitiveContentHost.calculatedContentSensitivity,
        equals(ContentSensitivity.notSensitive),
      );
    },
  );
}
