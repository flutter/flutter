// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:channels/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final Finder statusField = find.byKey(const ValueKey<String>('status'));
final Finder stepButton = find.byKey(const ValueKey<String>('step'));

String getStatus(WidgetTester tester) => tester.widget<Text>(statusField).data!;

void main() {
  testWidgets('step through', (WidgetTester tester) async {
    // TODO(goderbauer): Remove this once https://github.com/flutter/flutter/issues/116663 is diagnosed.
    debugPrintHitTestResults = true;

    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    int step = -1;
    while (getStatus(tester) == 'ok') {
      step++;
      print('>> Tapping for step $step...');
      await tester.tap(stepButton);
      await tester.pump();
      expect(statusField, findsNothing);

      print('>> Waiting for step $step to complete...');
      while (tester.widgetList(statusField).isEmpty) {
        await tester.pumpAndSettle();
      }
    }

    // TODO(goderbauer): Remove this once https://github.com/flutter/flutter/issues/116663 is diagnosed.
    debugPrintHitTestResults = false;

    final String status = getStatus(tester);
    if (status != 'complete') {
      fail('Failed at step $step with status $status');
    }
  });
}
