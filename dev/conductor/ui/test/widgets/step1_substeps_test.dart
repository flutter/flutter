// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/step1_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget should save all parameters correctly', (WidgetTester tester) async {
    const String candidateBranch = 'flutter-1.2-candidate.3';
    const String releaseChannel = 'dev';
    const String frameworkMirror = 'git@github.com:test/flutter.git';
    const String engineMirror = 'git@github.com:test/engine.git';
    const String engineCherrypick = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0,94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
    const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
    const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
    const String increment = 'y';

    void emptyFunction() {}

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: ListView(
                children: <Widget>[
                  Step1Substeps(
                    nextStep: emptyFunction,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    expect(Step1Substeps.releaseData, equals(<String, String>{'Release Channel': 'stable', 'Increment': 'm'}));

    await tester.enterText(find.byKey(const Key('Candidate Branch')), candidateBranch);

    /// Tests the Release Channel dropdown menu.
    await tester.tap(find.byKey(const Key('Release Channel')));
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation
    expect(Step1Substeps.releaseData['Release Channel'], equals('stable'));
    await tester.tap(find.text(releaseChannel).last);
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    await tester.enterText(find.byKey(const Key('Framework Mirror')), frameworkMirror);
    await tester.enterText(find.byKey(const Key('Engine Mirror')), engineMirror);
    await tester.enterText(find.byKey(const Key('Engine Cherrypicks')), engineCherrypick);
    await tester.enterText(find.byKey(const Key('Framework Cherrypicks')), frameworkCherrypick);
    await tester.enterText(find.byKey(const Key('Dart Revision')), dartRevision);

    /// Tests the Increment dropdown menu.
    await tester.tap(find.byKey(const Key('Increment')));
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation
    expect(Step1Substeps.releaseData['Increment'], equals('m'));
    await tester.tap(find.text(increment).last);
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    await tester.pumpAndSettle();

    expect(
        Step1Substeps.releaseData,
        equals(<String, String>{
          'Candidate Branch': candidateBranch,
          'Release Channel': releaseChannel,
          'Framework Mirror': frameworkMirror,
          'Engine Mirror': engineMirror,
          'Engine Cherrypicks': engineCherrypick,
          'Framework Cherrypicks': frameworkCherrypick,
          'Dart Revision': dartRevision,
          'Increment': increment,
        }));
  });
}
