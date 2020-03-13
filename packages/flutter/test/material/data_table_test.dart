// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
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
            key: ValueKey<String>(dessert.name),
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

  testWidgets('DataTable control test - no checkboxes', (WidgetTester tester) async {
    final List<String> log = <String>[];

    Widget buildTable({ bool checkboxes = false }) {
      return DataTable(
        showCheckboxColumn: checkboxes,
        onSelectAll: (bool value) {
          log.add('select-all: $value');
        },
        columns: const <DataColumn>[
          DataColumn(
            label: Text('Name'),
            tooltip: 'Name',
          ),
          DataColumn(
            label: Text('Calories'),
            tooltip: 'Calories',
            numeric: true,
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: ValueKey<String>(dessert.name),
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

    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.text('Cupcake'));

    expect(log, <String>['row-selected: Cupcake']);
    log.clear();

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(checkboxes: true)),
    ));

    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    final Finder checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(11));
    await tester.tap(checkboxes.first);

    expect(log, <String>['select-all: true']);
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
    Widget buildCustomTable({
      int sortColumnIndex,
      bool sortAscending = true,
      double dataRowHeight = 48.0,
      double headingRowHeight = 56.0,
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
            key: ValueKey<String>(dessert.name),
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

    // DEFAULT VALUES
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: DataTable(
          onSelectAll: (bool value) {},
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
              key: ValueKey<String>(dessert.name),
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
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Name')
    ).size.height, 56.0); // This is the header row height
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Frozen yogurt')
    ).size.height, 48.0); // This is the data row height

    // CUSTOM VALUES
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildCustomTable(headingRowHeight: 48.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Name')
    ).size.height, 48.0);

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildCustomTable(headingRowHeight: 64.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Name')
    ).size.height, 64.0);

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildCustomTable(dataRowHeight: 30.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Frozen yogurt')
    ).size.height, 30.0);

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildCustomTable(dataRowHeight: 56.0)),
    ));
    expect(tester.renderObject<RenderBox>(
      find.widgetWithText(Container, 'Frozen yogurt')
    ).size.height, 56.0);
  });

  testWidgets('DataTable custom horizontal padding - checkbox', (WidgetTester tester) async {
    const double _defaultHorizontalMargin = 24.0;
    const double _defaultColumnSpacing = 56.0;
    const double _customHorizontalMargin = 10.0;
    const double _customColumnSpacing = 15.0;
    Finder cellContent;
    Finder checkbox;
    Finder padding;

    Widget buildDefaultTable({
      int sortColumnIndex,
      bool sortAscending = true,
    }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: (bool value) {},
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
          DataColumn(
            label: const Text('Fat'),
            tooltip: 'Fat',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {},
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: ValueKey<String>(dessert.name),
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
              DataCell(
                Text('${dessert.fat}'),
                showEditIcon: true,
                onTap: () {},
              ),
            ],
          );
        }).toList(),
      );
    }

    // DEFAULT VALUES
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildDefaultTable()),
    ));

    // default checkbox padding
    checkbox = find.byType(Checkbox).first;
    padding = find.ancestor(of: checkbox, matching: find.byType(Padding));
    expect(
      tester.getRect(checkbox).left - tester.getRect(padding).left,
      _defaultHorizontalMargin,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(checkbox).right,
      _defaultHorizontalMargin / 2,
    );

    // default first column padding
    padding = find.widgetWithText(Padding, 'Frozen yogurt');
    cellContent = find.widgetWithText(Align, 'Frozen yogurt'); // DataTable wraps its DataCells in an Align widget
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _defaultHorizontalMargin / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _defaultColumnSpacing / 2,
    );

    // default middle column padding
    padding = find.widgetWithText(Padding, '159');
    cellContent = find.widgetWithText(Align, '159');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _defaultColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _defaultColumnSpacing / 2,
    );

    // default last column padding
    padding = find.widgetWithText(Padding, '6.0');
    cellContent = find.widgetWithText(Align, '6.0');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _defaultColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _defaultHorizontalMargin,
    );

    Widget buildCustomTable({
      int sortColumnIndex,
      bool sortAscending = true,
      double horizontalMargin,
      double columnSpacing,
    }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: (bool value) {},
        horizontalMargin: horizontalMargin,
        columnSpacing: columnSpacing,
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
          DataColumn(
            label: const Text('Fat'),
            tooltip: 'Fat',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {},
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: ValueKey<String>(dessert.name),
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
              DataCell(
                Text('${dessert.fat}'),
                showEditIcon: true,
                onTap: () {},
              ),
            ],
          );
        }).toList(),
      );
    }

    // CUSTOM VALUES
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildCustomTable(
        horizontalMargin: _customHorizontalMargin,
        columnSpacing: _customColumnSpacing,
      )),
    ));

    // custom checkbox padding
    checkbox = find.byType(Checkbox).first;
    padding = find.ancestor(of: checkbox, matching: find.byType(Padding));
    expect(
      tester.getRect(checkbox).left - tester.getRect(padding).left,
      _customHorizontalMargin,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(checkbox).right,
      _customHorizontalMargin / 2,
    );

    // custom first column padding
    padding = find.widgetWithText(Padding, 'Frozen yogurt');
    cellContent = find.widgetWithText(Align, 'Frozen yogurt'); // DataTable wraps its DataCells in an Align widget
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _customHorizontalMargin / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _customColumnSpacing / 2,
    );

    // custom middle column padding
    padding = find.widgetWithText(Padding, '159');
    cellContent = find.widgetWithText(Align, '159');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _customColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _customColumnSpacing / 2,
    );

    // custom last column padding
    padding = find.widgetWithText(Padding, '6.0');
    cellContent = find.widgetWithText(Align, '6.0');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _customColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _customHorizontalMargin,
    );
  });

  testWidgets('DataTable custom horizontal padding - no checkbox', (WidgetTester tester) async {
    const double _defaultHorizontalMargin = 24.0;
    const double _defaultColumnSpacing = 56.0;
    const double _customHorizontalMargin = 10.0;
    const double _customColumnSpacing = 15.0;
    Finder cellContent;
    Finder padding;

    Widget buildDefaultTable({
      int sortColumnIndex,
      bool sortAscending = true,
    }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
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
          DataColumn(
            label: const Text('Fat'),
            tooltip: 'Fat',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {},
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: ValueKey<String>(dessert.name),
            cells: <DataCell>[
              DataCell(
                Text(dessert.name),
              ),
              DataCell(
                Text('${dessert.calories}'),
                showEditIcon: true,
                onTap: () {},
              ),
              DataCell(
                Text('${dessert.fat}'),
                showEditIcon: true,
                onTap: () {},
              ),
            ],
          );
        }).toList(),
      );
    }

    // DEFAULT VALUES
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildDefaultTable()),
    ));

    // default first column padding
    padding = find.widgetWithText(Padding, 'Frozen yogurt');
    cellContent = find.widgetWithText(Align, 'Frozen yogurt'); // DataTable wraps its DataCells in an Align widget
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _defaultHorizontalMargin,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _defaultColumnSpacing / 2,
    );

    // default middle column padding
    padding = find.widgetWithText(Padding, '159');
    cellContent = find.widgetWithText(Align, '159');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _defaultColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _defaultColumnSpacing / 2,
    );

    // default last column padding
    padding = find.widgetWithText(Padding, '6.0');
    cellContent = find.widgetWithText(Align, '6.0');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _defaultColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _defaultHorizontalMargin,
    );

    Widget buildCustomTable({
      int sortColumnIndex,
      bool sortAscending = true,
      double horizontalMargin,
      double columnSpacing,
    }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        horizontalMargin: horizontalMargin,
        columnSpacing: columnSpacing,
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
          DataColumn(
            label: const Text('Fat'),
            tooltip: 'Fat',
            numeric: true,
            onSort: (int columnIndex, bool ascending) {},
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            key: ValueKey<String>(dessert.name),
            cells: <DataCell>[
              DataCell(
                Text(dessert.name),
              ),
              DataCell(
                Text('${dessert.calories}'),
                showEditIcon: true,
                onTap: () {},
              ),
              DataCell(
                Text('${dessert.fat}'),
                showEditIcon: true,
                onTap: () {},
              ),
            ],
          );
        }).toList(),
      );
    }

    // CUSTOM VALUES
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildCustomTable(
        horizontalMargin: _customHorizontalMargin,
        columnSpacing: _customColumnSpacing,
      )),
    ));

    // custom first column padding
    padding = find.widgetWithText(Padding, 'Frozen yogurt');
    cellContent = find.widgetWithText(Align, 'Frozen yogurt'); // DataTable wraps its DataCells in an Align widget
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _customHorizontalMargin,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _customColumnSpacing / 2,
    );

    // custom middle column padding
    padding = find.widgetWithText(Padding, '159');
    cellContent = find.widgetWithText(Align, '159');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _customColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _customColumnSpacing / 2,
    );

    // custom last column padding
    padding = find.widgetWithText(Padding, '6.0');
    cellContent = find.widgetWithText(Align, '6.0');
    expect(
      tester.getRect(cellContent).left - tester.getRect(padding).left,
      _customColumnSpacing / 2,
    );
    expect(
      tester.getRect(padding).right - tester.getRect(cellContent).right,
      _customHorizontalMargin,
    );
  });

  testWidgets('DataTable set border width test', (WidgetTester tester) async {
    const List<DataColumn> columns = <DataColumn>[
      DataColumn(label: Text('column1')),
      DataColumn(label: Text('column2')),
    ];

    const List<DataCell> cells = <DataCell>[
      DataCell(Text('cell1')),
      DataCell(Text('cell2')),
    ];

    const List<DataRow> rows = <DataRow>[
      DataRow(cells: cells),
      DataRow(cells: cells),
    ];

    // no thickness provided - border should be default: i.e "1.0" as it
    // set in DataTable constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );

    Table table = tester.widget(find.byType(Table));
    TableRow tableRow = table.children.first;
    BoxDecoration boxDecoration = tableRow.decoration as BoxDecoration;
    expect(boxDecoration.border.bottom.width, 1.0);

    const double thickness =  4.2;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            dividerThickness: thickness,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
    table = tester.widget(find.byType(Table));
    tableRow = table.children.first;
    boxDecoration = tableRow.decoration as BoxDecoration;
    expect(boxDecoration.border.bottom.width, thickness);
  });

  testWidgets('DataTable column heading cell - with and without sorting', (WidgetTester tester) async {
    Widget buildTable({ int sortColumnIndex, bool sortEnabled = true }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        columns: <DataColumn>[
          DataColumn(
            label: const Expanded(child: Center(child: Text('Name'))),
            tooltip: 'Name',
            onSort: sortEnabled ? (_, __) {} : null,
          ),
        ],
        rows: const <DataRow>[
          DataRow(
            cells: <DataCell>[
              DataCell(Text('A long desert name')),
            ],
          ),
        ]
      );
    }

    // Start with without sorting
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(
        sortEnabled: false,
      )),
    ));

    {
      final Finder nameText = find.text('Name');
      expect(nameText, findsOneWidget);
      final Finder nameCell = find.ancestor(of: find.text('Name'), matching: find.byType(Container)).first;
      expect(tester.getCenter(nameText), equals(tester.getCenter(nameCell)));
      expect(find.descendant(of: nameCell, matching: find.byType(Icon)), findsNothing);
    }

    // Turn on sorting
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(
        sortEnabled: true,
      )),
    ));

    {
      final Finder nameText = find.text('Name');
      expect(nameText, findsOneWidget);
      final Finder nameCell = find.ancestor(of: find.text('Name'), matching: find.byType(Container)).first;
      expect(find.descendant(of: nameCell, matching: find.byType(Icon)), findsOneWidget);
    }

    // Turn off sorting again
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(
        sortEnabled: false,
      )),
    ));

    {
      final Finder nameText = find.text('Name');
      expect(nameText, findsOneWidget);
      final Finder nameCell = find.ancestor(of: find.text('Name'), matching: find.byType(Container)).first;
      expect(tester.getCenter(nameText), equals(tester.getCenter(nameCell)));
      expect(find.descendant(of: nameCell, matching: find.byType(Icon)), findsNothing);
    }
  });

  testWidgets('DataTable correctly renders with a mouse', (WidgetTester tester) async {
    // Regression test for a bug described in
    // https://github.com/flutter/flutter/pull/43735#issuecomment-589459947
    // Filed at https://github.com/flutter/flutter/issues/51152
    Widget buildTable({ int sortColumnIndex }) {
      return DataTable(
        sortColumnIndex: sortColumnIndex,
        columns: <DataColumn>[
          const DataColumn(
            label: Expanded(child: Center(child: Text('column1'))),
            tooltip: 'Column1',
          ),
          DataColumn(
            label: const Expanded(child: Center(child: Text('column2'))),
            tooltip: 'Column2',
            onSort: (_, __) {},
          ),
        ],
        rows: const <DataRow>[
          DataRow(
            cells: <DataCell>[
              DataCell(Text('Content1')),
              DataCell(Text('Content2')),
            ],
          ),
        ]
      );
    }

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable()),
    ));

    expect(tester.renderObject(find.text('column1')).attached, true);
    expect(tester.renderObject(find.text('column2')).attached, true);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await tester.pumpAndSettle();
    expect(tester.renderObject(find.text('column1')).attached, true);
    expect(tester.renderObject(find.text('column2')).attached, true);

    // Wait for the tooltip timer to expire to prevent it scheduling a new frame
    // after the view is destroyed, which causes exceptions.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
