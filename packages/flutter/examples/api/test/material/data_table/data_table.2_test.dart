// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/data_table/data_table.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  DataTable getTable(WidgetTester tester) {
    return tester.widget<DataTable>(find.byType(DataTable));
  }

  List<String> namesInOrder(WidgetTester tester) {
    return getTable(tester).rows
        .map((DataRow row) => (row.cells[0].child as Text).data!)
        .toList();
  }

  testWidgets('DataTable starts unsorted', (WidgetTester tester) async {
    await tester.pumpWidget(const example.DataTableExampleApp());

    expect(getTable(tester).sortColumnIndex, isNull);
    expect(namesInOrder(tester), <String>[
      'Sarah',
      'Janine',
      'William',
      'Emma',
      'Liam',
      'Olivia',
    ]);
  });

  testWidgets('Tapping Age sorts by age and tapping again reverses it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.DataTableExampleApp());

    await tester.tap(find.text('Age'));
    await tester.pumpAndSettle();
    expect(getTable(tester).sortColumnIndex, 1);
    expect(getTable(tester).sortAscending, isTrue);
    expect(namesInOrder(tester), <String>[
      'Sarah',
      'Olivia',
      'William',
      'Emma',
      'Janine',
      'Liam',
    ]);

    await tester.tap(find.text('Age'));
    await tester.pumpAndSettle();
    expect(getTable(tester).sortColumnIndex, 1);
    expect(getTable(tester).sortAscending, isFalse);
    expect(namesInOrder(tester), <String>[
      'Liam',
      'Janine',
      'Emma',
      'William',
      'Olivia',
      'Sarah',
    ]);
  });

  testWidgets('Tapping Name after Age sorts by name ascending', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.DataTableExampleApp());

    await tester.tap(find.text('Age'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();

    expect(getTable(tester).sortColumnIndex, 0);
    expect(getTable(tester).sortAscending, isTrue);
    expect(namesInOrder(tester), <String>[
      'Emma',
      'Janine',
      'Liam',
      'Olivia',
      'Sarah',
      'William',
    ]);
  });

  testWidgets('Role column is not sortable', (WidgetTester tester) async {
    await tester.pumpWidget(const example.DataTableExampleApp());

    expect(getTable(tester).columns[2].onSort, isNull);

    await tester.tap(find.text('Role'));
    await tester.pumpAndSettle();
    expect(getTable(tester).sortColumnIndex, isNull);
    expect(namesInOrder(tester).first, 'Sarah');
  });
}
