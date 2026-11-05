// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui show Image;

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
      final parentData = TableCellParentData();
      expect(parentData.colSpan, equals(1));
      expect(parentData.rowSpan, equals(1));
    });

    test('TableCellParentData custom colSpan and rowSpan', () {
      final parentData = TableCellParentData()
        ..colSpan = 3
        ..rowSpan = 2;
      expect(parentData.colSpan, equals(3));
      expect(parentData.rowSpan, equals(2));
    });

    test('TableCellParentData toString includes colSpan and rowSpan', () {
      final parentData = TableCellParentData()
        ..colSpan = 2
        ..rowSpan = 3;
      final description = parentData.toString();
      expect(description, contains('2 cols'));
      expect(description, contains('3 rows'));

      // Test default case (should not show cols/rows when they are 1)
      final defaultParentData = TableCellParentData();
      final defaultDescription = defaultParentData.toString();
      expect(defaultDescription, isNot(contains('cols')));
      expect(defaultDescription, isNot(contains('rows')));
      expect(defaultDescription, isNot(contains('hidden')));

      // A placeholder.
      final hiddenParentData = TableCellParentData()
        ..colSpan = 0
        ..rowSpan = 0;
      expect(hiddenParentData.toString(), contains('hidden'));
    });

    test('colSpan and rowSpan must both be 0 or both be at least 1', () {
      final table = RenderTable(textDirection: TextDirection.ltr, columns: 1, rows: 1);
      table.setChild(
        0,
        0,
        sizedBox(100.0, 50.0)
          ..parentData = (TableCellParentData()
            ..colSpan = 0
            ..rowSpan = 1),
      );

      final errors = <FlutterErrorDetails>[];
      layout(
        table,
        onErrors: () {
          errors.addAll(TestRenderingFlutterBinding.instance.takeAllFlutterErrorDetails());
        },
      );
      expect(errors, isNotEmpty);
      expect(
        errors.first.exception.toString(),
        contains('colSpan and rowSpan must either both be 0'),
      );
    });

    test('RenderTable correctly distributes column widths when using colSpan', () {
      final table = RenderTable(
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
      final spanningCellParentData = TableCellParentData()..colSpan = 2;
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
      final table = RenderTable(textDirection: TextDirection.ltr, columns: 2, rows: 2);

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
      final spanningCellParentData = TableCellParentData()..rowSpan = 2;
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
      final table = RenderTable(
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
      final spanningCellParentData = TableCellParentData()
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

    test('a cell that turns into a placeholder is neither painted nor hit tested', () {
      // Placeholders are never laid out, so a cell that turns into one keeps
      // the size and offset from its last layout. Paint and hit testing must
      // still skip it.
      const leadColor = Color(0xFF00FF00);
      const coveredColor = Color(0xFFFF0000);
      RenderBox coloredCell(Color color) {
        return RenderDecoratedBox(
          decoration: BoxDecoration(color: color),
          child: constrainedBox(const BoxConstraints.tightFor(height: 50.0)),
        );
      }

      final table = RenderTable(textDirection: TextDirection.ltr, columns: 2, rows: 1);
      final RenderBox lead = coloredCell(leadColor);
      final RenderBox covered = coloredCell(coveredColor);
      table.setChild(0, 0, lead);
      table.setChild(1, 0, covered);
      layout(table, constraints: const BoxConstraints.tightFor(width: 200.0));

      // The lead cell now spans both columns, which turns the second cell into
      // a placeholder.
      (lead.parentData! as TableCellParentData).colSpan = 2;
      (covered.parentData! as TableCellParentData)
        ..colSpan = 0
        ..rowSpan = 0;
      table.markNeedsLayout();
      pumpFrame();
      expect(covered.hasSize, isTrue);

      final result = BoxHitTestResult();
      table.hitTest(result, position: const Offset(150.0, 25.0));
      expect(result.path.first.target, same(lead));

      expect(table, paints..rect(color: leadColor));
      expect(table, isNot(paints..rect(color: coveredColor)));
    });

    group('TableCellVerticalAlignment works correctly with colSpan and rowSpan', () {
      const spannedCellHeight = 50.0;
      const regularCellHeight = 80.0;
      const tableWidth = 300.0;

      // Helper to create a fixed-size RenderBox
      RenderBox createBox(double height) {
        return RenderConstrainedBox(additionalConstraints: BoxConstraints.tightFor(height: height));
      }

      // Helper to setup the table structure
      // Layout:
      // Row 0: | RowSpan 0-1 | ColSpan 1-2         |
      // Row 1: |             | Reg 1       | Reg 2 |
      (RenderTable, RenderBox, RenderBox) setupTable(TableCellVerticalAlignment alignment) {
        final table = RenderTable(textDirection: TextDirection.ltr, columns: 3, rows: 2);

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

        final rowData = rowSpanCell.parentData! as TableCellParentData;
        final colData = colSpanCell.parentData! as TableCellParentData;

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

        final rowData = rowSpanCell.parentData! as TableCellParentData;
        final colData = colSpanCell.parentData! as TableCellParentData;

        expect(rowData.offset.dy, equals(0.0), reason: 'Should start at top of table');
        expect(colData.offset.dy, equals(0.0), reason: 'Should start at top of Row 0');
      });

      test('Alignment: Middle', () {
        final (RenderTable table, RenderBox rowSpanCell, RenderBox colSpanCell) = setupTable(
          TableCellVerticalAlignment.middle,
        );

        expect(rowSpanCell.size.height, equals(spannedCellHeight));
        expect(colSpanCell.size.height, equals(spannedCellHeight));

        final rowData = rowSpanCell.parentData! as TableCellParentData;
        final colData = colSpanCell.parentData! as TableCellParentData;

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

        final rowData = rowSpanCell.parentData! as TableCellParentData;
        final colData = colSpanCell.parentData! as TableCellParentData;

        final double totalTableHeight = table.size.height;
        final double row0Height = totalTableHeight - regularCellHeight;

        // Math: AvailableSpace - CellSize
        expect(rowData.offset.dy, totalTableHeight - spannedCellHeight);
        expect(colData.offset.dy, row0Height - spannedCellHeight);
      });

      test('Alignment: Baseline', () {
        final table = RenderTable(
          textDirection: TextDirection.ltr,
          columns: 3,
          rows: 2,
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
        );

        // Create RenderParagraph cells with different font sizes
        final rowSpanningCell = RenderParagraph(
          const TextSpan(text: 'RowSpan', style: TextStyle(fontSize: 20)),
          textDirection: TextDirection.ltr,
        );
        final colSpanningCell = RenderParagraph(
          const TextSpan(text: 'ColSpan', style: TextStyle(fontSize: 40)),
          textDirection: TextDirection.ltr,
        );
        final regularCell1 = RenderParagraph(
          const TextSpan(text: 'Reg1', style: TextStyle(fontSize: 12)),
          textDirection: TextDirection.ltr,
        );
        final regularCell2 = RenderParagraph(
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

        final rowData = rowSpanningCell.parentData! as TableCellParentData;
        final colData = colSpanningCell.parentData! as TableCellParentData;
        final reg1Data = regularCell1.parentData! as TableCellParentData;
        final reg2Data = regularCell2.parentData! as TableCellParentData;

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

      test('Baseline: a cell without a baseline is top-aligned', () {
        // Regression test: in a baseline-aligned row, a cell whose child has no
        // baseline must be top-aligned (matching the first layout pass), not
        // pushed down by the row's baseline distance.
        final table = RenderTable(
          textDirection: TextDirection.ltr,
          columns: 2,
          rows: 1,
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
        );

        // A tall text cell defines a non-zero baseline distance for the row.
        final textCell = RenderParagraph(
          const TextSpan(text: 'Text', style: TextStyle(fontSize: 40)),
          textDirection: TextDirection.ltr,
        );
        textCell.parentData = TableCellParentData()
          ..verticalAlignment = TableCellVerticalAlignment.baseline;
        // A plain box has no baseline.
        final RenderBox boxCell = sizedBox(50.0, 30.0);
        boxCell.parentData = TableCellParentData()
          ..verticalAlignment = TableCellVerticalAlignment.baseline;

        table.setChild(0, 0, textCell);
        table.setChild(1, 0, boxCell);

        layout(table, constraints: const BoxConstraints.tightFor(width: 200.0));

        // Row 0 starts at y = 0, so top-aligned means offset.dy == 0. Before the
        // fix this was rowTop + beforeBaselineDistance (> 0).
        final boxData = boxCell.parentData! as TableCellParentData;
        expect(boxData.offset.dy, 0.0);
      });

      test('Baseline: the dry baseline measures a colSpan against its whole span', () {
        final table = RenderTable(
          textDirection: TextDirection.ltr,
          columns: 2,
          rows: 1,
          defaultColumnWidth: const FixedColumnWidth(100.0),
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
        );
        final spanningCell = _WidthBaselineBox(0.5);
        spanningCell.parentData = TableCellParentData()..colSpan = 2;
        table.setChild(0, 0, spanningCell);
        // The placeholder has a baseline of its own, which must not count.
        final placeholder = _WidthBaselineBox(2.0);
        placeholder.parentData = TableCellParentData()
          ..colSpan = 0
          ..rowSpan = 0;
        table.setChild(1, 0, placeholder);

        // The spanning cell is 200 pixels wide, so its baseline is at 100.
        const constraints = BoxConstraints(maxWidth: 400.0);
        expect(table.getDryBaseline(constraints, TextBaseline.alphabetic), 100.0);

        // The same as the baseline after layout: RenderBaseline moves the table
        // down so that its baseline is at 150.
        layout(
          RenderBaseline(baseline: 150.0, baselineType: TextBaseline.alphabetic, child: table),
          constraints: constraints,
        );
        expect((table.parentData! as BoxParentData).offset.dy, 50.0);
      });

      test('Baseline: a row sized by baseline cells counts toward a rowSpan', () {
        // A rowSpan cell only adds the height that the rows it covers do not
        // already provide. A row whose height comes from baseline-aligned cells
        // must count toward that too, or the last row of the span grows by the
        // height of the baseline row.
        final table = RenderTable(
          textDirection: TextDirection.ltr,
          columns: 2,
          rows: 2,
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
        );

        final RenderBox spanningCell = sizedBox(50.0, 100.0);
        spanningCell.parentData = TableCellParentData()
          ..rowSpan = 2
          ..verticalAlignment = TableCellVerticalAlignment.top;
        table.setChild(0, 0, spanningCell);

        // In the test font, a 20 pixel line is 20 pixels tall.
        RenderBox textCell() {
          return RenderParagraph(
            const TextSpan(text: 'Text', style: TextStyle(fontSize: 20.0)),
            textDirection: TextDirection.ltr,
          );
        }

        table.setChild(1, 0, textCell());
        table.setChild(1, 1, textCell());

        layout(table, constraints: const BoxConstraints.tightFor(width: 200.0));

        expect(table.getRowBox(0).height, 20.0);
        expect(table.getRowBox(1).height, 80.0);
        expect(table.size.height, 100.0);
        expect(table.getMinIntrinsicHeight(200.0), table.size.height);
      });
    });
  });

  test('Empty table intrinsic dimensions should not crash', () {
    // Test that empty tables (0 rows x 0 columns) don't cause division by zero
    // when intrinsic size methods are called with non-zero constraints.
    final table = RenderTable(textDirection: TextDirection.ltr);

    // Verify table is empty
    expect(table.rows, equals(0));
    expect(table.columns, equals(0));

    // These should all return 0.0 without crashing (previously caused division by zero)
    expect(table.getMinIntrinsicWidth(100.0), equals(0.0));
    expect(table.getMaxIntrinsicWidth(100.0), equals(0.0));
    expect(table.getMinIntrinsicHeight(100.0), equals(0.0));
    expect(table.getMaxIntrinsicHeight(100.0), equals(0.0));

    // Also test with infinite constraints
    expect(table.getMinIntrinsicWidth(double.infinity), equals(0.0));
    expect(table.getMaxIntrinsicWidth(double.infinity), equals(0.0));
    expect(table.getMinIntrinsicHeight(double.infinity), equals(0.0));
    expect(table.getMaxIntrinsicHeight(double.infinity), equals(0.0));
  });

  group('Intrinsic dimensions with colSpan and rowSpan', () {
    test('rowSpan does not add its height to the row it starts in', () {
      // Row 0: | RowSpan 0-1 (300 tall) | Reg (20 tall) |
      // Row 1: |                        | Reg (20 tall) |
      //
      // The spanning cell covers both rows, so the table only needs to be 300
      // tall. Measuring it as part of row 0 alone would report 320.
      final table = RenderTable(textDirection: TextDirection.ltr, columns: 2, rows: 2);

      final RenderBox spanningCell = sizedBox(50.0, 300.0);
      spanningCell.parentData = TableCellParentData()..rowSpan = 2;
      table.setChild(0, 0, spanningCell);
      table.setChild(1, 0, sizedBox(50.0, 20.0));
      table.setChild(1, 1, sizedBox(50.0, 20.0));

      expect(table.getMinIntrinsicHeight(100.0), equals(300.0));
      expect(table.getMaxIntrinsicHeight(100.0), equals(300.0));

      // The intrinsic height agrees with the height the table lays out to.
      layout(table, constraints: const BoxConstraints(maxWidth: 100.0));
      expect(table.size.height, equals(300.0));
    });

    test('rowSpan cells that start in different rows and end in the same row', () {
      // (0, 0) spans all three rows and (1, 1) the last two. Row 1 has no cell
      // of its own, so the last row has to make room for both: (0, 0) needs
      // 100 from the top of the table, (1, 1) needs 70 from the top of row 1.
      final table = RenderTable(
        textDirection: TextDirection.ltr,
        columns: 2,
        rows: 3,
        defaultColumnWidth: const FixedColumnWidth(100.0),
      );
      final RenderBox tall = sizedBox(100.0, 100.0);
      tall.parentData = TableCellParentData()..rowSpan = 3;
      table.setChild(0, 0, tall);
      table.setChild(1, 0, sizedBox(100.0, 20.0));
      final RenderBox lower = sizedBox(100.0, 70.0);
      lower.parentData = TableCellParentData()..rowSpan = 2;
      table.setChild(1, 1, lower);

      layout(table, constraints: const BoxConstraints.tightFor(width: 200.0));

      expect(table.getRowBox(0).height, 20.0);
      expect(table.getRowBox(1).height, 0.0);
      expect(table.getRowBox(2).height, 80.0);
      expect(table.size.height, 100.0);
      expect(table.getMinIntrinsicHeight(200.0), 100.0);
      expect(table.getDryLayout(const BoxConstraints.tightFor(width: 200.0)).height, 100.0);
    });

    test('rowSpan still grows the table when the rows it covers are shorter', () {
      // The rows the span covers only account for 40 of its 300, so the last row
      // of the span has to absorb the remaining 260.
      final table = RenderTable(textDirection: TextDirection.ltr, columns: 2, rows: 2);

      final RenderBox spanningCell = sizedBox(50.0, 300.0);
      spanningCell.parentData = TableCellParentData()..rowSpan = 2;
      table.setChild(0, 0, spanningCell);
      table.setChild(1, 0, sizedBox(50.0, 20.0));
      table.setChild(1, 1, sizedBox(50.0, 20.0));

      // Row 0 is 20 tall, so row 1 has to be 280 tall for the span to fit.
      expect(table.getMinIntrinsicHeight(100.0), equals(300.0));

      // A taller neighbour in the second row wins over the remainder of the span.
      table.setChild(1, 1, sizedBox(50.0, 400.0));
      expect(table.getMinIntrinsicHeight(100.0), equals(420.0));
    });

    test('placeholder cells do not contribute to the intrinsic height', () {
      // A placeholder (TableCell.none) sits where a spanning cell already covers
      // the grid, so whatever it is made of must not be measured.
      final table = RenderTable(textDirection: TextDirection.ltr, columns: 2, rows: 2);

      final RenderBox spanningCell = sizedBox(50.0, 40.0);
      spanningCell.parentData = TableCellParentData()..rowSpan = 2;
      table.setChild(0, 0, spanningCell);

      final RenderBox placeholder = sizedBox(50.0, 500.0);
      placeholder.parentData = TableCellParentData()
        ..colSpan = 0
        ..rowSpan = 0;
      table.setChild(0, 1, placeholder);

      table.setChild(1, 0, sizedBox(50.0, 20.0));
      table.setChild(1, 1, sizedBox(50.0, 20.0));

      expect(table.getMinIntrinsicHeight(100.0), equals(40.0));
    });

    test('colSpan measures the cell against the width of the whole span', () {
      // The cell is as tall as it is wide, and it covers both 50 wide columns,
      // so it is 100 tall - not the 50 it would be in a single column.
      final table = RenderTable(
        textDirection: TextDirection.ltr,
        columns: 2,
        rows: 1,
        columnWidths: const <int, TableColumnWidth>{
          0: FixedColumnWidth(50.0),
          1: FixedColumnWidth(50.0),
        },
      );

      final square = RenderAspectRatio(aspectRatio: 1.0);
      square.parentData = TableCellParentData()..colSpan = 2;
      table.setChild(0, 0, square);

      expect(table.getMinIntrinsicHeight(100.0), equals(100.0));
    });

    test('colSpan attributes the cell width to the column it starts in', () {
      // Documents a known limitation: TableColumnWidth is handed the cells of a
      // single column at a time, so an IntrinsicColumnWidth column that a
      // spanning cell starts in is sized to the whole span. The table therefore
      // reports 350 (300 + 50) where 300 would be enough.
      // See the TODO on RenderTable.computeMinIntrinsicWidth.
      final table = RenderTable(
        textDirection: TextDirection.ltr,
        columns: 2,
        rows: 2,
        defaultColumnWidth: const IntrinsicColumnWidth(),
      );

      final RenderBox spanningCell = sizedBox(300.0, 20.0);
      spanningCell.parentData = TableCellParentData()..colSpan = 2;
      table.setChild(0, 0, spanningCell);
      table.setChild(1, 0, sizedBox(50.0, 20.0));
      table.setChild(1, 1, sizedBox(50.0, 20.0));

      expect(table.getMaxIntrinsicWidth(double.infinity), equals(350.0));
      expect(table.getMinIntrinsicWidth(double.infinity), equals(350.0));
    });
  });

  group('Table borders with spans', () {
    const borderColor = Color(0xFF0000FF);
    const fillColor = Color(0xFF00FF00);
    const transparent = Color(0x00000000);

    // A table with three 100x50 columns and two rows. Every entry in `spans`
    // maps the column and row of a cell to the number of columns and rows that
    // it spans. The slots that a span covers are left empty.
    RenderTable spanningTable(
      TableBorder border, {
      required Map<(int, int), (int, int)> spans,
      TextDirection textDirection = TextDirection.ltr,
    }) {
      final table = RenderTable(textDirection: textDirection, columns: 3, rows: 2, border: border);
      final covered = <(int, int)>{};
      spans.forEach(((int, int) cell, (int, int) span) {
        for (var dy = 0; dy < span.$2; dy += 1) {
          for (var dx = 0; dx < span.$1; dx += 1) {
            if (dx != 0 || dy != 0) {
              covered.add((cell.$1 + dx, cell.$2 + dy));
            }
          }
        }
      });
      for (var y = 0; y < 2; y += 1) {
        for (var x = 0; x < 3; x += 1) {
          if (covered.contains((x, y))) {
            continue;
          }
          final (int colSpan, int rowSpan) = spans[(x, y)] ?? (1, 1);
          final RenderBox cell = sizedBox(100.0 * colSpan, 50.0 * rowSpan);
          cell.parentData = TableCellParentData()
            ..colSpan = colSpan
            ..rowSpan = rowSpan;
          table.setChild(x, y, cell);
        }
      }
      return table;
    }

    // Paints `table` at 300x100 and returns the color of the pixel at (x, y).
    Future<Color Function(int x, int y)> paintPixels(RenderTable table) async {
      final boundary = RenderRepaintBoundary(child: table);
      layout(boundary, constraints: BoxConstraints.tight(const Size(300.0, 100.0)));
      pumpFrame(phase: EnginePhase.composite);
      final ui.Image image = await boundary.toImage();
      addTearDown(image.dispose);
      final ByteData bytes = (await image.toByteData())!;
      return (int x, int y) {
        final int offset = (x + y * image.width) * 4;
        return Color.fromARGB(
          bytes.getUint8(offset + 3),
          bytes.getUint8(offset),
          bytes.getUint8(offset + 1),
          bytes.getUint8(offset + 2),
        );
      };
    }

    // Two pixels wide, so that the borders cover whole pixels.
    final border = TableBorder.all(width: 2.0, color: borderColor);

    test('clips the inner borders out of a colSpan', () async {
      //   +---------+----+
      //   |    A    | B  |
      //   +----+----+----+
      //   | C  | D  | E  |
      //   +----+----+----+
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(border, spans: <(int, int), (int, int)>{(0, 0): (2, 1)}),
      );
      // The vertical border inside A is clipped out, up to the borders around A.
      expect(pixel(100, 25), transparent);
      expect(pixel(100, 2), transparent);
      expect(pixel(100, 1), borderColor);
      expect(pixel(100, 48), transparent);
      expect(pixel(100, 49), borderColor);
      // The borders around A and the other cells are painted.
      expect(pixel(199, 25), borderColor);
      expect(pixel(200, 25), borderColor);
      expect(pixel(100, 75), borderColor);
      expect(pixel(150, 50), borderColor);
    });

    test('paints the borders around a span like the other borders', () async {
      // One pixel wide borders between two cells only partly cover the pixels
      // on either side of the line between the cells.
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          TableBorder.all(color: borderColor),
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
        ),
      );
      expect(pixel(199, 25), isNot(transparent));
      expect(pixel(199, 25), pixel(199, 75));
      expect(pixel(150, 49), isNot(transparent));
      expect(pixel(150, 49), pixel(250, 49));
    });

    test('clips the inner borders out of a colSpan in RTL', () async {
      //   +----+---------+
      //   | B  |    A    |
      //   +----+----+----+
      //   | E  | D  | C  |
      //   +----+----+----+
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          border,
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
          textDirection: TextDirection.rtl,
        ),
      );
      expect(pixel(200, 25), transparent);
      expect(pixel(100, 25), borderColor);
      expect(pixel(200, 75), borderColor);
    });

    test('clips the inner borders out of a rowSpan', () async {
      //   +----+----+----+
      //   | A  | B  |    |
      //   +----+----+ C  |
      //   | D  | E  |    |
      //   +----+----+----+
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(border, spans: <(int, int), (int, int)>{(2, 0): (1, 2)}),
      );
      // The horizontal border inside C is clipped out, up to the borders around C.
      expect(pixel(250, 49), transparent);
      expect(pixel(250, 50), transparent);
      expect(pixel(201, 50), transparent);
      expect(pixel(200, 50), borderColor);
      expect(pixel(297, 50), transparent);
      expect(pixel(298, 50), borderColor);
      // The other borders are painted.
      expect(pixel(150, 50), borderColor);
      expect(pixel(200, 25), borderColor);
    });

    test('clips the inner borders out of overlapping spans', () async {
      //   +----+----+----+
      //   | A  |    | C  |
      //   +----+ B  +----+
      //   |   D     | E  |
      //   +----+----+----+
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(border, spans: <(int, int), (int, int)>{(1, 0): (1, 2), (0, 1): (2, 1)}),
      );
      expect(pixel(150, 50), transparent);
      expect(pixel(100, 75), transparent);
      expect(pixel(100, 25), borderColor);
      expect(pixel(50, 50), borderColor);
      expect(pixel(200, 75), borderColor);
      expect(pixel(250, 50), borderColor);
    });

    test('keeps the full width of thick borders around a span', () async {
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          const TableBorder.symmetric(
            inside: BorderSide(width: 6.0, color: borderColor),
            outside: BorderSide(width: 4.0, color: borderColor),
          ),
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
        ),
      );
      expect(pixel(100, 25), transparent);
      // The outer border above A is four pixels wide.
      expect(pixel(100, 3), borderColor);
      expect(pixel(100, 4), transparent);
      // The inner borders below and to the right of A are six pixels wide,
      // three of them inside A.
      expect(pixel(100, 47), borderColor);
      expect(pixel(100, 46), transparent);
      expect(pixel(197, 25), borderColor);
      expect(pixel(196, 25), transparent);
    });

    test('keeps the rounded corners of the outer border around a span', () async {
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          TableBorder.all(
            width: 2.0,
            color: borderColor,
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          ),
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
        ),
      );
      expect(pixel(100, 25), transparent);
      // A pixel on the rounded top left corner, inside the rectangle that A
      // covers within the outer border.
      expect(pixel(3, 3), borderColor);
      expect(pixel(6, 6), transparent);
    });

    test('clips the inner borders up to the sides that are painted', () async {
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          const TableBorder(
            top: BorderSide(width: 4.0, style: BorderStyle.none),
            horizontalInside: BorderSide(width: 6.0, style: BorderStyle.none),
            verticalInside: BorderSide(width: 2.0, color: borderColor),
          ),
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
        ),
      );
      // Neither the top border nor the border below A is painted, so the
      // vertical border inside A is clipped out all the way to the edges of A.
      expect(pixel(100, 1), transparent);
      expect(pixel(100, 48), transparent);
      // The other vertical borders are painted.
      expect(pixel(100, 75), borderColor);
      expect(pixel(200, 25), borderColor);
    });

    test('clips all of a span when the outer border has square corners', () async {
      // TableBorder paints square corners, despite the borderRadius, because
      // the left side has a different color.
      const leftColor = Color(0xFFFF0000);
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          const TableBorder(
            top: BorderSide(width: 2.0, color: borderColor),
            right: BorderSide(width: 2.0, color: borderColor),
            bottom: BorderSide(width: 2.0, color: borderColor),
            left: BorderSide(width: 2.0, color: leftColor),
            verticalInside: BorderSide(width: 2.0, color: borderColor),
            borderRadius: BorderRadius.all(Radius.elliptical(150.0, 50.0)),
          ),
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
        ),
      );
      // Rounded corners this large would reach past the vertical border inside
      // A, near the top of the table.
      expect(pixel(100, 1), borderColor);
      expect(pixel(100, 3), transparent);
      expect(pixel(200, 25), borderColor);
    });

    test('clips what a TableBorder subclass paints inside a span', () async {
      final Color Function(int, int) pixel = await paintPixels(
        spanningTable(
          const _FillingTableBorder(fillColor),
          spans: <(int, int), (int, int)>{(0, 0): (2, 1)},
        ),
      );
      // The border has no sides, so all of A is clipped out.
      expect(pixel(0, 0), transparent);
      expect(pixel(100, 25), transparent);
      expect(pixel(199, 49), transparent);
      expect(pixel(200, 25), fillColor);
      expect(pixel(100, 50), fillColor);
    });

    test('clips the border only when the table has spans', () {
      final RenderTable plainTable = spanningTable(border, spans: const <(int, int), (int, int)>{});
      layout(plainTable, constraints: const BoxConstraints.tightFor(width: 300.0));
      expect(plainTable, paintsExactlyCountTimes(#save, 0));
      expect(plainTable, paintsExactlyCountTimes(#clipRect, 0));

      final RenderTable table = spanningTable(
        border,
        spans: <(int, int), (int, int)>{(0, 0): (2, 1), (2, 0): (1, 2)},
      );
      layout(table, constraints: const BoxConstraints.tightFor(width: 300.0));
      expect(table, paintsExactlyCountTimes(#clipRect, 2));
    });
  });
}

/// A box that is as wide as its constraints allow and 100 pixels tall, with a
/// baseline at [fraction] of its width.
class _WidthBaselineBox extends RenderBox {
  _WidthBaselineBox(this.fraction);

  final double fraction;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(Size(constraints.maxWidth, 100.0));
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    return constraints.maxWidth * fraction;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => size.width * fraction;
}

/// A [TableBorder] without sides that fills the whole table with [color].
class _FillingTableBorder extends TableBorder {
  const _FillingTableBorder(this.color);

  final Color color;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    required Iterable<double> rows,
    required Iterable<double> columns,
  }) {
    canvas.drawRect(rect, Paint()..color = color);
  }
}
