// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/material/data_table/data_table.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DataTable is scrollable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.DataTableExampleApp(),
    );

    expect(find.text('Row 0').hitTestable(), findsOneWidget);
    expect(find.text('Row 19').hitTestable(), findsNothing);

    await tester.ensureVisible(find.text('Row 19'));

    expect(find.text('Row 0').hitTestable(), findsNothing);
    expect(find.text('Row 19').hitTestable(), findsOneWidget);
  });
}
