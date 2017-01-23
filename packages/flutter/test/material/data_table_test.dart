// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Dessert {
  Dessert(this.name, this.calories, this.fat, this.carbs, this.protein, this.sodium, this.calcium, this.iron);

  final String name;
  final int calories;
  final double fat;
  final int carbs;
  final double protein;
  final int sodium;
  final int calcium;
  final int iron;
}

final List<Dessert> kDesserts = <Dessert>[
  new Dessert('Frozen yogurt',                        159,  6.0,  24,  4.0,  87, 14,  1),
  new Dessert('Ice cream sandwich',                   237,  9.0,  37,  4.3, 129,  8,  1),
  new Dessert('Eclair',                               262, 16.0,  24,  6.0, 337,  6,  7),
  new Dessert('Cupcake',                              305,  3.7,  67,  4.3, 413,  3,  8),
  new Dessert('Gingerbread',                          356, 16.0,  49,  3.9, 327,  7, 16),
  new Dessert('Jelly bean',                           375,  0.0,  94,  0.0,  50,  0,  0),
  new Dessert('Lollipop',                             392,  0.2,  98,  0.0,  38,  0,  2),
  new Dessert('Honeycomb',                            408,  3.2,  87,  6.5, 562,  0, 45),
  new Dessert('Donut',                                452, 25.0,  51,  4.9, 326,  2, 22),
  new Dessert('KitKat',                               518, 26.0,  65,  7.0,  54, 12,  6),
];

void main() {
  testWidgets('DataTable control test', (WidgetTester tester) async {
    List<String> log = <String>[];

    Widget buildTable({ int sortColumnIndex, bool sortAscending: true }) {
      return new DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: (bool value) {
          log.add('select-all: $value');
        },
        columns: <DataColumn>[
          new DataColumn(
            label: new Text('Name'),
            tooltip: 'Name',
          ),
          new DataColumn(
            label: new Text('Calories'),
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
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 200));
    await tester.tap(find.text('Calories'));

    expect(log, <String>['column-sort: 1 false']);
    log.clear();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(child: buildTable(sortColumnIndex: 1, sortAscending: false))
    ));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 200));

    await tester.tap(find.text('375'));

    expect(log, <String>['cell-tap: 375']);
    log.clear();

    await tester.tap(find.byType(Checkbox).last);

    expect(log, <String>['row-selected: KitKat']);
    log.clear();
  });
}
