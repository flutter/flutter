// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/conductor_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget should save all parameters correctly', (WidgetTester tester) async {
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
}
