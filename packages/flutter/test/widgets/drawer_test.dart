// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets(
    'Dismissible ModalBarrier includes button in semantic tree',
    (WidgetTester tester) async {
      final semantics = SemanticsTester(tester);
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(key: scaffoldKey, drawer: const Drawer());
            },
          ),
        ),
      );

      // Open the drawer.
      scaffoldKey.currentState!.openDrawer();
      await tester.pump(const Duration(milliseconds: 100));

      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.tap]));
      expect(semantics, includesNodeWith(label: 'Dismiss'));

      semantics.dispose();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets('Dismissible ModalBarrier is hidden on Android (back button is used to dismiss)', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(key: scaffoldKey, drawer: const Drawer(), body: Container());
          },
        ),
      ),
    );

    // Open the drawer.
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      semantics,
      isNot(
        includesNodeWith(actions: <SemanticsAction>[SemanticsAction.tap, SemanticsAction.focus]),
      ),
    );
    expect(semantics, isNot(includesNodeWith(label: 'Dismiss')));

    semantics.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
