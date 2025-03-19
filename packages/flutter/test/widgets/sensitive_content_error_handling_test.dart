// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/sensitive_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sensitive_content_utils.dart';

void main() {
  // The state of content sensitivity in the app.
  final SensitiveContentHost sensitiveContentHost = SensitiveContentHost.instance;

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      null,
    );
  });

  // testWidgets(
  //   'when SensitiveContentService.setContentSensitivity fails, SensitiveContentHost.register does not update calculatedContentSensitivity',
  //   (WidgetTester tester) async {
  //     int setContentSensitivityCall = 0;
  //     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
  //       SystemChannels.sensitiveContent,
  //       (MethodCall methodCall) async {
  //         if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
  //           setContentSensitivityCall += 1;
  //           if (setContentSensitivityCall == 1) {
  //             // In the first call to set content sensitivity, throw exception to test
  //             // SensitiveContentHost.register behavior.
  //             throw Exception('test exception');
  //           }
  //         } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
  //           // The enum name for ContentSensitivity.autoSensitive. This will be the
  //           // initial content sensitivity setting that we expect to persist when
  //           // the call to set sensitive content sensitivity fails.
  //           return 'autoSensitive';
  //         } else if (methodCall.method == 'SensitiveContent.isSupported') {
  //           return true;
  //         }
  //         return null;
  //       },
  //     );

  //     await tester.pumpWidget(
  //       SensitiveContent(sensitivity: ContentSensitivity.sensitive, child: Container()),
  //     );

  //     expect(tester.takeException(), isA<FlutterError>());
  //     expect(
  //       sensitiveContentHost.calculatedContentSensitivity,
  //       equals(ContentSensitivity.autoSensitive),
  //     );
  //   },
  // );

  // testWidgets(
  //   'when SensitiveContentService.setContentSensitivity fails, SensitiveContentHost.unregister does not update calculatedContentSensitivity when no SensitiveContent widgets are left in the tree',
  //   (WidgetTester tester) async {
  //     int setContentSensitivityCall = 0;
  //     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
  //       SystemChannels.sensitiveContent,
  //       (MethodCall methodCall) async {
  //         if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
  //           setContentSensitivityCall += 1;
  //           if (setContentSensitivityCall == 2) {
  //             // In the second call to set content sensitivity, throw exception to test
  //             // SensitiveContentHost.unregister behavior.
  //             throw Exception('test exception');
  //           }
  //         } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
  //           // The enum name for ContentSensitivity.autoSensitive. This will be the
  //           // content sensitivity setting before the sensitive SensitiveContent
  //           // widget is built.
  //           return 'autoSensitive';
  //         } else if (methodCall.method == 'SensitiveContent.isSupported') {
  //           return true;
  //         }
  //         return null;
  //       },
  //     );

  //     await tester.pumpWidget(
  //       SensitiveContent(sensitivity: ContentSensitivity.sensitive, child: Container()),
  //     );
  //     await tester.pumpWidget(Container());

  //     expect(tester.takeException(), isA<FlutterError>());
  //     expect(
  //       sensitiveContentHost.calculatedContentSensitivity,
  //       equals(ContentSensitivity.sensitive),
  //     );
  //   },
  // );

  testWidgets(
    'when SensitiveContentService.setContentSensitivity fails, SensitiveContentHost.unregister does not update calculatedContentSensitivity when there are SensitiveContent widgets left in the tree',
    (WidgetTester tester) async {
      // int setContentSensitivityCall = 0;
      const Key scKey = Key('sc');
      final DisposeTester sc = DisposeTester(
        child: SensitiveContent(
          key: scKey,
          sensitivity: ContentSensitivity.sensitive,
          child: Container(),
        ),
      );
      final SensitiveContent asc = SensitiveContent(
        sensitivity: ContentSensitivity.autoSensitive,
        child: Container(),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            // print('hello?@?!?!?!?!');
            // setContentSensitivityCall += 1;
            // // print('setContent called ${methodCall.arguments}, $setContentSensitivityCall');
            // if (setContentSensitivityCall == 3) {
            //   print('throwing exception');
            //   // In the second call to set content sensitivity, throw exception to test
            //   // SensitiveContentHost.unregister behavior.
            //   throw Exception('test exception');
            // }
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            // The enum name for ContentSensitivity.autoSensitive. This will be the
            // content sensitivity setting before the sensitive SensitiveContent
            // widget is built.
            return 'autoSensitive';
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return true;
          }
          return null;
        },
      );

      await tester.pumpWidget(Column(children: <Widget>[sc, asc]));

      final DisposeTesterState scDiposeTesterState = tester.firstState<DisposeTesterState>(
        find.byKey(scKey),
      );
      scDiposeTesterState.disposeWidget();
      await tester.pump();

      expect(tester.takeException(), isA<FlutterError>());
      expect(
        sensitiveContentHost.calculatedContentSensitivity,
        equals(ContentSensitivity.sensitive),
      );
    },
  );
}
