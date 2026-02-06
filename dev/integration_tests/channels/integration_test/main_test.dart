// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:channels/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final Finder statusField = find.byKey(const ValueKey<String>('status'));
final Finder stepButton = find.byKey(const ValueKey<String>('step'));

String getStatus(WidgetTester tester) => tester.widget<Text>(statusField).data!;

void main() {
  testWidgets('step through', (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    var step = -1;
    while (getStatus(tester) == 'ok') {
      step++;
      print('>> Tapping for step $step...');
      // TODO(goderbauer): Setting the pointer ID to something large to avoid
      //   that the test events clash with ghost events from the device to
      //   further investigate https://github.com/flutter/flutter/issues/116663.
      await tester.tap(stepButton, pointer: 500 + step);
      await tester.pump();
      expect(statusField, findsNothing);

      print('>> Waiting for step $step to complete...');
      while (tester.widgetList(statusField).isEmpty) {
        await tester.pumpAndSettle();
      }
    }

    final String status = getStatus(tester);
    if (status != 'complete') {
      fail('Failed at step $step with status $status');
    }
  });
}
