// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {
  testWidgets('Chip control test', (WidgetTester tester) async {
    final FeedbackTester feedback = new FeedbackTester();
    final List<String> deletedChipLabels = <String>[];
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Column(
            children: <Widget>[
              new Chip(
                avatar: const CircleAvatar(
                  child: const Text('A')
                ),
                label: const Text('Chip A'),
                onDeleted: () {
                  deletedChipLabels.add('A');
                },
                deleteButtonTooltipMessage: 'Delete chip A',
              ),
              new Chip(
                avatar: const CircleAvatar(
                  child: const Text('B')
                ),
                label: const Text('Chip B'),
                onDeleted: () {
                  deletedChipLabels.add('B');
                },
                deleteButtonTooltipMessage: 'Delete chip B',
              ),
            ]
          )
        )
      )
    );

    expect(tester.widget(find.byTooltip('Delete chip A')), isNotNull);
    expect(tester.widget(find.byTooltip('Delete chip B')), isNotNull);

    expect(feedback.clickSoundCount, 0);

    expect(deletedChipLabels, isEmpty);
    await tester.tap(find.byTooltip('Delete chip A'));
    expect(deletedChipLabels, equals(<String>['A']));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 1);

    await tester.tap(find.byTooltip('Delete chip B'));
    expect(deletedChipLabels, equals(<String>['A', 'B']));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 2);

    feedback.dispose();
  });
}
