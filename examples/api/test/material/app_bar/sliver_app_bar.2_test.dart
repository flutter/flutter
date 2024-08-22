// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/app_bar/sliver_app_bar.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Visibility of crucial widgets', (WidgetTester tester) async {
    await tester.pumpWidget(const example.AppBarMediumApp());

    const String title = 'Medium App Bar';

    expect(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.widgetWithText(SliverAppBar, title),
    ), findsOne);

    // Based on https://m3.material.io/components/top-app-bar/specs the title of
    // the SliverAppBar.medium widget is formatted with the headlineSmall style.
    final BuildContext context = tester.element(find.byType(MaterialApp));
    final TextStyle expectedTitleStyle = Theme.of(context).textTheme.headlineSmall!;

    // There are two Text() widgets: expanded and collapsed. The expanded is first.
    final Finder titleFinder = find.text(title).first;
    final TextStyle actualTitleStyle = DefaultTextStyle.of(tester.element(titleFinder) as BuildContext).style;

    expect(actualTitleStyle, expectedTitleStyle);
  });
}
