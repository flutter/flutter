// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigation rail can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationRailUseCase());

    expect(find.byType(NavigationRail), findsExactly(1));
  });

  testWidgets('navigation rail can show/hide leading', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationRailUseCase());
    final Finder findLeading = find.byTooltip('Add');

    expect(findLeading, findsNothing);

    await tester.tap(find.text('Show Leading'));
    await tester.pump();
    expect(findLeading, findsOne);

    await tester.tap(find.text('Hide Leading'));
    await tester.pump();
    expect(findLeading, findsNothing);
  });

  testWidgets('navigation rail can show/hide trailing', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationRailUseCase());
    final Finder findTrailing = find.byTooltip('More');

    expect(findTrailing, findsNothing);

    await tester.tap(find.text('Show Trailing'));
    await tester.pump();
    expect(findTrailing, findsOne);

    await tester.tap(find.text('Hide Trailing'));
    await tester.pump();
    expect(findTrailing, findsNothing);
  });
}
