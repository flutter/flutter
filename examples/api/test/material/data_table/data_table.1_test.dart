// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/data_table/data_table.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {

  testWidgets('Data table content can be scrolled', (WidgetTester tester) async {
    const String firstItemText = 'Row 0';
    const String lastItemText = 'Row 9';

    final Finder firstItemFinder = find.text(firstItemText).hitTestable();
    final Finder lastItemFinder = find.text(lastItemText).hitTestable();

    await tester.pumpWidget(
        const example.DataTableExampleApp()
    );

    //verify that first item is shown initially
    expect(firstItemFinder,findsOneWidget);
    //verify that last item is not shown initially
    expect(lastItemFinder,findsNothing);


    final Finder listFinder = find.byType(Scrollable);


    //Scroll until the last item appears.
    await tester.scrollUntilVisible(
      lastItemFinder,
      45.0,
      scrollable: listFinder,
    );

    // Verify that the last item is visible.
    expect(lastItemFinder, findsOneWidget);


  });
}
