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

  testWidgets('drawer is dismissible', (WidgetTester tester) async {
    await pumpsUseCase(tester, DrawerDismissibleUseCase(dismissibleDrawer: true));

    // check the flag is set at the Scaffold level
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.drawerDismissible, true);

    // open the drawer initially
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openEndDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // check that it's open
    expect(find.byType(Drawer), findsExactly(1));

    // close it programmatically
    state.closeEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(Drawer), findsExactly(0));

    // open it again, this time we'll try tapping on the modal barrier
    state.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(Drawer), findsExactly(1));

    // tap on the modal barrier
    // Find the ModalBarrier
    final modalBarrierFinder = find.byType(ModalBarrier);

    // Get the RenderBox of the ModalBarrier
    final modalBarrierRenderBox = tester.renderObject(modalBarrierFinder) as RenderBox;

    // Calculate a point to tap outside the Drawer
    // This example taps on the ModalBarrier somewhere outside its boundaries
    final modalBarrierCenter = Offset(400, 300);
    final tapPosition = modalBarrierRenderBox.localToGlobal(modalBarrierCenter);

    // Tap on the ModalBarrier
    await tester.tapAt(tapPosition);
    await tester.pumpAndSettle();

    // make sure the drawer is gone, since the flag is set to
    // drawerDismissible = true
    expect(find.byType(Drawer), findsExactly(0));
  });

  testWidgets('drawer is not dismissible', (WidgetTester tester) async {
    await pumpsUseCase(tester, DrawerDismissibleUseCase(dismissibleDrawer: false));

    // make sure the flag is set to false at the Scaffold level
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.drawerDismissible, false);

    // open the drawer initially
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openEndDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // check that it's open
    expect(find.byType(Drawer), findsExactly(1));

    // close it programmatically
    state.closeEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(Drawer), findsExactly(0));

    // open it again, this time we'll try tapping on the modal barrier
    state.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(Drawer), findsExactly(1));

    // tap on the modal barrier
    // Find the ModalBarrier
    final modalBarrierFinder = find.byType(ModalBarrier);

    // Get the RenderBox of the ModalBarrier
    final modalBarrierRenderBox = tester.renderObject(modalBarrierFinder) as RenderBox;

    // Calculate a point to tap outside the Drawer
    // This example taps on the ModalBarrier somewhere outside its boundaries
    final modalBarrierCenter = Offset(400, 300);
    final tapPosition = modalBarrierRenderBox.localToGlobal(modalBarrierCenter);

    // Tap on the ModalBarrier
    await tester.tapAt(tapPosition);
    await tester.pumpAndSettle();

    // make sure the drawer is still present, and by tapping on the
    // modal barrier didn't dismiss it, since the property
    // is set to drawerDismissible = false.
    expect(find.byType(Drawer), findsExactly(1));
  });
}
