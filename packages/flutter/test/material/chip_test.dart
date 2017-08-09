// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {
  /// Tests that a [Chip] that has its size constrained by its parent is
  /// further constraining the size of its child, the label widget.
  /// Optionally, adding an avatar or delete icon to the chip should not
  /// cause the chip or label to exceed its constrained size.
  Future<Null> _testConstrainedLabel(WidgetTester tester, {
    CircleAvatar avatar, VoidCallback onDeleted,
  }) async {
    const double labelWidth = 100.0;
    const double labelHeight = 50.0;
    const double chipParentWidth = 75.0;
    const double chipParentHeight = 25.0;
    final Key labelKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Center(
            child: new Container(
              width: chipParentWidth,
              height: chipParentHeight,
              child: new Chip(
                avatar: avatar,
                label: new Container(
                  key: labelKey,
                  width: labelWidth,
                  height: labelHeight,
                ),
                onDeleted: onDeleted,
              ),
            ),
          ),
        ),
      ),
    );

    final Size labelSize = tester.getSize(find.byKey(labelKey));
    expect(labelSize.width, lessThan(chipParentWidth));
    expect(labelSize.height, lessThanOrEqualTo(chipParentHeight));

    final Size chipSize = tester.getSize(find.byType(Chip));
    expect(chipSize.width, chipParentWidth);
    expect(chipSize.height, chipParentHeight);
  }

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

  testWidgets(
      'Chip does not constrain size of label widget if it does not exceed '
      'the available space', (WidgetTester tester) async {
    const double labelWidth = 50.0;
    const double labelHeight = 30.0;
    final Key labelKey = new UniqueKey();

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Container(
            width: 500.0,
            height: 500.0,
            child: new Column(
              children: <Widget>[
                new Chip(
                  label: new Container(
                    key: labelKey,
                    width: labelWidth,
                    height: labelHeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Size labelSize = tester.getSize(find.byKey(labelKey));
    expect(labelSize.width, labelWidth);
    expect(labelSize.height, labelHeight);
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space', (WidgetTester tester) async {
    await _testConstrainedLabel(tester);
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space and the avatar is present', (WidgetTester tester) async {
    await _testConstrainedLabel(
      tester,
      avatar: const CircleAvatar(
        child: const Text('A')
      ),
    );
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space and the delete icon is present',
      (WidgetTester tester) async {
    await _testConstrainedLabel(
      tester,
      onDeleted: () {},
    );
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space and both avatar and delete icons are present',
      (WidgetTester tester) async {
    await _testConstrainedLabel(
      tester,
      avatar: const CircleAvatar(
        child: const Text('A')
      ),
      onDeleted: () {},
    );
  });
}
