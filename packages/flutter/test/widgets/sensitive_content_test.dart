// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/sensitive_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sensitive_content_utils.dart';

void main() {
  const ContentSensitivity defaultContentSensitivitySetting = ContentSensitivity.autoSensitive;

  Completer<void> setContentSensitivityCompleter = Completer<void>();

  tearDown(() {
    setContentSensitivityCompleter = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      null,
    );
  });
  testWidgets(
    'while SensitiveContent widget is being registered, SizedBox.shrink is built initially, then child widget is built upon completion',
    (WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            return setContentSensitivityCompleter.future;
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return Future<String>.value(defaultContentSensitivitySetting.name);
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return Future<bool>.value(true);
          } else {
            return null;
          }
        },
      );

      await tester.runAsync(() async {
        final Container childWidget = Container();

        await tester.pumpWidget(
          SensitiveContent(sensitivity: ContentSensitivity.sensitive, child: childWidget),
        );

        expect(find.byWidget(childWidget), findsNothing);
        final SizedBox shrinkBox = tester.firstWidget(find.byType(SizedBox)) as SizedBox;
        expect(shrinkBox.width, 0);
        expect(shrinkBox.height, 0);

        setContentSensitivityCompleter.complete();

        // Delay added to ensure that the SensitiveContent widget registration completes.
        await Future<void>.delayed(const Duration(milliseconds: 100), () async {
          await tester.pump();
        });

        await expectLater(find.byWidget(childWidget), findsOne);
        expect(find.byType(SizedBox), findsNothing);
      });
    },
  );

  testWidgets(
    'when SensitiveContent widget changes sensitivity, SizedBox.shrink is built initially, then child widget is built upon completion',
    (WidgetTester tester) async {
      int setContentSensitivityCall = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            setContentSensitivityCall++;
            // Make second call to update content sensitivity awaits the Future for test.
            if (setContentSensitivityCall == 2 && methodCall.arguments == 'autoSensitive') {
              return setContentSensitivityCompleter.future;
            }
            return Future<void>.value();
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return Future<String>.value(defaultContentSensitivitySetting.name);
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return Future<bool>.value(true);
          } else {
            return null;
          }
        },
      );

      await tester.runAsync(() async {
        const Key scKey = Key('scKey');
        final Container childWidget = Container();

        await tester.pumpWidget(
          ChangeContentSensitivityTester(
            key: scKey,
            initialContentSensitivity: ContentSensitivity.sensitive,
            child: childWidget,
          ),
        );

        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
        scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

        expect(find.byWidget(childWidget), findsNothing);
        final SizedBox shrinkBox = tester.firstWidget(find.byType(SizedBox)) as SizedBox;
        expect(shrinkBox.width, 0);
        expect(shrinkBox.height, 0);

        setContentSensitivityCompleter.complete();
        await tester.pumpAndSettle();

        await expectLater(find.byType(childWidget.runtimeType), findsOne);
        expect(find.byType(SizedBox), findsNothing);

        // Ensure setContentSensitivity was not called more than once upon re-registration.
        expect(setContentSensitivityCall, 2);
      });
    },
  );
}
