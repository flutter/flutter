// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The global rect of `node` in logical pixels. Semantics geometry is in
  // physical pixels, so the device pixel ratio is divided back out.
  Rect globalSemanticsRect(WidgetTester tester, SemanticsNode node) {
    Matrix4 transform = node.transform ?? Matrix4.identity();
    for (SemanticsNode? parent = node.parent; parent != null; parent = parent.parent) {
      if (parent.transform != null) {
        transform = parent.transform!.multiplied(transform);
      }
    }
    final Rect rect = MatrixUtils.transformRect(transform, node.rect);
    final double scale = tester.view.devicePixelRatio;
    return Rect.fromLTRB(
      rect.left / scale,
      rect.top / scale,
      rect.right / scale,
      rect.bottom / scale,
    );
  }

  testWidgets(
    'Regression test: semantics geometry of a text field is updated after the keyboard is '
    'dismissed while a dialog is up',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/186178.
      final navigatorKey = GlobalKey<NavigatorState>();

      // The keyboard is up.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: 50,
                    itemBuilder: (BuildContext context, int index) =>
                        ListTile(title: Text('Item $index')),
                  ),
                ),
                const TextField(decoration: InputDecoration(hintText: 'Input')),
              ],
            ),
          ),
        ),
      );

      // A dialog opens and the keyboard is dismissed while it is up.
      final BuildContext context = navigatorKey.currentContext!;
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => const AlertDialog(content: Text('Dialog')),
      );
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);

      // The dialog is closed.
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel('Input'));
      expect(globalSemanticsRect(tester, node), tester.getRect(find.byType(TextField)));
    },
  );
}
