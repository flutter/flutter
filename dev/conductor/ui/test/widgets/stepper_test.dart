// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/progression.dart';
import 'package:conductor_ui/widgets/step1_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('All substeps of the current step must be checked before able to continue to the next step',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: Column(
                children: const <Widget>[
                  MainProgression(
                    stateFilePath: './testPath',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('Initialize a New Flutter Release'), findsOneWidget);
    expect(find.text('Continue'), findsNWidgets(0));

    // await tester.tap(find.ancestor(
    //     of: find.byKey(Key('${Step1Substeps.substepTitles[0]}')), matching: find.byType(CheckboxListTile)));
    await tester.tap(find.byType(CheckboxListTile).first);
    expect(find.text('Continue'), findsNWidgets(1));

    // /// Check every substep except the last one.
    // ///
    // /// Continue button should not appear.
    // for (int i = 0; i < Step1Substeps.substepTitles.length - 1; i++) {
    //   await tester.tap(find.byKey(Key('CheckBox${Step1Substeps.substepTitles[i]}')));
    // }
    // await tester.pumpAndSettle();
    // expect(find.text('Continue'), findsNWidgets(0));

    // /// Check the last substep.
    // ///
    // /// Continue button should appear now.
    // await tester.tap(find.byKey(Key('CheckBox${Step1Substeps.substepTitles[Step1Substeps.substepTitles.length - 1]}')));
    // await tester.pumpAndSettle();
    // expect(find.text('Continue'), findsOneWidget);
    // expect(tester.widget<Stepper>(find.byType(Stepper)).steps[0].state, equals(StepState.indexed));
    // expect(tester.widget<Stepper>(find.byType(Stepper)).steps[1].state, equals(StepState.disabled));

    // /// Tapping Continue button should proceed to the next step inside the Stepper widget.
    // await tester.tap(find.text('Continue'));
    // await tester.pumpAndSettle();
    // expect(tester.widget<Stepper>(find.byType(Stepper)).steps[0].state, equals(StepState.complete));
    // expect(tester.widget<Stepper>(find.byType(Stepper)).steps[1].state, equals(StepState.indexed));
  });

  // testWidgets('When user clicks on a previously completed step, Stepper does not navigate back.',
  //     (WidgetTester tester) async {
  //   await tester.pumpWidget(
  //     StatefulBuilder(
  //       builder: (BuildContext context, StateSetter setState) {
  //         return MaterialApp(
  //           home: Material(
  //             child: Column(
  //               children: const <Widget>[
  //                 MainProgression(
  //                   stateFilePath: './testPath',
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );

  //   await tester.tap(find.text('Substep 1').first);
  //   await tester.tap(find.text('Substep 2').first);
  //   await tester.tap(find.text('Substep 3').first);
  //   await tester.pumpAndSettle();
  //   await tester.tap(find.text('Continue'));
  //   await tester.tap(find.text('Initialize a New Flutter Release'));
  //   await tester.pumpAndSettle();

  //   expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(1));
  // });
}
