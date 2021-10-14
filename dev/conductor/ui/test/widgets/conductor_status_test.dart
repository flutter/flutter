// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/widgets/conductor_status.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('conductor_status', () {
    late pb.ConductorState state;

    const String testPath = './testPath';
    const String conductorVersion = 'v1.0';
    const String releaseChannel = 'beta';
    const String releaseVersion = '1.2.0-3.4.pre';
    const String engineCandidateBranch = 'flutter-1.2-candidate.3';
    const String frameworkCandidateBranch = 'flutter-1.2-candidate.4';
    const String workingBranch = 'cherrypicks-$engineCandidateBranch';
    const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
    const String engineCherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
    const String engineCherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
    const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
    const String engineStartingGitHead = '083049e6cae311910c6a6619a6681b7eba4035b4';
    const String engineCurrentGitHead = '23otn2o3itn2o3int2oi3tno23itno2i3tn';
    const String engineCheckoutPath = '/Users/alexchen/Desktop/flutter_conductor_checkouts/engine';
    const String frameworkStartingGitHead = 'df6981e98rh49er8h149er8h19er8h1';
    const String frameworkCurrentGitHead = '239tnint023t09j2039tj0239tn';
    const String frameworkCheckoutPath = '/Users/alexchen/Desktop/flutter_conductor_checkouts/framework';
    final String engineLUCIDashboard = luciConsoleLink(releaseChannel, 'engine');
    final String frameworkLUCIDashboard = luciConsoleLink(releaseChannel, 'flutter');

    setUp(() {
      state = pb.ConductorState(
        engine: pb.Repository(
          candidateBranch: engineCandidateBranch,
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(trunkRevision: engineCherrypick1),
            pb.Cherrypick(trunkRevision: engineCherrypick2),
          ],
          dartRevision: dartRevision,
          workingBranch: workingBranch,
          startingGitHead: engineStartingGitHead,
          currentGitHead: engineCurrentGitHead,
          checkoutPath: engineCheckoutPath,
        ),
        framework: pb.Repository(
          candidateBranch: frameworkCandidateBranch,
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(trunkRevision: frameworkCherrypick),
          ],
          workingBranch: workingBranch,
          startingGitHead: frameworkStartingGitHead,
          currentGitHead: frameworkCurrentGitHead,
          checkoutPath: frameworkCheckoutPath,
        ),
        conductorVersion: conductorVersion,
        releaseChannel: releaseChannel,
        releaseVersion: releaseVersion,
      );
    });
    testWidgets('Conductor_status displays nothing found when there is no state file', (WidgetTester tester) async {
      const String testPath = './testPath';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: const <Widget>[
                    ConductorStatus(
                      stateFilePath: testPath,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('No persistent state file found at $testPath'), findsOneWidget);
      expect(find.text('Conductor version:'), findsNothing);
    });

    testWidgets('Conductor_status displays correct status with a state file', (WidgetTester tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    ConductorStatus(
                      releaseState: state,
                      stateFilePath: testPath,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('No persistent state file found at $testPath'), findsNothing);
      for (final String headerElement in ConductorStatus.headerElements) {
        expect(find.text('$headerElement:'), findsOneWidget);
      }
      expect(find.text(conductorVersion), findsOneWidget);
      expect(find.text(releaseChannel), findsOneWidget);
      expect(find.text(releaseVersion), findsOneWidget);
      expect(find.text('Release Started at:'), findsOneWidget);
      expect(find.text('Release Updated at:'), findsOneWidget);
      expect(find.text(dartRevision), findsOneWidget);
      expect(find.text(engineCherrypick1), findsOneWidget);
      expect(find.text(engineCherrypick2), findsOneWidget);
      expect(find.text(frameworkCherrypick), findsOneWidget);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);

      /// Tests the tooltip is displaying status explanations upon cursor hovering.
      ///
      /// Before hovering, status explanations are not found.
      /// When the cursor hovers over the info icon, the explanations are displayed and found.
      expect(find.textContaining('PENDING: The cherrypick has not yet been applied.'), findsNothing);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('engineConductorStatusTooltip'))));
      await tester.pumpAndSettle();
      expect(find.textContaining('PENDING: The cherrypick has not yet been applied.'), findsOneWidget);
    });

    testWidgets('Conductor_status displays correct status with a null state file except a releaseChannel',
        (WidgetTester tester) async {
      final pb.ConductorState stateIncomplete = pb.ConductorState(
        releaseChannel: releaseChannel,
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    ConductorStatus(
                      releaseState: stateIncomplete,
                      stateFilePath: testPath,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('No persistent state file found at $testPath'), findsNothing);
      for (final String headerElement in ConductorStatus.headerElements) {
        expect(find.text('$headerElement:'), findsOneWidget);
      }
      expect(find.text(releaseChannel), findsOneWidget);
      expect(find.text('Unknown'), findsNWidgets(11));

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);

      /// Tests the tooltip is displaying status explanations upon cursor hovering.
      ///
      /// Before hovering, status explanations are not found.
      /// When the cursor hovers over the info icon, the explanations are displayed and found.
      expect(find.textContaining('PENDING: The cherrypick has not yet been applied.'), findsNothing);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('engineConductorStatusTooltip'))));
      await tester.pumpAndSettle();
      expect(find.textContaining('PENDING: The cherrypick has not yet been applied.'), findsOneWidget);
    });

    testWidgets('Repo Info section displays corresponding info in a dropdown fashion', (WidgetTester tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    ConductorStatus(
                      releaseState: state,
                      stateFilePath: testPath,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('No persistent state file found at $testPath'), findsNothing);
      for (final String repoElement in ConductorStatus.engineRepoElements) {
        expect(find.text('$repoElement:'), findsOneWidget);
      }
      for (final String repoElement in ConductorStatus.frameworkRepoElements) {
        expect(find.text('$repoElement:'), findsOneWidget);
      }
      expect(find.text(engineCandidateBranch), findsOneWidget);
      expect(find.text(engineStartingGitHead), findsOneWidget);
      expect(find.text(engineCurrentGitHead), findsOneWidget);
      expect(find.text(engineCheckoutPath), findsOneWidget);
      expect(find.text(engineLUCIDashboard), findsOneWidget);

      expect(find.text(frameworkCandidateBranch), findsOneWidget);
      expect(find.text(frameworkStartingGitHead), findsOneWidget);
      expect(find.text(frameworkCurrentGitHead), findsOneWidget);
      expect(find.text(frameworkCheckoutPath), findsOneWidget);
      expect(find.text(frameworkLUCIDashboard), findsOneWidget);

      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).first).children[0].isExpanded,
          equals(false));
      await tester.tap(find.byKey(const Key('engineRepoInfoDropdown')));
      await tester.pumpAndSettle();
      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).first).children[0].isExpanded,
          equals(true));
    });
  });
}
