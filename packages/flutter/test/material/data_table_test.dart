// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data_table_test_utils.dart';

void main() {
  testWidgets('DataTable control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    Widget buildTable({ int sortColumnIndex, bool sortAscending = true }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: (bool value) {
          log.add('select-all: $value');
        },
        columns: <DataColumn>[
          const DataColumn(
            label: Text('Name'),
            tooltip: 'Name',
          ),
          DataColumn(
            label: const Text('Calories'),
            tooltip: 'Calories',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {
              log.add('column-sort: $columnIndex $ascending');
            },
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: Key(dessert.name),
            onSelectChanged: (bool selected) {
              log.add('row-selected: ${dessert.name}');
            },
            cells: <DataCell>[
              DataCell(
                Text(dessert.name),
              ),
              DataCell(
                Text('${dessert.calories}'),
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

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable()),
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

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(sortColumnIndex: 1)),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.text('Calories'));

    expect(log, <String>['column-sort: 1 false']);
    log.clear();

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(sortColumnIndex: 1, sortAscending: false)),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.text('375'));

    expect(log, <String>['cell-tap: 375']);
    log.clear();

    await tester.tap(find.byType(Checkbox).last);

    expect(log, <String>['row-selected: KitKat']);
    log.clear();
  });

  testWidgets('DataTable overflow test - header', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: <DataColumn>[
              DataColumn(
                label: Text('X' * 2000),
              ),
            ],
            rows: const <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text('X'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Text).first).size.width, greaterThan(800.0));
    expect(tester.renderObject<RenderBox>(find.byType(Row).first).size.width, greaterThan(800.0));
    expect(tester.takeException(), isNull); // column overflows table, but text doesn't overflow cell
  });

  testWidgets('DataTable overflow test - header with spaces', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: <DataColumn>[
              DataColumn(
                label: Text('X ' * 2000), // has soft wrap points, but they should be ignored
              ),
            ],
            rows: const <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text('X'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Text).first).size.width, greaterThan(800.0));
    expect(tester.renderObject<RenderBox>(find.byType(Row).first).size.width, greaterThan(800.0));
    expect(tester.takeException(), isNull); // column overflows table, but text doesn't overflow cell
  }, skip: true); // https://github.com/flutter/flutter/issues/13512

  testWidgets('DataTable overflow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(
                label: Text('X'),
              ),
            ],
            rows: <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text('X' * 2000),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Text).first).size.width, lessThan(800.0));
    expect(tester.renderObject<RenderBox>(find.byType(Row).first).size.width, greaterThan(800.0));
    expect(tester.takeException(), isNull); // cell overflows table, but text doesn't overflow cell
  });

  testWidgets('DataTable overflow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(
                label: Text('X'),
              ),
            ],
            rows: <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text('X ' * 2000), // wraps
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Text).first).size.width, lessThan(800.0));
    expect(tester.renderObject<RenderBox>(find.byType(Row).first).size.width, lessThan(800.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('DataTable column onSort test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(
                label: Text('Dessert'),
              ),
            ],
            rows: const <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text('Lollipop'), // wraps
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dessert'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('DataTable row onSelectChanged test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(
                label: Text('Dessert'),
              ),
            ],
            rows: const <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text('Lollipop'), // wraps
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Lollipop'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('DataTable custom row height', (WidgetTester tester) async {
    Widget buildTable({
      int sortColumnIndex,
      bool sortAscending = true,
      double dataRowHeight,
      double headingRowHeight,
    }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: (bool value) {},
        dataRowHeight: dataRowHeight,
        headingRowHeight: headingRowHeight,
        columns: <DataColumn>[
          const DataColumn(
            label: Text('Name'),
            tooltip: 'Name',
          ),
          DataColumn(
            label: const Text('Calories'),
            tooltip: 'Calories',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {},
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: Key(dessert.name),
            onSelectChanged: (bool selected) {},
            cells: <DataCell>[
              DataCell(
                Text(dessert.name),
              ),
              DataCell(
                Text('${dessert.calories}'),
                showEditIcon: true,
                onTap: () {},
              ),
            ],
          );
        }).toList(),
      );
    }

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable()),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Name')
    ).size.height, 56.0); // This is the header row height
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Frozen yogurt')
    ).size.height, 48.0); // This is the data row height

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(headingRowHeight: 48.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Name')
    ).size.height, 48.0);

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(headingRowHeight: 64.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Name')
    ).size.height, 64.0);

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(dataRowHeight: 30.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Frozen yogurt')
    ).size.height, 30.0);

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(dataRowHeight: 56.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Frozen yogurt')
    ).size.height, 56.0);
  });
}
