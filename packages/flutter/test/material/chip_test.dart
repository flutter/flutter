// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {
  testWidgets('Chip control test', (WidgetTester tester) async {
    final FeedbackTester feedback = new FeedbackTester();
    bool didDeleteChip = false;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Center(
            child: new Chip(
              avatar: const CircleAvatar(
                child: const Text('C')
              ),
              label: const Text('Chip'),
              onDeleted: () {
                didDeleteChip = true;
              }
            )
          )
        )
      )
    );

    expect(feedback.clickSoundCount, 0);

    expect(didDeleteChip, isFalse);
    await tester.tap(find.byType(Tooltip));
    expect(didDeleteChip, isTrue);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 1);
  });
}
