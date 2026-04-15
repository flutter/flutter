// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/sensitive_content/sensitive_content.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ContentSensitivity defaultContentSensitivitySetting =
      ContentSensitivity.autoSensitive;
  late List<ContentSensitivity> setContentSensitivityArgs;

  setUp(() {
    setContentSensitivityArgs = <ContentSensitivity>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.sensitiveContent, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            setContentSensitivityArgs.add(
              ContentSensitivity.values.firstWhere(
                (ContentSensitivity sensitivity) =>
                    sensitivity.index == methodCall.arguments as int,
              ),
            );
          } else if (methodCall.method ==
              'SensitiveContent.getContentSensitivity') {
            return defaultContentSensitivitySetting.index;
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.sensitiveContent, null);
  });

  testWidgets(
    'Changing the screen sensitivity updates the sensitive content channel',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.SensitiveContentApp());
      await tester.pumpAndSettle();

      expect(find.byType(SensitiveContent), findsOneWidget);
      expect(find.text('Checking Account'), findsOneWidget);
      expect(find.text('One-time passcode: 246810'), findsOneWidget);
      expect(
        find.text('SensitiveContentService.isSupported()'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Supported on this device: Yes'),
        findsOneWidget,
      );
      expect(find.text('Selected sensitivity: autoSensitive'), findsOneWidget);
      expect(setContentSensitivityArgs, isEmpty);

      await tester.tap(find.text('Sensitive'));
      await tester.pumpAndSettle();

      SensitiveContent sensitiveContent = tester.widget(
        find.byType(SensitiveContent),
      );
      expect(sensitiveContent.sensitivity, ContentSensitivity.sensitive);
      expect(find.text('Selected sensitivity: sensitive'), findsOneWidget);
      expect(setContentSensitivityArgs, <ContentSensitivity>[
        ContentSensitivity.sensitive,
      ]);

      await tester.tap(find.text('Not sensitive'));
      await tester.pumpAndSettle();

      sensitiveContent = tester.widget(find.byType(SensitiveContent));
      expect(sensitiveContent.sensitivity, ContentSensitivity.notSensitive);
      expect(find.text('Selected sensitivity: notSensitive'), findsOneWidget);
      expect(setContentSensitivityArgs, <ContentSensitivity>[
        ContentSensitivity.sensitive,
        ContentSensitivity.notSensitive,
      ]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Account details widget is scrollable when vertical space is constrained',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800.0, 450.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const example.SensitiveContentApp());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0.0, -120.0),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
