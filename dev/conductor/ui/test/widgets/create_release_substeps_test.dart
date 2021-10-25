// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'create_release_substeps_test.mocks.dart';

/// A fake class to be mocked in order to test if nextStep is being called.
class FakeNextStep {
  void nextStep() {}
}

@GenerateMocks(<Type>[StartContext, FakeNextStep])
void main() {
  const String candidateBranch = 'flutter-1.2-candidate.3';
  const String releaseChannel = 'dev';
  const String frameworkMirror = 'git@github.com:test/flutter.git';
  const String engineMirror = 'git@github.com:test/engine.git';
  const String engineCherrypick = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0,94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
  const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
  const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
  const String increment = 'y';

  group('Capture and validate all parameters of a release initialization', () {
    testWidgets('Widget should capture all parameters correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.enterText(find.byKey(const Key('Candidate Branch')), candidateBranch);

      final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
      final CreateReleaseSubstepsState createReleaseSubstepsState =
          createReleaseSubsteps.state as CreateReleaseSubstepsState;

      /// Tests the Release Channel dropdown menu.
      await tester.tap(find.byKey(const Key('Release Channel')));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData['Release Channel'], equals(null));
      await tester.tap(find.text(releaseChannel).last);
      await tester.pumpAndSettle(); // finish the menu animation

      await tester.enterText(find.byKey(const Key('Framework Mirror')), frameworkMirror);
      await tester.enterText(find.byKey(const Key('Engine Mirror')), engineMirror);
      await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')), engineCherrypick);
      await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')), frameworkCherrypick);
      await tester.enterText(find.byKey(const Key('Dart Revision (if necessary)')), dartRevision);

      /// Tests the Increment dropdown menu.
      await tester.tap(find.byKey(const Key('Increment')));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData['Increment'], equals(null));
      await tester.tap(find.text(increment).last);
      await tester.pumpAndSettle(); // finish the menu animation

      expect(
        createReleaseSubstepsState.releaseData,
        equals(
          <String, String>{
            'Candidate Branch': candidateBranch,
            'Release Channel': releaseChannel,
            'Framework Mirror': frameworkMirror,
            'Engine Mirror': engineMirror,
            'Engine Cherrypicks (if necessary)': engineCherrypick,
            'Framework Cherrypicks (if necessary)': frameworkCherrypick,
            'Dart Revision (if necessary)': dartRevision,
            'Increment': increment,
          },
        ),
      );
    });
  });

  group('The desktop app is connected with the CLI conductor', () {
    testWidgets('Is able to display a conductor exception in the UI', (WidgetTester tester) async {
      final StartContext startContext = MockStartContext();
      const String exceptionMsg = 'There is a conductor Exception';

      when(startContext.run()).thenThrow(ConductorException(exceptionMsg));

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      verify(startContext.run()).called(1);
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });

    testWidgets('Is able to display a general exception in the UI', (WidgetTester tester) async {
      final StartContext startContext = MockStartContext();
      const String exceptionMsg = 'There is a general Exception';

      when(startContext.run()).thenThrow(Exception(exceptionMsg));

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      verify(startContext.run()).called(1);
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });

    testWidgets('Proceeds to the next step if there is no exception', (WidgetTester tester) async {
      final StartContext startContext = MockStartContext();
      final FakeNextStep fakeNextStep = MockFakeNextStep();

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: fakeNextStep.nextStep,
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      verify(startContext.run()).called(1);
      verify(fakeNextStep.nextStep()).called(1);
    });

    testWidgets('Is able to display the loading UI, and hides it after release is done', (WidgetTester tester) async {
      final StartContext startContext = MockStartContext();
      const int delayInMS = 3000;

      when(startContext.run()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: delayInMS));
        return;
      });

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, false);

      await tester.pump(const Duration(milliseconds: delayInMS + 1000));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
    });
  });
}
