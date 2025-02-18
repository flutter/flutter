// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Default content sensitivity setting for testing.
  final int defaultContentSensitivitySettingId = ContentSensitivity.autoSensitive.id;
  final ContentSensitivity defaultContentSensitivitySetting =
      ContentSensitivity.getContentSensitivityById(defaultContentSensitivitySettingId);

  // The state of content sensitivity in the app.
  final SensitiveContentSetting sensitiveContentSetting = SensitiveContentSetting.instance;

  setUp(() {
    // Mock calls to the sensitive content method channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
          expect(methodCall.arguments, isA<int>());
        } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
          // print('CAMILLE: getContentSensitivity called');
          // print('CAMILLE: returning default setting ID: $defaultContentSensitivitySettingId');
          return defaultContentSensitivitySettingId;
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

  testWidgets('one SenstiveContent widget sets content sensitivity for tree as expected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
    );

    expect(
      sensitiveContentSetting.getContentSenstivityState()!.currentContentSensitivitySetting,
      equals(ContentSensitivity.sensitive),
    );
    expect(sensitiveContentSetting.getContentSenstivityState()!.sensitiveWidgetCount, equals(1));
  });

  testWidgets(
    'disposing only SensitiveContent widget in the tree sets content sensitivity back to the default as expected',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
      );
      expect(
        sensitiveContentSetting.getContentSenstivityState()!.currentContentSensitivitySetting,
        equals(ContentSensitivity.sensitive),
      );

      await tester.pumpWidget(Container());
      expect(
        sensitiveContentSetting.getContentSenstivityState()!.currentContentSensitivitySetting,
        equals(defaultContentSensitivitySetting),
      );
      expect(sensitiveContentSetting.getContentSenstivityState()!.sensitiveWidgetCount, equals(0));
    },
  );

  group(
    'one sensitive SensitiveContent widget in the tree determines content sensitivity for tree as expected',
    () {
      // Tests with other sensitive widget(s):
      testWidgets('with another sensitive widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          Column(
            children: <Widget>[
              SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
              SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
            ],
          ),
        );

        expect(
          sensitiveContentSetting.getContentSenstivityState()!.currentContentSensitivitySetting,
          equals(ContentSensitivity.sensitive),
        );
        expect(
          sensitiveContentSetting.getContentSenstivityState()!.sensitiveWidgetCount,
          equals(2),
        );
      });

      testWidgets('when it gets disposed with another sensitive widget', (
        WidgetTester tester,
      ) async {
        final Widget sc = SensitiveContent(
          key: Key('hi'),
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final Widget sc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc, sc2]));

        SensitiveContentState state = tester.firstState<SensitiveContentState>(
          find.byKey(Key('hi')),
        );
        print(state);
        state.dispose();
        tester.pumpAndSettle();
        print('heeeyyyyyyyyyyyy!');
        addTearDown(() {
          print('>>>>>>>>>>>>>> camille: Test finished!');
        });
        tester.pumpWidget(Container());
        // debugDumpApp();

        // todo: camille figure out dilemma, probably want to create wrapper class for testing; go with wrapper method (mon)

        // await tester.pumpWidget(Column(children: [sc]));
      });

      testWidgets('with two other sensitive widgets', (WidgetTester tester) async {});

      testWidgets(
        'with two other sensitive widgets and one gets disposed',
        (WidgetTester tester) async {},
      );

      // Tests with auto sensitive widget(s):
      testWidgets('with one auto sensitive widget', (WidgetTester tester) async {});

      testWidgets(
        'when it gets disposed with one auto sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with one auto sensitive widget that gets disposed',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with two auto sensitive widgets and one gets disposed',
        (WidgetTester tester) async {},
      );

      // Tests with not sensitive widget(s):
      testWidgets('with one not sensitive widget', (WidgetTester tester) async {});

      testWidgets(
        'when it gets disposed with one not sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with one not sensitive widget that gets disposed',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with two not sensitive widgets and one gets disposed',
        (WidgetTester tester) async {},
      );

      // Tests with an auto sensitive and a not sensitive widget(s):
      testWidgets(
        'with one not sensitive widget and one auto sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'when it gets disposed with one not sensitive widget and one auto sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with one not sensitive widget and one auto sensitive widget and auto sensitive widget gets disposed',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with one not sensitive widget and one auto sensitive widget and not sensitive widget gets disposed',
        (WidgetTester tester) async {},
      );

      // Tests with another sensitive widget, an auto sensitive, and a not sensitive widget:
      testWidgets(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'when it gets disposed with another sensitive widget, one not sensitive widget, and one auto sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget and the auto sensitive widget is disposed',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget and the not sensitive widget is disposed',
        (WidgetTester tester) async {},
      );

      // Tests with mutliple non-sensitive (auto sensitive, not sensitive) widgets:
      testWidgets(
        'with two auto sensitive widgets and one not sensitive widget and one auto sensitive widget gets disposed',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with one auto sensitive widgets and two not sensitive widgets and one not sensitive widget gets disposed',
        (WidgetTester tester) async {},
      );
    },
  );

  group(
    'one auto-sensitive (with no sensitive SensitiveContent widgets in the tree) determines content sensitivity for tree as expected',
    () {
      // Tests with other auto sensitive widget(s):
      testWidgets('with another auto sensitive widget', (WidgetTester tester) async {});

      testWidgets(
        'when it gets disposed with another auto sensitive widget',
        (WidgetTester tester) async {},
      );

      // Tests with not sensitive widget(s):
      testWidgets('with one not sensitive widget', (WidgetTester tester) async {});

      testWidgets(
        'when it gets disposed with one not sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with one not sensitive widget that gets disposed',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with two not sensitive widgets and one gets disposed',
        (WidgetTester tester) async {},
      );

      // Tests with another auto sensitive widget and a not sensitive widget(s):
      testWidgets(
        'with another auto sensitive widget and one not sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'when it gets disposed with another auto sensitive widget and one not sensitive widget',
        (WidgetTester tester) async {},
      );

      testWidgets(
        'with another auto sensitive widget and one not sensitive widget and the not sensitive widget gets disposed',
        (WidgetTester tester) async {},
      );
    },
  );

  group(
    'one not sensitive (with no sensitive or auto sensitive SensitiveContent widgets in the tree) SensitiveContent widget in the tree determines content sensitivity for tree as expected',
    () {
      testWidgets('with another not sensitive widget', (WidgetTester tester) async {});

      testWidgets(
        'when it gets disposed with one not sensitive widget',
        (WidgetTester tester) async {},
      );
    },
  );
}
