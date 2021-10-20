// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('When user clicks on a previously completed step, Stepper does not navigate back.',
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

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(0));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Initialize a New Flutter Release'));
    await tester.pumpAndSettle();

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(1));
  });
}
