// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/table/table.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Table has expected arrangement', (WidgetTester tester) async {
    await tester.pumpWidget(const example.TableExampleApp());

    final Table table = tester.widget<Table>(find.byType(Table));

    // Check the defined columnWidths.
    expect(table.columnWidths, const <int, TableColumnWidth>{
      0: IntrinsicColumnWidth(),
      1: FlexColumnWidth(),
      2: FixedColumnWidth(64),
    });

    // The table has two rows.
    expect(table.children.length, 2);

    for (int i = 0; i < table.children.length; i++) {
      // Each row has three containers.
      expect(table.children[i].children.length, 3);

      // Returns the width of given widget.
      double getWidgetWidth(Widget widget) {
        return tester.getSize(find.byWidget(widget)).width;
      }

      // Check table row container width.
      expect(getWidgetWidth(table.children[i].children.first), equals(128));
      expect(getWidgetWidth(table.children[i].children[2]), equals(64));
    }
  });
}
