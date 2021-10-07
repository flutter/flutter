// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/widgets/conductor_status.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Conductor_status displays nothing found when there is no state file', (WidgetTester tester) async {
    const String testPath = './testPath';
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: Column(
                children: const <Widget>[
                  ConductorStatus(
                    releaseState: null,
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
    const String testPath = './testPath';
    const String releaseChannel = 'beta';
    const String releaseVersion = '1.2.0-3.4.pre';
    const String candidateBranch = 'flutter-1.2-candidate.3';
    const String workingBranch = 'cherrypicks-$candidateBranch';
    const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
    const String engineCherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
    const String engineCherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
    const String frameworkCherrypick = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';

    final pb.ConductorState state = pb.ConductorState(
      engine: pb.Repository(
        candidateBranch: candidateBranch,
        cherrypicks: <pb.Cherrypick>[
          pb.Cherrypick(trunkRevision: engineCherrypick1),
          pb.Cherrypick(trunkRevision: engineCherrypick2),
        ],
        dartRevision: dartRevision,
        workingBranch: workingBranch,
        startingGitHead: 'engineStartingGitHead',
        currentGitHead: 'engineCurrentGitHead',
        checkoutPath: 'engineCheckoutPath',
      ),
      framework: pb.Repository(
        candidateBranch: candidateBranch,
        cherrypicks: <pb.Cherrypick>[
          pb.Cherrypick(trunkRevision: frameworkCherrypick),
        ],
        workingBranch: workingBranch,
        startingGitHead: 'frameworkStartingGitHead',
        currentGitHead: 'frameworkCurrentGitHead',
        checkoutPath: 'frameworkCheckoutPath',
      ),
      conductorVersion: 'v1.0',
      releaseChannel: releaseChannel,
      releaseVersion: releaseVersion,
    );

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: Column(
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
    expect(find.text('v1.0'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('1.2.0-3.4.pre'), findsOneWidget);
    expect(find.text('1969-12-31 19:00:00.000'), findsNWidgets(2));
    expect(find.text('fe9708ab688dcda9923f584ba370a66fcbc3811f'), findsOneWidget);
    expect(find.text('94d06a2e1d01a3b0c693b94d70c5e1df9d78d249'), findsOneWidget);
    expect(find.text('a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0'), findsNWidgets(2));

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);

    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(const Key('conductorStatusTooltip1'))));
    await tester.pumpAndSettle();
    expect(find.textContaining('PENDING: The cherrypick has not yet been applied.'), findsOneWidget);
  });
}
