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

  group('changing SensitiveContent sensitivityLevel updates sensitive content setting as expected', () {
    // Tests for one SensitiveContent widget changing sensitivity level:
    testWidgets('when one sensitive SensitiveContent widget changes to sensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.sensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.sensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

      // Change content sensitivity to sensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.sensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
    });

    testWidgets('when one sensitive SensitiveContent widget changes to autoSensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.sensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.sensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

      // Change content sensitivity to autoSensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

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

    testWidgets('when one sensitive SensitiveContent widget changes to notSensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.sensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.sensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

      // Change content sensitivity to notSensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

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

    testWidgets('when one autoSensitive SensitiveContent widget changes to sensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.autoSensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.autoSensitive),
      );
      expect(setContentSensitivityArgs.length, 0);

      // Change content sensitivity to sensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.sensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
    });

    testWidgets('when one autoSensitive SensitiveContent widget changes to autoSensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.autoSensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.autoSensitive),
      );
      expect(setContentSensitivityArgs.length, 0);

      // Change content sensitivity to autoSensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.autoSensitive),
      );
      expect(setContentSensitivityArgs.length, 0);
    });

    testWidgets('when one autoSensitive SensitiveContent widget changes to notSensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.autoSensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.autoSensitive),
      );
      expect(setContentSensitivityArgs.length, 0);

      // Change content sensitivity to notSensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.notSensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);
    });

    testWidgets('when one notSensitive SensitiveContent widget changes to sensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.notSensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.notSensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);

      // Change content sensitivity to sensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.sensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[
        ContentSensitivity.notSensitive,
        ContentSensitivity.sensitive,
      ]);
    });

    testWidgets('when one notSensitive SensitiveContent widget changes to autoSensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.notSensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.notSensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);

      // Change content sensitivity to autoSensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.autoSensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[
        ContentSensitivity.notSensitive,
        ContentSensitivity.autoSensitive,
      ]);
    });

    testWidgets('when one notSensitive SensitiveContent widget changes to notSensitive', (
      WidgetTester tester,
    ) async {
      const Key scKey = Key('scKey');
      const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
        key: scKey,
        initialContentSensitivity: ContentSensitivity.notSensitive,
      );

      await tester.pumpWidget(sc);

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.notSensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);

      // Change content sensitivity to autoSensitive.
      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

      await tester.pump();

      expect(
        sensitiveContentHost.currentContentSensitivityLevel,
        equals(ContentSensitivity.notSensitive),
      );
      expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);
    });

    // Test cases with two SensitiveContent widgets, where one changes states:
    testWidgets(
      'when one sensitive SensitiveContent widget changes to autoSensitive with another sensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key sc1Key = Key('sc1Key');
        const ChangeContentSensitivityTester sc1 = ChangeContentSensitivityTester(
          key: sc1Key,
          initialContentSensitivity: ContentSensitivity.sensitive,
        );
        final SensitiveContent sc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, sc2]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change sc1 content sensitivity to autoSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(sc1Key));
        scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when one sensitive SensitiveContent widget changes to notSensitive with another sensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key sc1Key = Key('sc1Key');
        const ChangeContentSensitivityTester sc1 = ChangeContentSensitivityTester(
          key: sc1Key,
          initialContentSensitivity: ContentSensitivity.sensitive,
        );
        final SensitiveContent sc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc1, sc2]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change sc1 content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(sc1Key));
        scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when one sensitive SensitiveContent widget changes to autoSensitive with an autoSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key scKey = Key('scKey');
        const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
          key: scKey,
          initialContentSensitivity: ContentSensitivity.sensitive,
        );
        final SensitiveContent asc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc, asc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change sc content sensitivity to autoSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
        scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

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
      'when one sensitive SensitiveContent widget changes to notSensitive with an autoSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key scKey = Key('scKey');
        const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
          key: scKey,
          initialContentSensitivity: ContentSensitivity.sensitive,
        );
        final SensitiveContent asc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc, asc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change sc content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
        scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

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
      'when one sensitive SensitiveContent widget changes to autoSensitive with a notSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key scKey = Key('sc1Key');
        const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
          key: scKey,
          initialContentSensitivity: ContentSensitivity.sensitive,
        );
        final SensitiveContent nsc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc, nsc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change sc1= content sensitivity to autoSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
        scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

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
      'when one sensitive SensitiveContent widget changes to notSensitive with a notSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key scKey = Key('scKey');
        const ChangeContentSensitivityTester sc = ChangeContentSensitivityTester(
          key: scKey,
          initialContentSensitivity: ContentSensitivity.sensitive,
        );
        final SensitiveContent nsc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[sc, nsc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change sc content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
        scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.notSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.sensitive,
          ContentSensitivity.notSensitive,
        ]);
      },
    );

    testWidgets(
      'when one autoSensitive SensitiveContent widget changes to sensitive with a sensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key ascKey = Key('ascKey');
        const ChangeContentSensitivityTester asc = ChangeContentSensitivityTester(
          key: ascKey,
          initialContentSensitivity: ContentSensitivity.autoSensitive,
        );
        final SensitiveContent sc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc, sc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change asc content sensitivity to sensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(ascKey));
        scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when one autoSensitive SensitiveContent widget changes to notSensitive with a sensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key ascKey = Key('ascKey');
        const ChangeContentSensitivityTester asc = ChangeContentSensitivityTester(
          key: ascKey,
          initialContentSensitivity: ContentSensitivity.autoSensitive,
        );
        final SensitiveContent sc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc, sc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);

        // Change asc content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(ascKey));
        scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when one autoSensitive SensitiveContent widget changes to sensitive with another autoSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key asc1Key = Key('asc1Key');
        const ChangeContentSensitivityTester asc1 = ChangeContentSensitivityTester(
          key: asc1Key,
          initialContentSensitivity: ContentSensitivity.autoSensitive,
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

        // Change asc1 content sensitivity to sensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(asc1Key));
        scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when one autoSensitive SensitiveContent widget changes to notSensitive with another autoSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key asc1Key = Key('asc1Key');
        const ChangeContentSensitivityTester asc1 = ChangeContentSensitivityTester(
          key: asc1Key,
          initialContentSensitivity: ContentSensitivity.autoSensitive,
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

        // Change asc1 content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(asc1Key));
        scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      },
    );

    testWidgets(
      'when one autoSensitive SensitiveContent widget changes to sensitive with a notSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key ascKey = Key('ascKey');
        const ChangeContentSensitivityTester asc = ChangeContentSensitivityTester(
          key: ascKey,
          initialContentSensitivity: ContentSensitivity.autoSensitive,
        );
        final SensitiveContent nsc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc, nsc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);

        // Change asc content sensitivity to sensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(ascKey));
        scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when one autoSensitive SensitiveContent widget changes to notSensitive with a notSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key ascKey = Key('ascKey');
        const ChangeContentSensitivityTester asc = ChangeContentSensitivityTester(
          key: ascKey,
          initialContentSensitivity: ContentSensitivity.autoSensitive,
        );
        final SensitiveContent nsc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[asc, nsc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);

        // Change asc content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(ascKey));
        scState.changeContentSensitivityTo(ContentSensitivity.notSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.notSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);
      },
    );

    testWidgets(
      'when one notSensitive SensitiveContent widget changes to sensitive with a sensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key nscKey = Key('nscKey');
        const ChangeContentSensitivityTester nsc = ChangeContentSensitivityTester(
          key: nscKey,
          initialContentSensitivity: ContentSensitivity.notSensitive,
        );
        final SensitiveContent sc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[nsc, sc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.sensitive,
        ]);

        // Change nsc content sensitivity to sensitive.
        final ChangeContentSensitivityTesterState nscState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(nscKey));
        nscState.changeContentSensitivityTo(ContentSensitivity.sensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.sensitive,
        ]);
      },
    );

    testWidgets(
      'when one notSensitive SensitiveContent widget changes to autoSensitive with a sensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key nscKey = Key('nscKey');
        const ChangeContentSensitivityTester nsc = ChangeContentSensitivityTester(
          key: nscKey,
          initialContentSensitivity: ContentSensitivity.notSensitive,
        );
        final SensitiveContent sc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[nsc, sc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.sensitive,
        ]);

        // Change nsc content sensitivity to autoSensitive.
        final ChangeContentSensitivityTesterState nscState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(nscKey));
        nscState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.sensitive,
        ]);
      },
    );

    testWidgets(
      'when one notSensitive SensitiveContent widget changes to sensitive with an autoSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key nscKey = Key('nscKey');
        const ChangeContentSensitivityTester nsc = ChangeContentSensitivityTester(
          key: nscKey,
          initialContentSensitivity: ContentSensitivity.notSensitive,
        );
        final SensitiveContent asc2 = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[nsc, asc2]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.autoSensitive,
        ]);

        // Change nsc content sensitivity to sensitive.
        final ChangeContentSensitivityTesterState nscState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(nscKey));
        nscState.changeContentSensitivityTo(ContentSensitivity.sensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.autoSensitive,
          ContentSensitivity.sensitive,
        ]);
      },
    );

    testWidgets(
      'when one notSensitive SensitiveContent widget changes to autoSensitive with an autoSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key nscKey = Key('nscKey');
        const ChangeContentSensitivityTester nsc = ChangeContentSensitivityTester(
          key: nscKey,
          initialContentSensitivity: ContentSensitivity.notSensitive,
        );
        final SensitiveContent asc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );

        await tester.pumpWidget(Column(children: <Widget>[nsc, asc]));

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.autoSensitive,
        ]);

        // Change nsc content sensitivity to autoSensitive.
        final ChangeContentSensitivityTesterState nscState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(nscKey));
        nscState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.autoSensitive,
        ]);
      },
    );

    testWidgets(
      'when one notSensitive SensitiveContent widget changes to sensitive with another notSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key nsc1Key = Key('nsc1Key');
        const ChangeContentSensitivityTester nsc1 = ChangeContentSensitivityTester(
          key: nsc1Key,
          initialContentSensitivity: ContentSensitivity.notSensitive,
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
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);

        // Change nsc content sensitivity to sensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(nsc1Key));
        scState.changeContentSensitivityTo(ContentSensitivity.sensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.sensitive,
        ]);
      },
    );

    testWidgets(
      'when one notSensitive SensitiveContent widget changes to autoSensitive with another notSensitive SensitiveContent widget',
      (WidgetTester tester) async {
        const Key nsc1Key = Key('nsc1Key');
        const ChangeContentSensitivityTester nsc1 = ChangeContentSensitivityTester(
          key: nsc1Key,
          initialContentSensitivity: ContentSensitivity.notSensitive,
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
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.notSensitive]);

        // Change nsc1 content sensitivity to notSensitive.
        final ChangeContentSensitivityTesterState scState = tester
            .firstState<ChangeContentSensitivityTesterState>(find.byKey(nsc1Key));
        scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.autoSensitive,
        ]);
      },
    );
  });

  group('SensitiveContent children of SensitiveContent widgets behaves as expected', () {
    testWidgets('when a sensitive SensitiveContent widget has any SensitiveContent children', (
      WidgetTester tester,
    ) async {
      for (final ContentSensitivity contentSensitivity in ContentSensitivity.values) {
        final SensitiveContent scChild = SensitiveContent(
          sensitivityLevel: contentSensitivity,
          child: Container(),
        );
        final SensitiveContent sc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: scChild,
        );

        await tester.pumpWidget(sc);

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      }
    });

    testWidgets(
      'when an autoSensitive SensitiveContent widget has a sensitive SensitiveContent child',
      (WidgetTester tester) async {
        final SensitiveContent ascChild = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent sc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: ascChild,
        );

        await tester.pumpWidget(sc);

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[ContentSensitivity.sensitive]);
      },
    );

    testWidgets(
      'when an autoSensitive SensitiveContent widget has an autoSensitive SensitiveContent child',
      (WidgetTester tester) async {
        final SensitiveContent ascChild = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent asc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: ascChild,
        );

        await tester.pumpWidget(asc);

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      },
    );

    testWidgets(
      'when an autoSensitive SensitiveContent widget has an notSensitive SensitiveContent child',
      (WidgetTester tester) async {
        final SensitiveContent nscChild = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: Container(),
        );
        final SensitiveContent asc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: nscChild,
        );

        await tester.pumpWidget(asc);

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs.length, 0);
      },
    );

    testWidgets(
      'when an notSensitive SensitiveContent widget has a sensitive SensitiveContent child',
      (WidgetTester tester) async {
        final SensitiveContent scChild = SensitiveContent(
          sensitivityLevel: ContentSensitivity.sensitive,
          child: Container(),
        );
        final SensitiveContent nsc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: scChild,
        );

        await tester.pumpWidget(nsc);
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.sensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.sensitive,
        ]);
      },
    );

    testWidgets(
      'when an notSensitive SensitiveContent widget has an autoSensitive SensitiveContent child',
      (WidgetTester tester) async {
        final SensitiveContent ascChild = SensitiveContent(
          sensitivityLevel: ContentSensitivity.autoSensitive,
          child: Container(),
        );
        final SensitiveContent nsc = SensitiveContent(
          sensitivityLevel: ContentSensitivity.notSensitive,
          child: ascChild,
        );

        await tester.pumpWidget(nsc);
        await tester.pump();

        expect(
          sensitiveContentHost.currentContentSensitivityLevel,
          equals(ContentSensitivity.autoSensitive),
        );
        expect(setContentSensitivityArgs, <ContentSensitivity>[
          ContentSensitivity.notSensitive,
          ContentSensitivity.autoSensitive,
        ]);
      },
    );
  });
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

class ChangeContentSensitivityTester extends StatefulWidget {
  const ChangeContentSensitivityTester({super.key, required this.initialContentSensitivity});

  final ContentSensitivity initialContentSensitivity;

  @override
  State<ChangeContentSensitivityTester> createState() => ChangeContentSensitivityTesterState();
}

class ChangeContentSensitivityTesterState extends State<ChangeContentSensitivityTester> {
  late ContentSensitivity _contentSensitivity;

  @override
  void initState() {
    super.initState();
    _contentSensitivity = widget.initialContentSensitivity;
  }

  void changeContentSensitivityTo(ContentSensitivity newContentSensitivity) {
    setState(() {
      _contentSensitivity = newContentSensitivity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SensitiveContent(sensitivityLevel: _contentSensitivity, child: Container());
  }
}
