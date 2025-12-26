// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('drawer can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, DrawerUseCase());

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openEndDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(Drawer), findsExactly(1));
  });

  testWidgets('drawer has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, DrawerUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('drawer Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}
