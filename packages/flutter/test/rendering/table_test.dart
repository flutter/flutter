// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_canvas.dart';
import 'rendering_tester.dart';

RenderBox sizedBox(double width, double height) {
  return RenderConstrainedBox(
    additionalConstraints: BoxConstraints.tight(Size(width, height))
  );
}

void main() {
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

    expect(table.size, equals(const Size(0.0, 0.0)));
  });

  test('Table control test: constrained flex columns', () {
    final RenderTable table = RenderTable(textDirection: TextDirection.ltr);
    final List<RenderBox> children = List<RenderBox>.generate(6, (_) => RenderPositionedBox());

    RenderBox? preChild;
    for (final RenderBox child in children) {
      table.insertChild(child, after: preChild);
      preChild = child;
    }

    table.updateInfo(1, 6);

    layout(table, constraints: const BoxConstraints.tightFor(width: 100.0));

    const double expectedWidth = 100.0 / 6;
    for (final RenderBox child in children) {
      expect(child.size.width, moreOrLessEquals(expectedWidth));
    }
  });

  test('Table test: combinations', () {
    final RenderTable table = RenderTable(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      textDirection: TextDirection.ltr,
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
    );

    layout(RenderPositionedBox(child: table));

    expect(table.size, equals(const Size(0.0, 0.0)));

    table.insertChild(null);
    table.insertChild(null);
    table.insertChild(sizedBox(100.0, 200.0));
    table.updateInfo(1, 3);
    pumpFrame();

    expect(table.size, equals(const Size(100.0, 200.0)));

    for (int index = 0; index < 19; index++)
      table.insertChild(null);

    table.insertChild(sizedBox(30.0, 10.0));
    table.insertChild(sizedBox(20.0, 20.0));
    table.insertChild(sizedBox(10.0, 30.0));
    table.updateInfo(5, 5);
    pumpFrame();

    expect(table.size, equals(const Size(130.0, 230.0)));

    expect(table, hasAGoodToStringDeep);
    expect(
      table.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderTable#00000 relayoutBoundary=up1 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE\n'
        ' │ parentData: offset=Offset(335.0, 185.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
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
    final RenderBox child = sizedBox(10.0, 10.0);
    table = RenderTable(
      columns: 5,
      rows: 5,
      textDirection: TextDirection.ltr,
    );
    for (int index = 0; index < 5 * 5; index++) {
      if (index == 0) {
        table.insertChild(child);
      } else {
        table.insertChild(null);
      }
    }

    layout(table);
    expect(child.attached, isTrue);
    table.removeChild(child);
    table.insertChild(RenderPositionedBox());
    expect(child.attached, isFalse);
  });

  test('Table test: replacing cells', () {
    RenderTable table;
    final RenderBox child1 = RenderPositionedBox();
    final RenderBox child2 = RenderPositionedBox();
    final RenderBox child3 = RenderPositionedBox();
    final RenderBox child4 = RenderPositionedBox();
    final RenderBox child5 = RenderPositionedBox();
    final RenderBox child6 = RenderPositionedBox();
    table = RenderTable(textDirection: TextDirection.ltr);

    table.insertChild(child1);
    table.insertChild(child2, after: child1);
    table.insertChild(child3, after: child2);

    table.insertChild(child4, after: child1);
    table.insertChild(child5, after: child2);
    table.insertChild(child6, after: child3);

    table.updateInfo(2, 3);

    expect(table.rows, equals(2));
    layout(table);

    table.moveChild(child4,);
    table.moveChild(child5, after: child1);
    table.moveChild(child6, after: child2);
    pumpFrame();

    table.removeChild(child4);
    table.removeChild(child5);
    table.removeChild(child6);
    table.insertChild(RenderPositionedBox(),);
    table.insertChild(RenderPositionedBox(), after: child1);
    table.insertChild(RenderPositionedBox(), after: child2);
    pumpFrame();
    expect(table.columns, equals(3));
    expect(table.rows, equals(2));
  });

  test('Table border painting', () {
    final RenderTable table = RenderTable(
      textDirection: TextDirection.rtl,
      border: TableBorder.all(),
    );
    layout(table);
    table.updateInfo(0, 0);
    pumpFrame();
    expect(table, paints..path()..path()..path()..path());
    table.insertChild(RenderPositionedBox());
    table.updateInfo(1, 1);
    pumpFrame();
    expect(table, paints..path()..path()..path()..path());
    table.insertChild(RenderPositionedBox());
    table.updateInfo(2, 1);
    pumpFrame();
    expect(table, paints..path()..path()..path()..path()..path());
    table.updateInfo(1, 2);
    pumpFrame();
    expect(table, paints..path()..path()..path()..path()..path());
    table.insertChild(RenderPositionedBox());
    table.insertChild(RenderPositionedBox());
    table.updateInfo(2, 2);
    pumpFrame();
    expect(table, paints..path()..path()..path()..path()..path()..path());
    table.insertChild(RenderPositionedBox());
    table.insertChild(RenderPositionedBox());
    table.updateInfo(2, 3);
    pumpFrame();
    expect(table, paints..path()..path()..path()..path()..path()..path());
  });

  test('Table flex sizing', () {
    const BoxConstraints cellConstraints =
        BoxConstraints.tightFor(width: 100, height: 100);
    final RenderTable table = RenderTable(
      textDirection: TextDirection.rtl,
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.0),
        1: FlexColumnWidth(0.123),
        2: FlexColumnWidth(0.123),
        3: FlexColumnWidth(0.123),
        4: FlexColumnWidth(0.123),
        5: FlexColumnWidth(0.123),
        6: FlexColumnWidth(0.123),
      },
    );

    for (int index = 0; index < 7; index++)
      table.insertChild(RenderConstrainedBox(additionalConstraints: cellConstraints));
    table.updateInfo(1, 7);

    layout(table, constraints: BoxConstraints.tight(const Size(800.0, 600.0)));
    expect(table.hasSize, true);
  });
}
