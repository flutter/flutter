// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Default content sensitivity setting for testing.
  const ContentSensitivity defaultContentSensitivitySetting = ContentSensitivity.autoSensitive;

  // The state of content sensitivity in the app.
  final SensitiveContentHost sensitiveContentHost = SensitiveContentHost.instance;

  // The ContentSenstivity levels that get set by the native platform via calls to
  // `SensitiveContent.setContentSensitivity`.
  List<ContentSensitivity> setContentSensitivityArgs = <ContentSensitivity>[];

  setUp(() {
    // Reset number of method channel calls to `SensitiveContent.setContentSensitivity`.
    setContentSensitivityArgs = <ContentSensitivity>[];

    // Mock calls to the sensitive content method channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
          setContentSensitivityArgs.add(
            ContentSensitivity.getContentSensitivityById(methodCall.arguments as int),
          );
        } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
          return defaultContentSensitivitySetting.id;
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

  testWidgets('one SenstiveContent widget sets content sensitivity for tree as expected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
    );

    expect(
      sensitiveContentHost.currentContentSensitivityLevel,
      equals(ContentSensitivity.sensitive),
    );
    expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
  });

  testWidgets(
    'disposing only SensitiveContent widget in the tree sets content sensitivity back to the default as expected',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        SensitiveContent(sensitivityLevel: ContentSensitivity.sensitive, child: Container()),
      );
      await tester.pumpWidget(Container());

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(defaultContentSensitivitySetting),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[
        ContentSensitivity.sensitive,
        defaultContentSensitivitySetting,
      ]);
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
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('when it gets disposed with another sensitive widget', (
        WidgetTester tester,
      ) async {
        const Key sc1Key = Key('sc1');
        final DisposeTester sc1 = DisposeTester(
          child: SensitiveContent(
            key: sc1Key,
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          ),
        );
        final SensitiveContent sc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, sc2]));

        final DisposeTesterState sc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(sc1Key),
        );
        sc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('with two other sensitive widgets', (WidgetTester tester) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent sc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent sc3 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, sc2, sc3]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('with two other sensitive widgets and one gets disposed', (
        WidgetTester tester,
      ) async {
        const Key sc1Key = Key('sc1');
        final DisposeTester sc1 = DisposeTester(
          child: SensitiveContent(
            key: sc1Key,
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          ),
        );
        final SensitiveContent sc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent sc3 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, sc2, sc3]));

        final DisposeTesterState sc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(sc1Key),
        );
        sc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      // Tests with auto sensitive widget(s):
      testWidgets('with one auto sensitive widget', (WidgetTester tester) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, asc1]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('when it gets disposed with one auto sensitive widget', (
        WidgetTester tester,
      ) async {
        const Key sc1Key = Key('sc1');
        final DisposeTester sc1 = DisposeTester(
          child: SensitiveContent(
            key: sc1Key,
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          ),
        );
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, asc1]));

        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        final DisposeTesterState sc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(sc1Key),
        );
        sc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );

        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.sensitive,
          ContentSensitivity.autoSensitive,
        ]);
      });

      testWidgets('with one auto sensitive widget that gets disposed', (WidgetTester tester) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        const Key asc1Key = Key('asc1');
        final DisposeTester asc1 = DisposeTester(
          child: SensitiveContent(
            key: asc1Key,
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          ),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, asc1]));

        final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(asc1Key),
        );
        asc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );

        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('with two auto sensitive widgets and one gets disposed', (
        WidgetTester tester,
      ) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        const Key asc1Key = Key('asc1');
        final DisposeTester asc1 = DisposeTester(
          child: SensitiveContent(
            key: asc1Key,
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          ),
        );
        final SensitiveContent asc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, asc2]));

        final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(asc1Key),
        );
        asc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );

        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      // Tests with not sensitive widget(s):
      testWidgets('with one not sensitive widget', (WidgetTester tester) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, nsc1]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('when it gets disposed with one not sensitive widget', (
        WidgetTester tester,
      ) async {
        const Key sc1Key = Key('sc1');
        final DisposeTester sc1 = DisposeTester(
          child: SensitiveContent(
            key: sc1Key,
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          ),
        );
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, nsc1]));

        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        final DisposeTesterState sc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(sc1Key),
        );
        sc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.notSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.sensitive,
          ContentSensitivity.notSensitive,
        ]);
      });

      testWidgets('with one not sensitive widget that gets disposed', (WidgetTester tester) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        const Key nsc1Key = Key('nsc1');
        final DisposeTester nsc1 = DisposeTester(
          child: SensitiveContent(
            key: nsc1Key,
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          ),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, nsc1]));

        final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(nsc1Key),
        );
        nsc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets('with two not sensitive widgets and one gets disposed', (
        WidgetTester tester,
      ) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        const Key nsc1Key = Key('nsc1');
        final DisposeTester asc1 = DisposeTester(
          child: SensitiveContent(
            key: nsc1Key,
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          ),
        );
        final SensitiveContent nsc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, nsc2]));

        final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(nsc1Key),
        );
        nsc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      // Tests with an auto sensitive and a not sensitive widget(s):
      testWidgets('with one not sensitive widget and one auto sensitive widget', (
        WidgetTester tester,
      ) async {
        final SensitiveContent sc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, nsc1]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      });

      testWidgets(
        'when it gets disposed with one not sensitive widget and one auto sensitive widget',
        (WidgetTester tester) async {
          const Key sc1Key = Key('sc1');
          final DisposeTester sc1 = DisposeTester(
            child: SensitiveContent(
              key: sc1Key,
              sensitivityLevel: ContentSensitivity.sensitive,
              child: Container(),
            ),
          );
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, nsc1]));

          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

          final DisposeTesterState sc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(sc1Key),
          );
          sc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.autoSensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[
            ContentSensitivity.sensitive,
            ContentSensitivity.autoSensitive,
          ]);
        },
      );

      testWidgets(
        'with one not sensitive widget and one auto sensitive widget and auto sensitive widget gets disposed',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          const Key asc1Key = Key('asc1');
          final DisposeTester asc1 = DisposeTester(
            child: SensitiveContent(
              key: asc1Key,
              sensitivityLevel: ContentSensitivity.autoSensitive,
              child: Container(),
            ),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, nsc1]));

          final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(asc1Key),
          );
          asc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      testWidgets(
        'with one not sensitive widget and one auto sensitive widget and not sensitive widget gets disposed',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          const Key nsc1Key = Key('nsc1');
          final DisposeTester nsc1 = DisposeTester(
            child: SensitiveContent(
              key: nsc1Key,
              sensitivityLevel: ContentSensitivity.notSensitive,
              child: Container(),
            ),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, nsc1]));

          final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(nsc1Key),
          );
          nsc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      // Tests with another sensitive widget, an auto sensitive, and a not sensitive widget:
      testWidgets(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent sc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, sc2, asc1, nsc1]));

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      testWidgets(
        'when it gets disposed with another sensitive widget, one not sensitive widget, and one auto sensitive widget',
        (WidgetTester tester) async {
          const Key sc1Key = Key('sc1');
          final DisposeTester sc1 = DisposeTester(
            child: SensitiveContent(
              key: sc1Key,
              sensitivityLevel: ContentSensitivity.sensitive,
              child: Container(),
            ),
          );
          final SensitiveContent sc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, sc2, asc1, nsc1]));

          final DisposeTesterState sc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(sc1Key),
          );
          sc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      testWidgets(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget and the auto sensitive widget is disposed',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent sc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          const Key asc1Key = Key('asc1');
          final DisposeTester asc1 = DisposeTester(
            child: SensitiveContent(
              key: asc1Key,
              sensitivityLevel: ContentSensitivity.autoSensitive,
              child: Container(),
            ),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, sc2, asc1, nsc1]));

          final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(asc1Key),
          );
          asc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      testWidgets(
        'with another sensitive widget, one not sensitive widget, and one auto sensitive widget and the not sensitive widget is disposed',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent sc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          const Key nsc1Key = Key('nsc1');
          final DisposeTester nsc1 = DisposeTester(
            child: SensitiveContent(
              key: nsc1Key,
              sensitivityLevel: ContentSensitivity.notSensitive,
              child: Container(),
            ),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, sc2, asc1, nsc1]));

          final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(nsc1Key),
          );
          nsc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      // Tests with mutliple non-sensitive (auto sensitive, not sensitive) widgets:
      testWidgets(
        'with two auto sensitive widgets and one not sensitive widget and one auto sensitive widget gets disposed',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          const Key asc1Key = Key('asc1');
          final DisposeTester asc1 = DisposeTester(
            child: SensitiveContent(
              key: asc1Key,
              sensitivityLevel: ContentSensitivity.autoSensitive,
              child: Container(),
            ),
          );

          final SensitiveContent asc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, asc2, nsc1]));

          final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(asc1Key),
          );
          asc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );

      testWidgets(
        'with one auto sensitive widgets and two not sensitive widgets and one not sensitive widget gets disposed',
        (WidgetTester tester) async {
          final SensitiveContent sc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.sensitive,
            child: Container(),
          );
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          const Key nsc1Key = Key('nsc1');
          final DisposeTester nsc1 = DisposeTester(
            child: SensitiveContent(
              key: nsc1Key,
              sensitivityLevel: ContentSensitivity.notSensitive,
              child: Container(),
            ),
          );
          final SensitiveContent nsc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[sc1, asc1, nsc1, nsc2]));

          final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(nsc1Key),
          );
          nsc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.sensitive),
          );
          expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
        },
      );
    },
  );

  group(
    'one auto-sensitive (with no sensitive SensitiveContent widgets in the tree) determines content sensitivity for tree as expected',
    () {
      // Tests with other auto sensitive widget(s):
      testWidgets('with another auto sensitive widget', (WidgetTester tester) async {
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent asc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, asc2]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      });

      testWidgets('when it gets disposed with another auto sensitive widget', (
        WidgetTester tester,
      ) async {
        const Key asc1Key = Key('asc1');
        final DisposeTester asc1 = DisposeTester(
          child: SensitiveContent(
            key: asc1Key,
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          ),
        );
        final SensitiveContent asc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, asc2]));

        final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(asc1Key),
        );
        asc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      });

      // Tests with not sensitive widget(s):
      testWidgets('with one not sensitive widget', (WidgetTester tester) async {
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, nsc1]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      });

      testWidgets('when it gets disposed with one not sensitive widget', (
        WidgetTester tester,
      ) async {
        const Key asc1Key = Key('asc1');
        final DisposeTester asc1 = DisposeTester(
          child: SensitiveContent(
            key: asc1Key,
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          ),
        );
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, nsc1]));

        final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(asc1Key),
        );
        asc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.notSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);
      });

      testWidgets('with one not sensitive widget that gets disposed', (WidgetTester tester) async {
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        const Key nsc1Key = Key('nsc1');
        final DisposeTester nsc1 = DisposeTester(
          child: SensitiveContent(
            key: nsc1Key,
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          ),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, nsc1]));

        final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(nsc1Key),
        );
        nsc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      });

      testWidgets('with two not sensitive widgets and one gets disposed', (
        WidgetTester tester,
      ) async {
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        const Key nsc1Key = Key('nsc1');
        final DisposeTester nsc1 = DisposeTester(
          child: SensitiveContent(
            key: nsc1Key,
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          ),
        );
        final SensitiveContent nsc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, nsc1, nsc2]));

        final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(nsc1Key),
        );
        nsc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      });

      // Tests with another auto sensitive widget and a not sensitive widget(s):
      testWidgets('with another auto sensitive widget and one not sensitive widget', (
        WidgetTester tester,
      ) async {
        final SensitiveContent asc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent asc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc1, asc2, nsc1]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      });

      testWidgets(
        'when it gets disposed with another auto sensitive widget and one not sensitive widget',
        (WidgetTester tester) async {
          const Key asc1Key = Key('asc1');
          final DisposeTester asc1 = DisposeTester(
            child: SensitiveContent(
              key: asc1Key,
              sensitivityLevel: ContentSensitivity.autoSensitive,
              child: Container(),
            ),
          );
          final SensitiveContent asc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          final SensitiveContent nsc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          );

          await tester.pumpWidget(Column(children: <Widget>[asc1, asc2, nsc1]));

          final DisposeTesterState asc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(asc1Key),
          );
          asc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.autoSensitive),
          );
          expect(setContentSensitivityArgs.length, 0);
        },
      );

      testWidgets(
        'with another auto sensitive widget and one not sensitive widget and the not sensitive widget gets disposed',
        (WidgetTester tester) async {
          final SensitiveContent asc1 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          final SensitiveContent asc2 = SensitiveContent(
            sensitivityLevel: ContentSensitivity.autoSensitive,
            child: Container(),
          );
          const Key nsc1Key = Key('nsc1');
          final DisposeTester nsc1 = DisposeTester(
            child: SensitiveContent(
              key: nsc1Key,
              sensitivityLevel: ContentSensitivity.notSensitive,
              child: Container(),
            ),
          );

          await tester.pumpWidget(Column(children: <Widget>[asc1, asc2, nsc1]));

          final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
            find.byKey(nsc1Key),
          );
          nsc1DiposeTesterState.disposeWidget();
          await tester.pump();

          expect(
            sensitiveContentHost.currentContentSensitivityLevel,
            equals(ContentSensitivity.autoSensitive),
          );
          expect(setContentSensitivityArgs.length, 0);
        },
      );
    },
  );

  group(
    'one not sensitive (with no sensitive or auto sensitive SensitiveContent widgets in the tree) SensitiveContent widget in the tree determines content sensitivity for tree as expected',
    () {
      testWidgets('with another not sensitive widget', (WidgetTester tester) async {
        final SensitiveContent nsc1 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );
        final SensitiveContent nsc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[nsc1, nsc2]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.notSensitive),
        );
        expect(setContentSensitivityArgs.length, 1);
      });

      testWidgets('when it gets disposed with one not sensitive widget', (
        WidgetTester tester,
      ) async {
        const Key nsc1Key = Key('nsc1');
        final DisposeTester nsc1 = DisposeTester(
          child: SensitiveContent(
            key: nsc1Key,
            sensitivityLevel: ContentSensitivity.notSensitive,
            child: Container(),
          ),
        );
        final SensitiveContent nsc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[nsc1, nsc2]));

        final DisposeTesterState nsc1DiposeTesterState = tester.firstState<DisposeTesterState>(
          find.byKey(nsc1Key),
        );
        nsc1DiposeTesterState.disposeWidget();
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.notSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);
      });
    },
  );
}

class DisposeTester extends StatefulWidget {
  DisposeTester({required this.child}) : super(key: child.key);

  final Widget child;

  @override
  State<DisposeTester> createState() => DisposeTesterState();
}

class DisposeTesterState extends State<DisposeTester> {
  bool _widgetDisposed = false;

  void disposeWidget() {
    setState(() {
      _widgetDisposed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _widgetDisposed ? Container() : widget.child;
  }
}
