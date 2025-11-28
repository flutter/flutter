// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

RenderBox sizedBox(double width, double height) {
  return RenderConstrainedBox(additionalConstraints: BoxConstraints.tight(Size(width, height)));
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('Table control test; tight', () {
    RenderTable table;
    layout(table = RenderTable(textDirection: TextDirection.ltr));

    expect(table.size.width, equals(800.0));
    expect(table.size.height, equals(600.0));

    expect(table, hasAGoodToStringDeep);
    expect(
      table.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderTable#00000 NEEDS-PAINT\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ semantic boundary\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │ default column width: FlexColumnWidth(1.0)\n'
        ' │ table size: 0×0\n'
        ' │ column offsets: unknown\n'
        ' │ row offsets: []\n'
        ' │\n'
        ' └─table is empty\n',
      ),
    );
  });

  test('Table control test; loose', () {
    RenderTable table;
    layout(RenderPositionedBox(child: table = RenderTable(textDirection: TextDirection.ltr)));

    expect(table.size, equals(Size.zero));
  });

  test('Table control test: constrained flex columns', () {
    final table = RenderTable(textDirection: TextDirection.ltr);
    final children = List<RenderBox>.generate(6, (_) => RenderPositionedBox());

    table.setFlatChildren(6, children);
    layout(table, constraints: const BoxConstraints.tightFor(width: 100.0));

    const double expectedWidth = 100.0 / 6;
    for (final child in children) {
      expect(child.size.width, moreOrLessEquals(expectedWidth));
    }
  });

  test('Table test: combinations', () {
    RenderTable table;
    layout(
      RenderPositionedBox(
        child: table = RenderTable(
          columns: 5,
          rows: 5,
          defaultColumnWidth: const IntrinsicColumnWidth(),
          textDirection: TextDirection.ltr,
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
        ),
      ),
    );

    expect(table.size, equals(Size.zero));

    table.setChild(2, 4, sizedBox(100.0, 200.0));

    pumpFrame();

    expect(table.size, equals(const Size(100.0, 200.0)));

    table.setChild(0, 0, sizedBox(10.0, 30.0));
    table.setChild(1, 0, sizedBox(20.0, 20.0));
    table.setChild(2, 0, sizedBox(30.0, 10.0));

    pumpFrame();

    expect(table.size, equals(const Size(130.0, 230.0)));

    expect(table, hasAGoodToStringDeep);
    expect(
      table.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderTable#00000 relayoutBoundary=up1 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE\n'
        ' │ parentData: offset=Offset(335.0, 185.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
        ' │ semantic boundary\n'
        ' │ size: Size(130.0, 230.0)\n'
        ' │ default column width: IntrinsicColumnWidth(flex: null)\n'
        ' │ table size: 5×5\n'
        ' │ column offsets: 0.0, 10.0, 30.0, 130.0, 130.0\n'
        ' │ row offsets: 0.0, 30.0, 30.0, 30.0, 30.0, 230.0\n'
        ' │\n'
        ' ├─child (0, 0): RenderConstrainedBox#00000 relayoutBoundary=up2 NEEDS-PAINT\n'
        ' │   parentData: offset=Offset(0.0, 0.0); default vertical alignment\n'
        ' │     (can use size)\n'
        ' │   constraints: BoxConstraints(w=10.0, 0.0<=h<=Infinity)\n'
        ' │   size: Size(10.0, 30.0)\n'
        ' │   additionalConstraints: BoxConstraints(w=10.0, h=30.0)\n'
        ' │\n'
        ' ├─child (1, 0): RenderConstrainedBox#00000 relayoutBoundary=up2 NEEDS-PAINT\n'
        ' │   parentData: offset=Offset(10.0, 0.0); default vertical alignment\n'
        ' │     (can use size)\n'
        ' │   constraints: BoxConstraints(w=20.0, 0.0<=h<=Infinity)\n'
        ' │   size: Size(20.0, 20.0)\n'
        ' │   additionalConstraints: BoxConstraints(w=20.0, h=20.0)\n'
        ' │\n'
        ' ├─child (2, 0): RenderConstrainedBox#00000 relayoutBoundary=up2 NEEDS-PAINT\n'
        ' │   parentData: offset=Offset(30.0, 0.0); default vertical alignment\n'
        ' │     (can use size)\n'
        ' │   constraints: BoxConstraints(w=100.0, 0.0<=h<=Infinity)\n'
        ' │   size: Size(100.0, 10.0)\n'
        ' │   additionalConstraints: BoxConstraints(w=30.0, h=10.0)\n'
        ' │\n'
        ' ├─child (3, 0) is null\n'
        ' ├─child (4, 0) is null\n'
        ' ├─child (0, 1) is null\n'
        ' ├─child (1, 1) is null\n'
        ' ├─child (2, 1) is null\n'
        ' ├─child (3, 1) is null\n'
        ' ├─child (4, 1) is null\n'
        ' ├─child (0, 2) is null\n'
        ' ├─child (1, 2) is null\n'
        ' ├─child (2, 2) is null\n'
        ' ├─child (3, 2) is null\n'
        ' ├─child (4, 2) is null\n'
        ' ├─child (0, 3) is null\n'
        ' ├─child (1, 3) is null\n'
        ' ├─child (2, 3) is null\n'
        ' ├─child (3, 3) is null\n'
        ' ├─child (4, 3) is null\n'
        ' ├─child (0, 4) is null\n'
        ' ├─child (1, 4) is null\n'
        ' ├─child (2, 4): RenderConstrainedBox#00000 relayoutBoundary=up2 NEEDS-PAINT\n'
        ' │   parentData: offset=Offset(30.0, 30.0); default vertical alignment\n'
        ' │     (can use size)\n'
        ' │   constraints: BoxConstraints(w=100.0, 0.0<=h<=Infinity)\n'
        ' │   size: Size(100.0, 200.0)\n'
        ' │   additionalConstraints: BoxConstraints(w=100.0, h=200.0)\n'
        ' │\n'
        ' ├─child (3, 4) is null\n'
        ' └─child (4, 4) is null\n',
      ),
    );
  });

  test('Table test: removing cells', () {
    RenderTable table;
    RenderBox child;
    table = RenderTable(columns: 5, rows: 5, textDirection: TextDirection.ltr);
    table.setChild(4, 4, child = sizedBox(10.0, 10.0));

    layout(table);

    expect(child.attached, isTrue);
    table.rows = 4;
    expect(child.attached, isFalse);
  });

  test('Table test: replacing cells', () {
    RenderTable table;
    final RenderBox child1 = RenderPositionedBox();
    final RenderBox child2 = RenderPositionedBox();
    final RenderBox child3 = RenderPositionedBox();
    table = RenderTable(textDirection: TextDirection.ltr);
    table.setFlatChildren(3, <RenderBox>[
      child1,
      RenderPositionedBox(),
      child2,
      RenderPositionedBox(),
      child3,
      RenderPositionedBox(),
    ]);
    expect(table.rows, equals(2));
    layout(table);
    table.setFlatChildren(3, <RenderBox>[
      RenderPositionedBox(),
      child1,
      RenderPositionedBox(),
      child2,
      RenderPositionedBox(),
      child3,
    ]);
    pumpFrame();
    table.setFlatChildren(3, <RenderBox>[
      RenderPositionedBox(),
      child1,
      RenderPositionedBox(),
      child2,
      RenderPositionedBox(),
      child3,
    ]);
    pumpFrame();
    expect(table.columns, equals(3));
    expect(table.rows, equals(2));
  });

  test('Table border painting', () {
    final table = RenderTable(textDirection: TextDirection.rtl, border: TableBorder.all());
    layout(table);
    table.setFlatChildren(1, <RenderBox>[]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..path()
        ..path(),
    );
    table.setFlatChildren(1, <RenderBox>[RenderPositionedBox()]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..path()
        ..path(),
    );
    table.setFlatChildren(1, <RenderBox>[RenderPositionedBox(), RenderPositionedBox()]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..path()
        ..path()
        ..path(),
    );
    table.setFlatChildren(2, <RenderBox>[RenderPositionedBox(), RenderPositionedBox()]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..path()
        ..path()
        ..path(),
    );
    table.setFlatChildren(2, <RenderBox>[
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
    ]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..path()
        ..path()
        ..path()
        ..path(),
    );
    table.setFlatChildren(3, <RenderBox>[
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
    ]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..path()
        ..path()
        ..path()
        ..path(),
    );
  });

  test('Table flex sizing', () {
    const cellConstraints = BoxConstraints.tightFor(width: 100, height: 100);
    final table = RenderTable(
      textDirection: TextDirection.rtl,
      children: <List<RenderBox>>[
        List<RenderBox>.generate(
          7,
          (int _) => RenderConstrainedBox(additionalConstraints: cellConstraints),
        ),
      ],
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(0.123),
        2: FlexColumnWidth(0.123),
        3: FlexColumnWidth(0.123),
        4: FlexColumnWidth(0.123),
        5: FlexColumnWidth(0.123),
        6: FlexColumnWidth(0.123),
      },
    );

    layout(table, constraints: BoxConstraints.tight(const Size(800.0, 600.0)));
    expect(table.hasSize, true);
  });

  test('Table paints a borderRadius', () {
    final table = RenderTable(
      textDirection: TextDirection.ltr,
      border: TableBorder.all(borderRadius: const BorderRadius.all(Radius.circular(8.0))),
    );
    layout(table);
    table.setFlatChildren(2, <RenderBox>[
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
      RenderPositionedBox(),
    ]);
    pumpFrame();
    expect(
      table,
      paints
        ..path()
        ..path()
        ..drrect(
          outer: RRect.fromLTRBR(0.0, 0.0, 800.0, 0.0, const Radius.circular(8.0)),
          inner: RRect.fromLTRBR(1.0, 1.0, 799.0, -1.0, const Radius.circular(7.0)),
        ),
    );
  });

  test('MaxColumnWidth.flex returns the correct result', () {
    var columnWidth = const MaxColumnWidth(
      FixedColumnWidth(100), // returns null from .flex
      FlexColumnWidth(), // returns 1 from .flex
    );
    final double? flexValue = columnWidth.flex(<RenderBox>[]);
    expect(flexValue, 1.0);

    // Swap a and b, check for same result.
    columnWidth = const MaxColumnWidth(
      FlexColumnWidth(), // returns 1 from .flex
      FixedColumnWidth(100), // returns null from .flex
    );
    // Same result.
    expect(columnWidth.flex(<RenderBox>[]), flexValue);
  });

  test('MinColumnWidth.flex returns the correct result', () {
    var columnWidth = const MinColumnWidth(
      FixedColumnWidth(100), // returns null from .flex
      FlexColumnWidth(), // returns 1 from .flex
    );
    final double? flexValue = columnWidth.flex(<RenderBox>[]);
    expect(flexValue, 1.0);

    // Swap a and b, check for same result.
    columnWidth = const MinColumnWidth(
      FlexColumnWidth(), // returns 1 from .flex
      FixedColumnWidth(100), // returns null from .flex
    );
    // Same result.
    expect(columnWidth.flex(<RenderBox>[]), flexValue);
  });

  test('TableRows with different constraints, but vertically with intrinsicHeight', () {
    const firstConstraints = BoxConstraints.tightFor(width: 100, height: 100);
    const secondConstraints = BoxConstraints.tightFor(width: 200, height: 200);

    final table = RenderTable(
      textDirection: TextDirection.rtl,
      defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      children: <List<RenderBox>>[
        <RenderBox>[
          RenderConstrainedBox(additionalConstraints: firstConstraints),
          RenderConstrainedBox(additionalConstraints: secondConstraints),
        ],
      ],
      columnWidths: const <int, TableColumnWidth>{0: FlexColumnWidth(), 1: FlexColumnWidth()},
    );

    const size = Size(300.0, 300.0);

    // Layout the table with a fixed size.
    layout(table, constraints: BoxConstraints.tight(size));

    // Make sure the table has a size and that the children are filled vertically to the highest cell.
    expect(table.size, equals(size));
    expect(table.defaultVerticalAlignment, TableCellVerticalAlignment.intrinsicHeight);
  });

  group('RenderTable colSpan and rowSpan tests', () {
    RenderBox constrainedBox([BoxConstraints constraints = const BoxConstraints()]) {
      return RenderConstrainedBox(additionalConstraints: constraints);
    }

    test('TableCellParentData default colSpan and rowSpan', () {
      final TableCellParentData parentData = TableCellParentData();
      expect(parentData.colSpan, equals(1));
      expect(parentData.rowSpan, equals(1));
    });

    test('TableCellParentData custom colSpan and rowSpan', () {
      final TableCellParentData parentData = TableCellParentData()
        ..colSpan = 3
        ..rowSpan = 2;
      expect(parentData.colSpan, equals(3));
      expect(parentData.rowSpan, equals(2));
    });

    test('TableCellParentData toString includes colSpan and rowSpan', () {
      final TableCellParentData parentData = TableCellParentData()
        ..colSpan = 2
        ..rowSpan = 3;
      final String description = parentData.toString();
      expect(description, contains('2 cols'));
      expect(description, contains('3 rows'));

      // Test default case (should not show cols/rows when they are 1)
      final TableCellParentData defaultParentData = TableCellParentData();
      final String defaultDescription = defaultParentData.toString();
      expect(defaultDescription, isNot(contains('cols')));
      expect(defaultDescription, isNot(contains('rows')));
    });

    test('RenderTable correctly distributes column widths when using colSpan', () {
      final RenderTable table = RenderTable(
        textDirection: TextDirection.ltr,
        columns: 3,
        rows: 1,
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
      );

      final RenderBox spanningCell = constrainedBox();
      final RenderBox regularCell = constrainedBox();

      // Set up colSpan
      final TableCellParentData spanningCellParentData = TableCellParentData()..colSpan = 2;
      spanningCell.parentData = spanningCellParentData;

      table.setChild(0, 0, spanningCell); // spans columns 0 and 1
      table.setChild(2, 0, regularCell); // column 2

      layout(table, constraints: const BoxConstraints.tightFor(width: 300.0));

      // With 3 equal flex columns and 300.0 total width, each column should
      // be 100.0 wide. The spanning cell spans 2 columns, so it should be
      // 200.0 wide.
      expect(spanningCell.size.width, equals(200.0));
      expect(regularCell.size.width, equals(100.0));
      expect(spanningCellParentData.colSpan, equals(2));
    });

    test('RenderTable correctly merges row heights when using rowSpan', () {
      final RenderTable table = RenderTable(textDirection: TextDirection.ltr, columns: 2, rows: 2);

      final RenderBox spanningCell = constrainedBox(
        const BoxConstraints(minHeight: 200, maxHeight: 200),
      );
      final RenderBox regularCell1 = constrainedBox(
        const BoxConstraints(minHeight: 150, maxHeight: 150),
      );
      final RenderBox regularCell2 = constrainedBox(
        const BoxConstraints(minHeight: 50, maxHeight: 50),
      );

      // Set up rowSpan - spanning cell should span rows 0 and 1
      final TableCellParentData spanningCellParentData = TableCellParentData()..rowSpan = 2;
      spanningCell.parentData = spanningCellParentData;

      table.setChild(0, 0, spanningCell); // column 0, row 0 - spans to row 1
      table.setChild(1, 0, regularCell1); // column 1, row 0
      table.setChild(1, 1, regularCell2); // column 1, row 1

      layout(table, constraints: const BoxConstraints.tightFor(width: 300.0));

      expect(spanningCellParentData.rowSpan, equals(2));

      expect(regularCell1.size.height, equals(150.0));
      expect(regularCell2.size.height, equals(50.0));

      // The table height should be determined by the spanning cell that takes up both rows
      expect(table.size.height, equals(200.0));
    });

    test('RenderTable correctly handles cells spanning multiple rows and columns', () {
      final RenderTable table = RenderTable(
        textDirection: TextDirection.ltr,
        columns: 3,
        rows: 3,
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
      );

      final RenderBox spanningCell = constrainedBox(
        const BoxConstraints(minHeight: 200, maxHeight: 200),
      );
      final RenderBox regularCell1 = constrainedBox(
        const BoxConstraints(minHeight: 80, maxHeight: 80),
      );
      final RenderBox regularCell2 = constrainedBox(
        const BoxConstraints(minHeight: 120, maxHeight: 120),
      );
      final RenderBox regularCell3 = constrainedBox(
        const BoxConstraints(minHeight: 60, maxHeight: 60),
      );

      // Set up colSpan and rowSpan - spanning cell spans 2 columns and 2 rows
      final TableCellParentData spanningCellParentData = TableCellParentData()
        ..colSpan = 2
        ..rowSpan = 2;
      spanningCell.parentData = spanningCellParentData;

      table.setChild(0, 0, spanningCell); // column 0-1, row 0-1 (spans 2x2)
      table.setChild(2, 0, regularCell1); // column 2, row 0
      table.setChild(2, 1, regularCell2); // column 2, row 1
      table.setChild(0, 2, regularCell3); // column 0, row 2

      layout(table, constraints: const BoxConstraints.tightFor(width: 300.0));

      expect(spanningCellParentData.colSpan, equals(2));
      expect(spanningCellParentData.rowSpan, equals(2));

      // With 3 equal flex columns and 300.0 total width, each column should
      // be 100.0 wide. The spanning cell spans 2 columns, so it should be
      // 200.0 wide.
      expect(spanningCell.size.width, equals(200.0));
      expect(regularCell1.size.width, equals(100.0));
      expect(regularCell2.size.width, equals(100.0));
      expect(regularCell3.size.width, equals(100.0));

      // Height checks
      expect(regularCell1.size.height, equals(80.0));
      expect(regularCell2.size.height, equals(120.0));
      expect(regularCell3.size.height, equals(60.0));

      // The spanning cell should have its preferred height
      expect(spanningCell.size.height, equals(200.0));
    });

    group('TableCellVerticalAlignment works correctly with colSpan and rowSpan', () {
      const double spannedCellHeight = 50.0;
      const double regularCellHeight = 80.0;
      const double tableWidth = 300.0;

      // Helper to create a fixed-size RenderBox
      RenderBox createBox(double height) {
        return RenderConstrainedBox(additionalConstraints: BoxConstraints.tightFor(height: height));
      }

      // Helper to setup the table structure
      // Layout:
      // Row 0: | RowSpan 0-1 | ColSpan 1-2         |
      // Row 1: |             | Reg 1       | Reg 2 |
      (RenderTable, RenderBox, RenderBox) setupTable(TableCellVerticalAlignment alignment) {
        final RenderTable table = RenderTable(
          textDirection: TextDirection.ltr,
          columns: 3,
          rows: 2,
        );

        final RenderBox rowSpanningCell = createBox(spannedCellHeight);
        final RenderBox colSpanningCell = createBox(spannedCellHeight);
        final RenderBox regularCell1 = createBox(regularCellHeight);
        final RenderBox regularCell2 = createBox(regularCellHeight);

        // Setup Row Spanning Cell (Col 0, Rows 0-1)
        rowSpanningCell.parentData = TableCellParentData()
          ..rowSpan = 2
          ..verticalAlignment = alignment;
        table.setChild(0, 0, rowSpanningCell);

        // Setup Column Spanning Cell (Col 1-2, Row 0)
        colSpanningCell.parentData = TableCellParentData()
          ..colSpan = 2
          ..verticalAlignment = alignment;
        table.setChild(1, 0, colSpanningCell);

        // Setup Regular Cells (Row 1)
        table.setChild(1, 1, regularCell1);
        table.setChild(2, 1, regularCell2);

        table.layout(const BoxConstraints.tightFor(width: tableWidth));

        return (table, rowSpanningCell, colSpanningCell);
      }

      test('Common constraints and dimensions', () {
        final (RenderTable table, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.top,
        );

        // Column width logic: 300 width / 3 columns = 100 per column
        expect(rowSpanCell.size.width, equals(100.0), reason: 'Spans 1 column');
        expect(colSpanCell.size.width, equals(200.0), reason: 'Spans 2 columns');

        final TableCellParentData rowData = rowSpanCell.parentData! as TableCellParentData;
        final TableCellParentData colData = colSpanCell.parentData! as TableCellParentData;

        expect(rowData.rowSpan, equals(2));
        expect(colData.colSpan, equals(2));
      });

      test('Alignment: Fill', () {
        final (RenderTable table, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.fill,
        );

        // In Fill, the cell expands to match the row(s) height.
        // Row 1 is driven by regularCell (80.0).
        // Row 0 matches the intrinsic height of the content or the span.
        // Total Table Height = Row 0 Height + Row 1 Height.

        expect(
          rowSpanCell.size.height,
          equals(table.size.height),
          reason: 'RowSpan should fill total table height',
        );

        expect(
          colSpanCell.size.height,
          equals(table.size.height - regularCellHeight),
          reason: 'ColSpan should fill Row 0 (Total - Row 1)',
        );
      });

      test('Alignment: IntrinsicHeight', () {
        final (RenderTable table, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.intrinsicHeight,
        );

        expect(colSpanCell.size.height, equals(spannedCellHeight));
        expect(rowSpanCell.size.height, equals(table.size.height));
      });

      test('Alignment: Top', () {
        final (_, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.top,
        );

        expect(rowSpanCell.size.height, equals(spannedCellHeight));
        expect(colSpanCell.size.height, equals(spannedCellHeight));

        final TableCellParentData rowData = rowSpanCell.parentData! as TableCellParentData;
        final TableCellParentData colData = colSpanCell.parentData! as TableCellParentData;

        expect(rowData.offset.dy, equals(0.0), reason: 'Should start at top of table');
        expect(colData.offset.dy, equals(0.0), reason: 'Should start at top of Row 0');
      });

      test('Alignment: Middle', () {
        final (RenderTable table, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.middle,
        );

        expect(rowSpanCell.size.height, equals(spannedCellHeight));
        expect(colSpanCell.size.height, equals(spannedCellHeight));

        final TableCellParentData rowData = rowSpanCell.parentData! as TableCellParentData;
        final TableCellParentData colData = colSpanCell.parentData! as TableCellParentData;

        // Available space calculations
        final double totalTableHeight = table.size.height;
        final double row0Height = totalTableHeight - regularCellHeight;

        // Math: (AvailableSpace - CellSize) / 2
        expect(rowData.offset.dy, (totalTableHeight - spannedCellHeight) / 2);
        expect(colData.offset.dy, (row0Height - spannedCellHeight) / 2);
      });

      test('Alignment: Bottom', () {
        final (RenderTable table, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.bottom,
        );

        expect(rowSpanCell.size.height, equals(spannedCellHeight));
        expect(colSpanCell.size.height, equals(spannedCellHeight));

        final TableCellParentData rowData = rowSpanCell.parentData! as TableCellParentData;
        final TableCellParentData colData = colSpanCell.parentData! as TableCellParentData;

        final double totalTableHeight = table.size.height;
        final double row0Height = totalTableHeight - regularCellHeight;

        // Math: AvailableSpace - CellSize
        expect(rowData.offset.dy, totalTableHeight - spannedCellHeight);
        expect(colData.offset.dy, row0Height - spannedCellHeight);
      });

      test('Alignment: Baseline', () {
        final RenderTable table = RenderTable(
          textDirection: TextDirection.ltr,
          columns: 3,
          rows: 2,
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
        );

        // Create RenderParagraph cells with different font sizes
        final RenderParagraph rowSpanningCell = RenderParagraph(
          const TextSpan(text: 'RowSpan', style: TextStyle(fontSize: 20)),
          textDirection: TextDirection.ltr,
        );
        final RenderParagraph colSpanningCell = RenderParagraph(
          const TextSpan(text: 'ColSpan', style: TextStyle(fontSize: 40)),
          textDirection: TextDirection.ltr,
        );
        final RenderParagraph regularCell1 = RenderParagraph(
          const TextSpan(text: 'Reg1', style: TextStyle(fontSize: 12)),
          textDirection: TextDirection.ltr,
        );
        final RenderParagraph regularCell2 = RenderParagraph(
          const TextSpan(text: 'Reg2', style: TextStyle(fontSize: 12)),
          textDirection: TextDirection.ltr,
        );

        // Setup Row Spanning Cell (Col 0, Rows 0-1)
        rowSpanningCell.parentData = TableCellParentData()
          ..rowSpan = 2
          ..verticalAlignment = TableCellVerticalAlignment.baseline;
        table.setChild(0, 0, rowSpanningCell);

        // Setup Column Spanning Cell (Col 1-2, Row 0)
        colSpanningCell.parentData = TableCellParentData()
          ..colSpan = 2
          ..verticalAlignment = TableCellVerticalAlignment.baseline;
        table.setChild(1, 0, colSpanningCell);

        // Setup Regular Cells (Row 1) - need baseline alignment too
        regularCell1.parentData = TableCellParentData()
          ..verticalAlignment = TableCellVerticalAlignment.baseline;
        regularCell2.parentData = TableCellParentData()
          ..verticalAlignment = TableCellVerticalAlignment.baseline;
        table.setChild(1, 1, regularCell1);
        table.setChild(2, 1, regularCell2);

        // Use the layout helper from rendering_tester.dart
        layout(table, constraints: const BoxConstraints.tightFor(width: tableWidth));

        final TableCellParentData rowData = rowSpanningCell.parentData! as TableCellParentData;
        final TableCellParentData colData = colSpanningCell.parentData! as TableCellParentData;
        final TableCellParentData reg1Data = regularCell1.parentData! as TableCellParentData;
        final TableCellParentData reg2Data = regularCell2.parentData! as TableCellParentData;

        // For baseline alignment, cells in the same row should align at their baselines
        // The larger font (ColSpan 40px) will be positioned higher, smaller font (RowSpan 20px) lower
        // so that their baselines match

        // Both cells in row 0 should have aligned baselines
        // The cell with larger font should start higher (smaller offset.dy)
        // so its baseline matches the cell with smaller font
        expect(colData.offset.dy, lessThan(rowData.offset.dy));

        // For row 1, cells with same font size should have same offset
        expect(reg1Data.offset.dy, equals(reg2Data.offset.dy));
      });
    });
  });
}
