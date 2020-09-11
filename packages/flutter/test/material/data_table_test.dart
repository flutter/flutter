// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix3;

import '../rendering/mock_canvas.dart';
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
            headingTextStyle: const TextStyle(
              fontSize: 14.0,
              letterSpacing: 0.0, // Will overflow if letter spacing is larger than 0.0.
            ),
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

  testWidgets('DataTable sort indicator orientation', (WidgetTester tester) async {
    Widget buildTable({ bool sortAscending = true }) {
      return DataTable(
        sortColumnIndex: 0,
        sortAscending: sortAscending,
        columns: <DataColumn>[
          DataColumn(
            label: const Text('Name'),
            tooltip: 'Name',
            onSort: (int columnIndex, bool ascending) {},
          ),
        ],
        rows: kDesserts.map<DataRow>((Dessert dessert) {
          return DataRow(
            cells: <DataCell>[
              DataCell(
                Text(dessert.name),
              ),
            ],
          );
        }).toList(),
      );
    }

    // Check for ascending list
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(sortAscending: true)),
    ));
    // The `tester.widget` ensures that there is exactly one upward arrow.
    Transform transformOfArrow = tester.widget<Transform>(find.widgetWithIcon(Transform, Icons.arrow_upward));
    expect(
      transformOfArrow.transform.getRotation(),
      equals(Matrix3.identity())
    );

    // Check for descending list.
    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable(sortAscending: false)),
    ));
    await tester.pumpAndSettle();
    // The `tester.widget` ensures that there is exactly one upward arrow.
    transformOfArrow = tester.widget<Transform>(find.widgetWithIcon(Transform, Icons.arrow_upward));
    expect(
      transformOfArrow.transform.getRotation(),
      equals(Matrix3.rotationZ(math.pi))
    );
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
    padding = find.widgetWithText(Padding, 'Frozen yogurt').first;
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
    TableRow tableRow = table.children.last;
    BoxDecoration boxDecoration = tableRow.decoration as BoxDecoration;
    expect(boxDecoration.border.top.width, 1.0);

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
    tableRow = table.children.last;
    boxDecoration = tableRow.decoration as BoxDecoration;
    expect(boxDecoration.border.top.width, thickness);
  });

  testWidgets('DataTable set show bottom border', (WidgetTester tester) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: DataTable(
            showBottomBorder: true,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );

    Table table = tester.widget(find.byType(Table));
    TableRow tableRow = table.children.last;
    BoxDecoration boxDecoration = tableRow.decoration as BoxDecoration;
    expect(boxDecoration.border.bottom.width, 1.0);

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
    table = tester.widget(find.byType(Table));
    tableRow = table.children.last;
    boxDecoration = tableRow.decoration as BoxDecoration;
    expect(boxDecoration.border.bottom.width, 0.0);
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

  testWidgets('DataRow renders custom colors when selected', (WidgetTester tester) async {
    const Color selectedColor = Colors.green;
    const Color defaultColor = Colors.red;

    Widget buildTable({bool selected = false}) {
      return Material(
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(
              label: Text('Column1'),
            ),
          ],
          rows: <DataRow>[
            DataRow(
              selected: selected,
              color: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected))
                    return selectedColor;
                  return defaultColor;
                },
              ),
              cells: const <DataCell>[
                DataCell(Text('Content1')),
              ],
            ),
          ],
        ),
      );
    }

    BoxDecoration lastTableRowBoxDecoration() {
      final Table table = tester.widget(find.byType(Table));
      final TableRow tableRow = table.children.last;
      return tableRow.decoration as BoxDecoration;
    }

    await tester.pumpWidget(MaterialApp(
      home: buildTable(),
    ));
    expect(lastTableRowBoxDecoration().color, defaultColor);

    await tester.pumpWidget(MaterialApp(
      home: buildTable(selected: true),
    ));
    expect(lastTableRowBoxDecoration().color, selectedColor);
  });

  testWidgets('DataRow renders custom colors when disabled', (WidgetTester tester) async {
    const Color disabledColor = Colors.grey;
    const Color defaultColor = Colors.red;

    Widget buildTable({bool disabled = false}) {
      return Material(
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(
              label: Text('Column1'),
            ),
          ],
          rows: <DataRow>[
            DataRow(
              cells: const <DataCell>[
                DataCell(Text('Content1')),
              ],
              onSelectChanged: (bool value) {},
            ),
            DataRow(
              color: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled))
                    return disabledColor;
                  return defaultColor;
                },
              ),
              cells: const <DataCell>[
                DataCell(Text('Content2')),
              ],
              onSelectChanged: disabled ? null : (bool value) {},
            ),
          ],
        ),
      );
    }

    BoxDecoration lastTableRowBoxDecoration() {
      final Table table = tester.widget(find.byType(Table));
      final TableRow tableRow = table.children.last;
      return tableRow.decoration as BoxDecoration;
    }

    await tester.pumpWidget(MaterialApp(
      home: buildTable(),
    ));
    expect(lastTableRowBoxDecoration().color, defaultColor);

    await tester.pumpWidget(MaterialApp(
      home: buildTable(disabled: true),
    ));
    expect(lastTableRowBoxDecoration().color, disabledColor);
  });

  testWidgets('DataRow renders custom colors when pressed', (WidgetTester tester) async {
    const Color pressedColor = Color(0xff4caf50);
    Widget buildTable() {
      return DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Text('Column1'),
          ),
        ],
        rows: <DataRow>[
          DataRow(
            color: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed))
                  return pressedColor;
                return Colors.transparent;
              },
            ),
            onSelectChanged: (bool value) {},
            cells: const <DataCell>[
              DataCell(Text('Content1')),
            ],
          ),
        ]
      );
    }

    await tester.pumpWidget(MaterialApp(
      home: Material(child: buildTable()),
    ));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Content1')));
    await tester.pump(const Duration(milliseconds: 200)); // splash is well underway
    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as RenderBox;
    expect(box, paints..circle(x: 68.0, y: 24.0, color: pressedColor));
    await gesture.up();
  });

  testWidgets('DataTable can render inside an AlertDialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AlertDialog(
            content: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Col1')),
              ],
              rows: const <DataRow>[
                DataRow(cells: <DataCell>[DataCell(Text('1'))]),
              ],
            ),
            scrollable: true,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

}
