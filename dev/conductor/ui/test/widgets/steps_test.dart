// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  group('Progession steps and substeps workflow', () {
    testWidgets(
        'All substeps of the current step must be checked before able to continue to the next step',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: Column(
                  children: <Widget>[
                    MainProgression(
                      releaseState: null,
                      stateFilePath:
                          defaultStateFilePath(const LocalPlatform()),
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

      await tester.tap(find.text('Substep 1').first);
      await tester.tap(find.text('Substep 2').first);
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsNWidgets(0));

      await tester.tap(find.text('Substep 3').first);
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
