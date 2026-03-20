// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/expansion_panel/expansion_panel_list.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpansionPanel icon visibility can be toggled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.ExpansionPanelIconVisibilityExampleApp(),
    );

    expect(find.byType(ExpandIcon), findsNWidgets(3));

    final Finder visibilityFinder = find
        .ancestor(
          of: find.byType(ExpandIcon).first,
          matching: find.byType(Visibility),
        )
        .first;

    Visibility visibility = tester.widget(visibilityFinder);
    expect(visibility.visible, isTrue);

    await tester.tap(find.text('Hidden'));
    await tester.pumpAndSettle();

    visibility = tester.widget(visibilityFinder);
    expect(visibility.visible, isFalse);
    expect(visibility.maintainSize, isTrue);

    await tester.tap(find.text('Gone'));
    await tester.pumpAndSettle();

    visibility = tester.widget(visibilityFinder);
    expect(visibility.visible, isFalse);
    expect(visibility.maintainSize, isFalse);
  });

  testWidgets('Expanded panel remains collapsible when icon is hidden', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.ExpansionPanelIconVisibilityExampleApp(),
    );

    await tester.tap(find.byType(ExpandIcon).first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<ExpandIcon>(find.byType(ExpandIcon).first).isExpanded,
      true,
    );

    await tester.tap(find.text('Hidden'));
    await tester.pumpAndSettle();

    final Finder visibilityFinder = find
        .ancestor(
          of: find.byType(ExpandIcon).first,
          matching: find.byType(Visibility),
        )
        .first;

    final Visibility visibility = tester.widget(visibilityFinder);
    expect(visibility.visible, isTrue);
  });
}
