// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DataTableThemeData copyWith, ==, hashCode basics', () {
    expect(const DataTableThemeData(), const DataTableThemeData().copyWith());
    expect(const DataTableThemeData().hashCode, const DataTableThemeData().copyWith().hashCode);
  });

  test('DataTableThemeData defaults', () {
    const DataTableThemeData themeData = DataTableThemeData();
    expect(themeData.dataRowColor, null);
    expect(themeData.dataRowHeight, null);
    expect(themeData.dataTextStyle, null);
    expect(themeData.headingRowColor, null);
    expect(themeData.headingRowHeight, null);
    expect(themeData.headingTextStyle, null);
    expect(themeData.horizontalMargin, null);
    expect(themeData.columnSpacing, null);
    expect(themeData.dividerThickness, null);

    const DataTableTheme theme = DataTableTheme(data: DataTableThemeData());
    expect(theme.data.dataRowColor, null);
    expect(theme.data.dataRowHeight, null);
    expect(theme.data.dataTextStyle, null);
    expect(theme.data.headingRowColor, null);
    expect(theme.data.headingRowHeight, null);
    expect(theme.data.headingTextStyle, null);
    expect(theme.data.horizontalMargin, null);
    expect(theme.data.columnSpacing, null);
    expect(theme.data.dividerThickness, null);
  });

  testWidgets('Default DataTableThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DataTableThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('DataTableThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    DataTableThemeData(
      dataRowColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) => const Color(0xfffffff1),
      ),
      dataRowHeight: 51.0,
      dataTextStyle: const TextStyle(fontSize: 12.0),
      headingRowColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) => const Color(0xfffffff2),
      ),
      headingRowHeight: 52.0,
      headingTextStyle:  const TextStyle(fontSize: 14.0),
      horizontalMargin: 3.0,
      columnSpacing: 4.0,
      dividerThickness: 5.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description[0], 'dataRowColor: Instance of \'_MaterialStatePropertyWith<Color>\'');
    expect(description[1], 'dataRowHeight: 51.0');
    expect(description[2], 'dataTextStyle: TextStyle(inherit: true, size: 12.0)');
    expect(description[3], 'headingRowColor: Instance of \'_MaterialStatePropertyWith<Color>\'');
    expect(description[4], 'headingRowHeight: 52.0');
    expect(description[5], 'headingTextStyle: TextStyle(inherit: true, size: 14.0)');
    expect(description[6], 'horizontalMargin: 3.0');
    expect(description[7], 'columnSpacing: 4.0');
    expect(description[8], 'dividerThickness: 5.0');
  });

  testWidgets('DataTable is themeable', (WidgetTester tester) async {
    final MaterialStateProperty<Color> dataRowColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => const Color(0xfffffff1),
    );
    const double dataRowHeight = 51.0;
    const TextStyle dataTextStyle = TextStyle(fontSize: 12.5);
    final MaterialStateProperty<Color> headingRowColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => const Color(0xfffffff2),
    );
    const double headingRowHeight = 52.0;
    const TextStyle headingTextStyle = TextStyle(fontSize: 14.5);
    const double horizontalMargin = 3.0;
    const double columnSpacing = 4.0;
    const double dividerThickness = 5.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          dataTableTheme: DataTableThemeData(
            dataRowColor: dataRowColor,
            dataRowHeight: dataRowHeight,
            dataTextStyle: dataTextStyle,
            headingRowColor: headingRowColor,
            headingRowHeight: headingRowHeight,
            headingTextStyle: headingTextStyle,
            horizontalMargin: horizontalMargin,
            columnSpacing: columnSpacing,
            dividerThickness: dividerThickness,
          ),
        ),
        home: Scaffold(
          body: DataTable(
            sortColumnIndex: 0,
            columns: <DataColumn>[
              DataColumn(
                label: const Text('A'),
                onSort: (int columnIndex, bool ascending) {},
              ),
              const DataColumn(label: Text('B')),
            ],
            rows: const <DataRow>[
              DataRow(cells: <DataCell>[
                DataCell(Text('Data')),
                DataCell(Text('Data 2')),
              ]),
            ],
          ),
        ),
      ),
    );

    final TextStyle dataRowTextStyle = tester.renderObject<RenderParagraph>(find.text('Data')).text.style;
    expect(dataRowTextStyle.fontSize, dataTextStyle.fontSize);
    expect(_tableRowBoxDecoration(tester: tester, index: 1).color, dataRowColor.resolve(<MaterialState>{}));
    expect(_tableRowBoxDecoration(tester: tester, index: 1).border.top.width, dividerThickness);

    final Finder dataRowContainer = find.ancestor(of: find.text('Data'), matching: find.byType(Container));
    expect(tester.getSize(dataRowContainer).height, dataRowHeight);

    final TextStyle headingRowTextStyle = tester.renderObject<RenderParagraph>(find.text('A')).text.style;
    expect(headingRowTextStyle.fontSize, headingTextStyle.fontSize);
    expect(_tableRowBoxDecoration(tester: tester, index: 0).color, headingRowColor.resolve(<MaterialState>{}));

    final Finder headingRowContainer = find.ancestor(of: find.text('A'), matching: find.byType(Container));
    expect(tester.getSize(headingRowContainer).height, headingRowHeight);
    expect(tester.getTopLeft(find.text('A')).dx, horizontalMargin);
    expect(tester.getTopLeft(find.text('Data 2')).dx - tester.getTopRight(find.text('Data')).dx, columnSpacing);
  });

  testWidgets('DataTable properties are taken over the theme values', (WidgetTester tester) async {
    final MaterialStateProperty<Color> themeDataRowColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => const Color(0xfffffff0),
    );
    const double themeDataRowHeight = 50.0;
    const TextStyle themeDataTextStyle = TextStyle(fontSize: 11.5);
    final MaterialStateProperty<Color> themeHeadingRowColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => const Color(0xfffffff1),
    );
    const double themeHeadingRowHeight = 51.0;
    const TextStyle themeHeadingTextStyle = TextStyle(fontSize: 13.5);
    const double themeHorizontalMargin = 2.0;
    const double themeColumnSpacing = 3.0;
    const double themeDividerThickness = 4.0;

    final MaterialStateProperty<Color> dataRowColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => const Color(0xfffffff1),
    );
    const double dataRowHeight = 51.0;
    const TextStyle dataTextStyle = TextStyle(fontSize: 12.5);
    final MaterialStateProperty<Color> headingRowColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => const Color(0xfffffff2),
    );
    const double headingRowHeight = 52.0;
    const TextStyle headingTextStyle = TextStyle(fontSize: 14.5);
    const double horizontalMargin = 3.0;
    const double columnSpacing = 4.0;
    const double dividerThickness = 5.0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          dataTableTheme: DataTableThemeData(
            dataRowColor: themeDataRowColor,
            dataRowHeight: themeDataRowHeight,
            dataTextStyle: themeDataTextStyle,
            headingRowColor: themeHeadingRowColor,
            headingRowHeight: themeHeadingRowHeight,
            headingTextStyle: themeHeadingTextStyle,
            horizontalMargin: themeHorizontalMargin,
            columnSpacing: themeColumnSpacing,
            dividerThickness: themeDividerThickness,
          ),
        ),
        home: Scaffold(
          body: DataTable(
            dataRowColor: dataRowColor,
            dataRowHeight: dataRowHeight,
            dataTextStyle: dataTextStyle,
            headingRowColor: headingRowColor,
            headingRowHeight: headingRowHeight,
            headingTextStyle: headingTextStyle,
            horizontalMargin: horizontalMargin,
            columnSpacing: columnSpacing,
            dividerThickness: dividerThickness,
            sortColumnIndex: 0,
            columns: <DataColumn>[
              DataColumn(
                label: const Text('A'),
                onSort: (int columnIndex, bool ascending) {},
              ),
              const DataColumn(label: Text('B')),
            ],
            rows: const <DataRow>[
              DataRow(cells: <DataCell>[
                DataCell(Text('Data')),
                DataCell(Text('Data 2')),
              ]),
            ],
          ),
        ),
      ),
    );

    final TextStyle dataRowTextStyle = tester.renderObject<RenderParagraph>(find.text('Data')).text.style;
    expect(dataRowTextStyle.fontSize, dataTextStyle.fontSize);
    expect(_tableRowBoxDecoration(tester: tester, index: 1).color, dataRowColor.resolve(<MaterialState>{}));
    expect(_tableRowBoxDecoration(tester: tester, index: 1).border.top.width, dividerThickness);

    final Finder dataRowContainer = find.ancestor(of: find.text('Data'), matching: find.byType(Container));
    expect(tester.getSize(dataRowContainer).height, dataRowHeight);

    final TextStyle headingRowTextStyle = tester.renderObject<RenderParagraph>(find.text('A')).text.style;
    expect(headingRowTextStyle.fontSize, headingTextStyle.fontSize);
    expect(_tableRowBoxDecoration(tester: tester, index: 0).color, headingRowColor.resolve(<MaterialState>{}));

    final Finder headingRowContainer = find.ancestor(of: find.text('A'), matching: find.byType(Container));
    expect(tester.getSize(headingRowContainer).height, headingRowHeight);
    expect(tester.getTopLeft(find.text('A')).dx, horizontalMargin);
    expect(tester.getTopLeft(find.text('Data 2')).dx - tester.getTopRight(find.text('Data')).dx, columnSpacing);
  });
}

BoxDecoration _tableRowBoxDecoration({WidgetTester tester, int index}) {
  final Table table = tester.widget(find.byType(Table));
  final TableRow tableRow = table.children[index];
  return tableRow.decoration as BoxDecoration;
}
