// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_api_samples/cupertino/dialog/cupertino_alert_dialog.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('Perform an action on CupertinoAlertDialog', (WidgetTester tester) async {
    const String actionText = 'Yes';
    await tester.pumpWidget(const example.AlertDialogApp());

    // Launch the CupertinoAlertDialog.
    await tester.tap(find.byType(CupertinoButton));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(actionText), findsOneWidget);

    // Tap on an action to close the CupertinoAlertDialog.
    await tester.tap(find.text(actionText));
    await tester.pumpAndSettle();
    expect(find.text(actionText), findsNothing);
  });

  testWidgets('Check for Directionality', (WidgetTester tester) async {
    const String actionText = 'Yes';
    await tester.pumpWidget(const example.AlertDialogApp());

    // Launch the CupertinoAlertDialog.
    await tester.tap(find.byType(CupertinoButton));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(actionText), findsOneWidget);

    // Tap on an action to close the CupertinoAlertDialog.
    await tester.tap(find.text(actionText));
    await tester.pumpAndSettle();
    expect(find.text(actionText), findsNothing);
  });

  testWidgets('Check for Directionality', (WidgetTester tester) async {
    Future<void> pumpWidget({required bool isLTR}) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
            child: const CupertinoAlertDialog(
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(isDefaultAction: true, child: Text('No')),
                CupertinoDialogAction(child: Text('Yes')),
              ],
            ),
          ),
        ),
      );
    }

    await pumpWidget(isLTR: true);
    Vector3 yesButton =
        tester.firstRenderObject(find.text('Yes')).getTransformTo(null).getTranslation();
    Vector3 noButton =
        tester.firstRenderObject(find.text('No')).getTransformTo(null).getTranslation();
    expect(yesButton.x > noButton.x, true);
    await pumpWidget(isLTR: false);
    yesButton = tester.firstRenderObject(find.text('Yes')).getTransformTo(null).getTranslation();
    noButton = tester.firstRenderObject(find.text('No')).getTransformTo(null).getTranslation();
    expect(yesButton.x > noButton.x, false);
  });
}
