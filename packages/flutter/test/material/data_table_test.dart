// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data_table_test_utils.dart';

void main() {
  testWidgets('DataTable control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    Widget buildTable({ int sortColumnIndex, bool sortAscending: true }) {
      return new DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: (bool value) {
          log.add('select-all: $value');
        },
        columns: <DataColumn>[
          const DataColumn(
            label: const Text('Name'),
            tooltip: 'Name',
          ),
          new DataColumn(
            label: const Text('Calories'),
            tooltip: 'Calories',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {
              log.add('column-sort: $columnIndex $ascending');
            }
          ),
        ],
        rows: kDesserts.map((Dessert dessert) {
          return new DataRow(
            key: new Key(dessert.name),
            onSelectChanged: (bool selected) {
              log.add('row-selected: ${dessert.name}');
            },
            cells: <DataCell>[
              new DataCell(
                new Text(dessert.name),
              ),
              new DataCell(
                new Text('${dessert.calories}'),
                showEditIcon: true,
                onTap: () {
                  log.add('cell-tap: ${dessert.calories}');
                },
              ),
            ],
          );
        }).toList(),
      );
    }

    await tester.pumpWidget(new MaterialApp(
      home: new Material(child: buildTable())
    ));

    await tester.tap(find.byType(Checkbox).first);

    expect(log, <String>['select-all: true']);
    log.clear();

    await tester.tap(find.text('Cupcake'));

    expect(log, <String>['row-selected: Cupcake']);
    log.clear();

    await tester.tap(find.text('Calories'));

    expect(log, <String>['column-sort: 1 true']);
    log.clear();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(child: buildTable(sortColumnIndex: 1))
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.text('Calories'));

    expect(log, <String>['column-sort: 1 false']);
    log.clear();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(child: buildTable(sortColumnIndex: 1, sortAscending: false))
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.text('375'));

    expect(log, <String>['cell-tap: 375']);
    log.clear();

    await tester.tap(find.byType(Checkbox).last);

    expect(log, <String>['row-selected: KitKat']);
    log.clear();
  });
}
