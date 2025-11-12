// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'semantics_tester.dart';

class TestStatefulWidget extends StatefulWidget {
  const TestStatefulWidget({super.key});

  @override
  TestStatefulWidgetState createState() => TestStatefulWidgetState();
}

class TestStatefulWidgetState extends State<TestStatefulWidget> {
  @override
  Widget build(BuildContext context) => Container();
}

class TestChildWidget extends StatefulWidget {
  const TestChildWidget({super.key});

  @override
  TestChildState createState() => TestChildState();
}

class TestChildState extends State<TestChildWidget> {
  bool toggle = true;

  void toggleMe() {
    setState(() {
      toggle = !toggle;
    });
  }

  @override
  Widget build(BuildContext context) => toggle ? const SizedBox() : const Text('CRASHHH');
}

void main() {
  testWidgets('Table widget - empty', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Table()));
  });

  testWidgets('Table widget - control test', (WidgetTester tester) async {
    Future<void> run(TextDirection textDirection) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: textDirection,
          child: Table(
            children: const <TableRow>[
              TableRow(children: <Widget>[Text('AAAAAA'), Text('B'), Text('C')]),
              TableRow(children: <Widget>[Text('D'), Text('EEE'), Text('F')]),
              TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
            ],
          ),
        ),
      );
      final RenderBox boxA = tester.renderObject(find.text('AAAAAA'));
      final RenderBox boxD = tester.renderObject(find.text('D'));
      final RenderBox boxG = tester.renderObject(find.text('G'));
      final RenderBox boxB = tester.renderObject(find.text('B'));
      expect(boxA.size, equals(boxD.size));
      expect(boxA.size, equals(boxG.size));
      expect(boxA.size, equals(boxB.size));
    }

    await run(TextDirection.ltr);
    await tester.pumpWidget(Container());
    await run(TextDirection.rtl);
  });

  testWidgets('Table widget calculate depth', (WidgetTester tester) async {
    final UniqueKey outerTable = UniqueKey();
    final UniqueKey innerTable = UniqueKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          key: outerTable,
          children: <TableRow>[
            TableRow(
              children: <Widget>[
                Table(
                  key: innerTable,
                  children: const <TableRow>[
                    TableRow(children: <Widget>[Text('AAAAAA'), Text('B'), Text('C')]),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final RenderObject outerTableRenderObject = tester.renderObject(find.byKey(outerTable));
    final RenderObject innerTableRenderObject = tester.renderObject(find.byKey(innerTable));
    final RenderObject textRenderObject = tester.renderObject(find.text('AAAAAA'));
    expect(outerTableRenderObject.depth + 1, innerTableRenderObject.depth);
    expect(innerTableRenderObject.depth + 1, textRenderObject.depth);
  });

  testWidgets('Table widget can be detached and re-attached', (WidgetTester tester) async {
    final Widget table = Table(
      key: GlobalKey(),
      children: const <TableRow>[
        TableRow(
          decoration: BoxDecoration(color: Colors.yellow),
          children: <Widget>[Placeholder()],
        ),
      ],
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: table),
      ),
    );
    // Move table to a different location to simulate detaching and re-attaching effect.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Center(child: table)),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Table widget - column offset (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(100.0),
              1: FixedColumnWidth(110.0),
              2: FixedColumnWidth(125.0),
            },
            defaultColumnWidth: const FixedColumnWidth(333.0),
            children: const <TableRow>[
              TableRow(children: <Widget>[Text('A1'), Text('B1'), Text('C1')]),
              TableRow(children: <Widget>[Text('A2'), Text('B2'), Text('C2')]),
              TableRow(children: <Widget>[Text('A3'), Text('B3'), Text('C3')]),
            ],
          ),
        ),
      ),
    );

    final Rect table = tester.getRect(find.byType(Table));
    final Rect a1 = tester.getRect(find.text('A1'));
    final Rect a2 = tester.getRect(find.text('A2'));
    final Rect a3 = tester.getRect(find.text('A3'));
    final Rect b1 = tester.getRect(find.text('B1'));
    final Rect b2 = tester.getRect(find.text('B2'));
    final Rect b3 = tester.getRect(find.text('B3'));
    final Rect c1 = tester.getRect(find.text('C1'));
    final Rect c2 = tester.getRect(find.text('C2'));
    final Rect c3 = tester.getRect(find.text('C3'));

    expect(a1.width, equals(100.0));
    expect(a2.width, equals(100.0));
    expect(a3.width, equals(100.0));
    expect(b1.width, equals(110.0));
    expect(b2.width, equals(110.0));
    expect(b3.width, equals(110.0));
    expect(c1.width, equals(125.0));
    expect(c2.width, equals(125.0));
    expect(c3.width, equals(125.0));

    expect(table.width, equals(335.0));

    expect(a1.left, equals(table.left));
    expect(a2.left, equals(a1.left));
    expect(a3.left, equals(a1.left));

    expect(b1.left, equals(table.left + a1.width));
    expect(b2.left, equals(b1.left));
    expect(b3.left, equals(b1.left));

    expect(c1.left, equals(table.left + a1.width + b1.width));
    expect(c2.left, equals(c1.left));
    expect(c3.left, equals(c1.left));
  });

  testWidgets('Table widget - column offset (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(100.0),
              1: FixedColumnWidth(110.0),
              2: FixedColumnWidth(125.0),
            },
            defaultColumnWidth: const FixedColumnWidth(333.0),
            children: const <TableRow>[
              TableRow(children: <Widget>[Text('A1'), Text('B1'), Text('C1')]),
              TableRow(children: <Widget>[Text('A2'), Text('B2'), Text('C2')]),
              TableRow(children: <Widget>[Text('A3'), Text('B3'), Text('C3')]),
            ],
          ),
        ),
      ),
    );

    final Rect table = tester.getRect(find.byType(Table));
    final Rect a1 = tester.getRect(find.text('A1'));
    final Rect a2 = tester.getRect(find.text('A2'));
    final Rect a3 = tester.getRect(find.text('A3'));
    final Rect b1 = tester.getRect(find.text('B1'));
    final Rect b2 = tester.getRect(find.text('B2'));
    final Rect b3 = tester.getRect(find.text('B3'));
    final Rect c1 = tester.getRect(find.text('C1'));
    final Rect c2 = tester.getRect(find.text('C2'));
    final Rect c3 = tester.getRect(find.text('C3'));

    expect(a1.width, equals(100.0));
    expect(a2.width, equals(100.0));
    expect(a3.width, equals(100.0));
    expect(b1.width, equals(110.0));
    expect(b2.width, equals(110.0));
    expect(b3.width, equals(110.0));
    expect(c1.width, equals(125.0));
    expect(c2.width, equals(125.0));
    expect(c3.width, equals(125.0));

    expect(table.width, equals(335.0));

    expect(a1.right, equals(table.right));
    expect(a2.right, equals(a1.right));
    expect(a3.right, equals(a1.right));

    expect(b1.right, equals(table.right - a1.width));
    expect(b2.right, equals(b1.right));
    expect(b3.right, equals(b1.right));

    expect(c1.right, equals(table.right - a1.width - b1.width));
    expect(c2.right, equals(c1.right));
    expect(c3.right, equals(c1.right));
  });

  testWidgets('Table border - smoke test', (WidgetTester tester) async {
    Future<void> run(TextDirection textDirection) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: textDirection,
          child: Table(
            border: TableBorder.all(),
            children: const <TableRow>[
              TableRow(children: <Widget>[Text('AAAAAA'), Text('B'), Text('C')]),
              TableRow(children: <Widget>[Text('D'), Text('EEE'), Text('F')]),
              TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
            ],
          ),
        ),
      );
    }

    await run(TextDirection.ltr);
    await tester.pumpWidget(Container());
    await run(TextDirection.rtl);
  });

  testWidgets('Table widget - changing table dimensions', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('A'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('E'), Text('F')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('I')]),
          ],
        ),
      ),
    );
    final RenderBox boxA1 = tester.renderObject(find.text('A'));
    final RenderBox boxG1 = tester.renderObject(find.text('G'));
    expect(boxA1, isNotNull);
    expect(boxG1, isNotNull);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('a'), Text('b'), Text('c'), Text('d')]),
            TableRow(children: <Widget>[Text('e'), Text('f'), Text('g'), Text('h')]),
          ],
        ),
      ),
    );
    final RenderBox boxA2 = tester.renderObject(find.text('a'));
    final RenderBox boxG2 = tester.renderObject(find.text('g'));
    expect(boxA2, isNotNull);
    expect(boxG2, isNotNull);
    expect(boxA1, equals(boxA2));
    expect(boxG1, isNot(equals(boxG2)));
  });

  testWidgets('Really small deficit double precision error', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/27083
    const SizedBox cell = SizedBox(width: 16, height: 16);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[cell, cell, cell, cell, cell, cell]),
            TableRow(children: <Widget>[cell, cell, cell, cell, cell, cell]),
          ],
        ),
      ),
    );
    // If the above bug is present this test will never terminate.
  });

  testWidgets('Calculating flex columns with small width deficit', (WidgetTester tester) async {
    const SizedBox cell = SizedBox(width: 1, height: 1);
    // If the error is present, pumpWidget() will fail due to an unsatisfied
    // assertion during the layout phase.
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: BoxConstraints.tight(const Size(600, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(),
              1: FlexColumnWidth(0.123),
              2: FlexColumnWidth(0.123),
              3: FlexColumnWidth(0.123),
              4: FlexColumnWidth(0.123),
              5: FlexColumnWidth(0.123),
              6: FlexColumnWidth(0.123),
            },
            children: <TableRow>[
              TableRow(children: List<Widget>.filled(7, cell)),
              TableRow(children: List<Widget>.filled(7, cell)),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), null);
  });

  testWidgets('Table widget - repump test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('AAAAAA'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('EEE'), Text('F')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('AAA'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('E'), Text('FFFFFF')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    final RenderBox boxA = tester.renderObject(find.text('AAA'));
    final RenderBox boxD = tester.renderObject(find.text('D'));
    final RenderBox boxG = tester.renderObject(find.text('G'));
    final RenderBox boxB = tester.renderObject(find.text('B'));
    expect(boxA.size, equals(boxD.size));
    expect(boxA.size, equals(boxG.size));
    expect(boxA.size, equals(boxB.size));
  });

  testWidgets('Table widget - intrinsic sizing test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('AAA'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('E'), Text('FFFFFF')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    final RenderBox boxA = tester.renderObject(find.text('AAA'));
    final RenderBox boxD = tester.renderObject(find.text('D'));
    final RenderBox boxG = tester.renderObject(find.text('G'));
    final RenderBox boxB = tester.renderObject(find.text('B'));
    expect(boxA.size, equals(boxD.size));
    expect(boxA.size, equals(boxG.size));
    expect(boxA.size.width, greaterThan(boxB.size.width));
    expect(boxA.size.height, equals(boxB.size.height));
  });

  testWidgets('Table widget - intrinsic sizing test, resizing', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('AAAAAA'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('EEE'), Text('F')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('A'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('EEE'), Text('F')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    final RenderBox boxA = tester.renderObject(find.text('A'));
    final RenderBox boxD = tester.renderObject(find.text('D'));
    final RenderBox boxG = tester.renderObject(find.text('G'));
    final RenderBox boxB = tester.renderObject(find.text('B'));
    expect(boxA.size, equals(boxD.size));
    expect(boxA.size, equals(boxG.size));
    expect(boxA.size.width, lessThan(boxB.size.width));
    expect(boxA.size.height, equals(boxB.size.height));
  });

  testWidgets('Table widget - intrinsic sizing test, changing column widths', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('AAA'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('E'), Text('FFFFFF')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: const <TableRow>[
            TableRow(children: <Widget>[Text('AAA'), Text('B'), Text('C')]),
            TableRow(children: <Widget>[Text('D'), Text('E'), Text('FFFFFF')]),
            TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
          ],
        ),
      ),
    );
    final RenderBox boxA = tester.renderObject(find.text('AAA'));
    final RenderBox boxD = tester.renderObject(find.text('D'));
    final RenderBox boxG = tester.renderObject(find.text('G'));
    final RenderBox boxB = tester.renderObject(find.text('B'));
    expect(boxA.size, equals(boxD.size));
    expect(boxA.size, equals(boxG.size));
    expect(boxA.size.width, greaterThan(boxB.size.width));
    expect(boxA.size.height, equals(boxB.size.height));
  });

  testWidgets('Table widget - moving test', (WidgetTester tester) async {
    final List<BuildContext> contexts = <BuildContext>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: <TableRow>[
            TableRow(
              key: const ValueKey<int>(1),
              children: <Widget>[
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    contexts.add(context);
                    return const Text('A');
                  },
                ),
              ],
            ),
            const TableRow(children: <Widget>[Text('b')]),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: <TableRow>[
            const TableRow(children: <Widget>[Text('b')]),
            TableRow(
              key: const ValueKey<int>(1),
              children: <Widget>[
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    contexts.add(context);
                    return const Text('A');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(contexts.length, equals(2));
    expect(contexts[0], equals(contexts[1]));
  });

  testWidgets('Table widget - keyed rows', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(
              key: ValueKey<int>(1),
              children: <Widget>[
                TestStatefulWidget(key: ValueKey<int>(11)),
                TestStatefulWidget(key: ValueKey<int>(12)),
              ],
            ),
            TableRow(
              key: ValueKey<int>(2),
              children: <Widget>[
                TestStatefulWidget(key: ValueKey<int>(21)),
                TestStatefulWidget(key: ValueKey<int>(22)),
              ],
            ),
          ],
        ),
      ),
    );

    final TestStatefulWidgetState state11 = tester.state(find.byKey(const ValueKey<int>(11)));
    final TestStatefulWidgetState state12 = tester.state(find.byKey(const ValueKey<int>(12)));
    final TestStatefulWidgetState state21 = tester.state(find.byKey(const ValueKey<int>(21)));
    final TestStatefulWidgetState state22 = tester.state(find.byKey(const ValueKey<int>(22)));

    expect(state11.mounted, isTrue);
    expect(state12.mounted, isTrue);
    expect(state21.mounted, isTrue);
    expect(state22.mounted, isTrue);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(
              key: ValueKey<int>(2),
              children: <Widget>[
                TestStatefulWidget(key: ValueKey<int>(21)),
                TestStatefulWidget(key: ValueKey<int>(22)),
              ],
            ),
          ],
        ),
      ),
    );

    expect(state11.mounted, isFalse);
    expect(state12.mounted, isFalse);
    expect(state21.mounted, isTrue);
    expect(state22.mounted, isTrue);
  });

  testWidgets('Table widget - global key reparenting', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final Key tableKey = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Expanded(
              key: tableKey,
              child: Table(
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      Container(key: const ValueKey<int>(1)),
                      TestStatefulWidget(key: key),
                      Container(key: const ValueKey<int>(2)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final RenderTable table = tester.renderObject(find.byType(Table));
    expect(table.row(0).length, 3);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Expanded(child: TestStatefulWidget(key: key)),
            Expanded(
              key: tableKey,
              child: Table(
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      Container(key: const ValueKey<int>(1)),
                      Container(key: const ValueKey<int>(2)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.renderObject(find.byType(Table)), equals(table));
    expect(table.row(0).length, 2);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Expanded(
              key: tableKey,
              child: Table(
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      Container(key: const ValueKey<int>(1)),
                      TestStatefulWidget(key: key),
                      Container(key: const ValueKey<int>(2)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.renderObject(find.byType(Table)), equals(table));
    expect(table.row(0).length, 3);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Expanded(
              key: tableKey,
              child: Table(
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      Container(key: const ValueKey<int>(1)),
                      Container(key: const ValueKey<int>(2)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: TestStatefulWidget(key: key)),
          ],
        ),
      ),
    );

    expect(tester.renderObject(find.byType(Table)), equals(table));
    expect(table.row(0).length, 2);
  });

  testWidgets('Table widget diagnostics', (WidgetTester tester) async {
    GlobalKey key0;
    final Widget table = Directionality(
      textDirection: TextDirection.ltr,
      child: Table(
        key: key0 = GlobalKey(),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: const <TableRow>[
          TableRow(children: <Widget>[Text('A'), Text('B'), Text('C')]),
          TableRow(children: <Widget>[Text('D'), Text('EEE'), Text('F')]),
          TableRow(children: <Widget>[Text('G'), Text('H'), Text('III')]),
        ],
      ),
    );
    await tester.pumpWidget(table);
    final RenderObjectElement element = key0.currentContext! as RenderObjectElement;
    expect(element, hasAGoodToStringDeep);
    expect(
      element.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'Table-[GlobalKey#00000](dependencies: [Directionality, MediaQuery], renderObject: RenderTable#00000)\n'
        '├Text("A", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "A", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("B", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "B", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("C", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "C", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("D", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "D", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("EEE", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "EEE", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("F", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "F", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("G", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "G", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("H", dependencies: [MediaQuery])\n'
        '│└RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "H", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '└Text("III", dependencies: [MediaQuery])\n'
        ' └RichText(softWrap: wrapping at box width, maxLines: unlimited, text: "III", dependencies: [Directionality], renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n',
      ),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/31473.
  testWidgets(
    'Does not crash if a child RenderObject is replaced by another RenderObject of a different type',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(children: <Widget>[TestChildWidget()]),
            ],
          ),
        ),
      );
      expect(find.text('CRASHHH'), findsNothing);

      final TestChildState state = tester.state(find.byType(TestChildWidget));
      state.toggleMe();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(children: <Widget>[TestChildWidget()]),
            ],
          ),
        ),
      );

      // Should not crash.
      expect(find.text('CRASHHH'), findsOneWidget);
    },
  );

  testWidgets('Table widget - Default textBaseline is null', (WidgetTester tester) async {
    expect(
      () => Table(defaultVerticalAlignment: TableCellVerticalAlignment.baseline),
      throwsA(
        isAssertionError.having(
          (AssertionError error) => error.message,
          'exception message',
          contains('baseline'),
        ),
      ),
    );
  });

  testWidgets('Table widget requires all TableRows to have same number of children', (
    WidgetTester tester,
  ) async {
    FlutterError? error;
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(children: <Widget>[Text('Some Text')]),
              TableRow(),
            ],
          ),
        ),
      );
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(error!.toStringDeep(), contains('Inconsistent number of table cells.'));
    }
  });

  testWidgets('Can replace child with a different RenderObject type', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/69395.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: const <TableRow>[
            TableRow(children: <Widget>[TestChildWidget(), TestChildWidget(), TestChildWidget()]),
            TableRow(children: <Widget>[TestChildWidget(), TestChildWidget(), TestChildWidget()]),
          ],
        ),
      ),
    );
    final RenderTable table = tester.renderObject(find.byType(Table));

    expect(find.text('CRASHHH'), findsNothing);
    expect(find.byType(SizedBox), findsNWidgets(3 * 2));
    final Type toBeReplaced = table.column(2).last.runtimeType;

    final TestChildState state = tester.state(find.byType(TestChildWidget).last);
    state.toggleMe();
    await tester.pump();

    expect(find.byType(SizedBox), findsNWidgets(5));
    expect(find.text('CRASHHH'), findsOneWidget);

    // The RenderObject got replaced by a different type.
    expect(table.column(2).last.runtimeType, isNot(toBeReplaced));
  });

  testWidgets('Do not crash if a child that has not been laid out in a previous build is removed', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/60488.
    Widget buildTable(Key key) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Table(
          children: <TableRow>[
            TableRow(
              children: <Widget>[KeyedSubtree(key: key, child: const Text('Hello'))],
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(
      buildTable(const ValueKey<int>(1)),
      phase: EnginePhase.build, // Children are not laid out!
    );

    await tester.pumpWidget(buildTable(const ValueKey<int>(2)));

    expect(tester.takeException(), isNull);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('TableRow with no children throws an error message', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/119541.
    String result = 'no exception';

    // Test TableRow with children.
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(children: <Widget>[Text('A')]),
            ],
          ),
        ),
      );
    } on FlutterError catch (e) {
      result = e.toString();
    }

    expect(result, 'no exception');

    // Test TableRow with no children.
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(children: const <TableRow>[TableRow()]),
        ),
      );
    } on FlutterError catch (e) {
      result = e.toString();
    }

    expect(
      result,
      'Empty first TableRow.\n'
      'The first TableRow in the table has no cells. '
      'It must contain at least one child widget to define the '
      "table's column count.",
    );
  });

  testWidgets('Set defaultVerticalAlignment to intrinsic height and check their heights', (
    WidgetTester tester,
  ) async {
    final Widget table = Directionality(
      textDirection: TextDirection.ltr,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
        children: const <TableRow>[
          TableRow(
            children: <Widget>[
              SizedBox(height: 100, child: Text('A')),
              SizedBox(height: 200, child: Text('B')),
            ],
          ),
          TableRow(
            children: <Widget>[
              SizedBox(height: 200, child: Text('C')),
              SizedBox(height: 300, child: Text('D')),
            ],
          ),
        ],
      ),
    );

    // load and check if render object was created.
    await tester.pumpWidget(table);
    expect(find.byWidget(table), findsOneWidget);

    final RenderBox boxA = tester.renderObject(find.text('A'));
    final RenderBox boxB = tester.renderObject(find.text('B'));

    // boxA and boxB must be the same height, even though boxB is higher than boxA initially.
    expect(boxA.size.height, equals(boxB.size.height));

    final RenderBox boxC = tester.renderObject(find.text('C'));
    final RenderBox boxD = tester.renderObject(find.text('D'));

    // boxC and boxD must be the same height, even though boxD is higher than boxC initially.
    expect(boxC.size.height, equals(boxD.size.height));

    // boxD (300.0h) should be higher than boxA (200.0h) which has the same height of boxB.
    expect(boxD.size.height, greaterThan(boxA.size.height));
  });

  testWidgets('Table has correct roles in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(child: Text('Data Cell 1')),
                  TableCell(child: Text('Data Cell 2')),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          textDirection: TextDirection.ltr,
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      role: SemanticsRole.table,
                      children: <TestSemantics>[
                        TestSemantics(
                          role: SemanticsRole.row,
                          children: <TestSemantics>[
                            TestSemantics(
                              label: 'Data Cell 1',
                              textDirection: TextDirection.ltr,
                              role: SemanticsRole.cell,
                            ),
                            TestSemantics(
                              label: 'Data Cell 2',
                              textDirection: TextDirection.ltr,
                              role: SemanticsRole.cell,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true, ignoreRect: true),
    );

    semantics.dispose();
  });

  testWidgets('Table reuse the semantics nodes for cell wrappers', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Table(
            children: <TableRow>[
              TableRow(children: <Widget>[TextField(focusNode: focusNode)]),
            ],
          ),
        ),
      ),
    );

    final SemanticsNode textFieldSemanticsNode = find.semantics
        .byFlag(SemanticsFlag.isTextField)
        .evaluate()
        .first;
    final int? cellWrapperId = textFieldSemanticsNode.parent?.id;

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final SemanticsNode textFieldSemanticsNodeNew = find.semantics
        .byFlag(SemanticsFlag.isTextField)
        .evaluate()
        .first;

    final int? cellWrapperIdAfterUIchanges = textFieldSemanticsNodeNew.parent?.id;
    expect(cellWrapperIdAfterUIchanges, cellWrapperId);
  });

  group('TableCell colSpan and rowSpan tests', () {
    testWidgets('TableCell with default colSpan and rowSpan', (WidgetTester tester) async {
      const TableCell cell = TableCell(child: Text('Cell'));
      expect(cell.colSpan, equals(1));
      expect(cell.rowSpan, equals(1));
    });

    testWidgets('TableCell with custom colSpan', (WidgetTester tester) async {
      const TableCell cell = TableCell(colSpan: 3, child: Text('Cell'));
      expect(cell.colSpan, equals(3));
      expect(cell.rowSpan, equals(1));
    });

    testWidgets('TableCell with custom rowSpan', (WidgetTester tester) async {
      const TableCell cell = TableCell(rowSpan: 2, child: Text('Cell'));
      expect(cell.colSpan, equals(1));
      expect(cell.rowSpan, equals(2));
    });

    testWidgets('TableCell with both colSpan and rowSpan', (WidgetTester tester) async {
      const TableCell cell = TableCell(colSpan: 2, rowSpan: 3, child: Text('Cell'));
      expect(cell.colSpan, equals(2));
      expect(cell.rowSpan, equals(3));
    });

    testWidgets('TableCell.none has zero colSpan and rowSpan', (WidgetTester tester) async {
      expect(TableCell.none.colSpan, equals(0));
      expect(TableCell.none.rowSpan, equals(0));
    });

    testWidgets('Table with colSpan - basic functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(colSpan: 2, child: Text('Spanning Cell')),
                  TableCell.none,
                ],
              ),
              TableRow(children: <Widget>[Text('Cell 1'), Text('Cell 2')]),
            ],
          ),
        ),
      );

      expect(find.text('Spanning Cell'), findsOneWidget);
      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 2'), findsOneWidget);
    });

    testWidgets('Table with rowSpan - basic functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(rowSpan: 2, child: Text('Spanning Cell')),
                  Text('Cell 1'),
                ],
              ),
              TableRow(children: <Widget>[TableCell.none, Text('Cell 2')]),
            ],
          ),
        ),
      );

      expect(find.text('Spanning Cell'), findsOneWidget);
      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 2'), findsOneWidget);
    });

    testWidgets('Table with both colSpan and rowSpan', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(colSpan: 2, rowSpan: 2, child: Text('Large Cell')),
                  TableCell.none,
                  Text('Right Cell'),
                ],
              ),
              TableRow(children: <Widget>[TableCell.none, TableCell.none, Text('Bottom Right')]),
              TableRow(children: <Widget>[Text('Bottom 1'), Text('Bottom 2'), Text('Bottom 3')]),
            ],
          ),
        ),
      );

      expect(find.text('Large Cell'), findsOneWidget);
      expect(find.text('Right Cell'), findsOneWidget);
      expect(find.text('Bottom Right'), findsOneWidget);
      expect(find.text('Bottom 1'), findsOneWidget);
      expect(find.text('Bottom 2'), findsOneWidget);
      expect(find.text('Bottom 3'), findsOneWidget);
    });

    testWidgets('TableCell colSpan exceeds table columns - throws error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(colSpan: 3, child: Text('Too Wide')),
                  Text('Cell 1'),
                ],
              ),
            ],
          ),
        ),
      );

      final Object? exception = tester.takeException();

      expect(exception, isA<FlutterError>());
      expect(exception.toString(), contains('Invalid TableCell.colSpan'));
    });

    testWidgets('TableCell rowSpan exceeds table rows - throws error', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(rowSpan: 3, child: Text('Too Tall')),
                  Text('Cell 1'),
                ],
              ),
              TableRow(children: <Widget>[TableCell.none, Text('Cell 2')]),
            ],
          ),
        ),
      );

      final Object? exception = tester.takeException();

      expect(exception, isNotNull);
      expect(exception.toString(), contains('Invalid TableCell.rowSpan'));
    });

    testWidgets('TableCell with colSpan at last column - valid edge case', (
      WidgetTester tester,
    ) async {
      // This should not throw an error as colSpan is exactly at the boundary
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  Text('Cell 1'),
                  TableCell(colSpan: 2, child: Text('Last Two')),
                  TableCell.none,
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Last Two'), findsOneWidget);
    });

    testWidgets('TableCell with rowSpan at last row - valid edge case', (
      WidgetTester tester,
    ) async {
      // This should not throw an error as rowSpan is exactly at the boundary
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  Text('Cell 1'),
                  TableCell(rowSpan: 2, child: Text('Tall Cell')),
                ],
              ),
              TableRow(children: <Widget>[Text('Cell 2'), TableCell.none]),
            ],
          ),
        ),
      );

      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 2'), findsOneWidget);
      expect(find.text('Tall Cell'), findsOneWidget);
    });

    testWidgets('TableCell colSpan and rowSpan assertions', (WidgetTester tester) async {
      expect(() => TableCell(colSpan: 0, child: Container()), throwsAssertionError);

      expect(() => TableCell(rowSpan: 0, child: Container()), throwsAssertionError);

      expect(() => TableCell(colSpan: -1, child: Container()), throwsAssertionError);

      expect(() => TableCell(rowSpan: -1, child: Container()), throwsAssertionError);
    });

    testWidgets('TableCell parent data contains colSpan and rowSpan', (WidgetTester tester) async {
      const ValueKey<String> testKey = ValueKey<String>('TestCell');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(key: testKey, colSpan: 2, rowSpan: 3, child: Text('Test')),
                  TableCell.none,
                ],
              ),
              TableRow(children: <Widget>[TableCell.none, TableCell.none]),
              TableRow(children: <Widget>[TableCell.none, TableCell.none]),
            ],
          ),
        ),
      );

      // Instead of trying to access parentData directly, test the widget properties
      final TableCell cellWidget = tester.widget(find.byKey(testKey));
      expect(cellWidget.colSpan, equals(2));
      expect(cellWidget.rowSpan, equals(3));
    });

    testWidgets('Table with complex colSpan and rowSpan layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(colSpan: 2, child: Text('Header')),
                  TableCell.none,
                  Text('Top Right'),
                ],
              ),
              TableRow(
                children: <Widget>[
                  TableCell(rowSpan: 2, child: Text('Left Tall')),
                  Text('Middle'),
                  TableCell(rowSpan: 2, child: Text('Right Tall')),
                ],
              ),
              TableRow(children: <Widget>[TableCell.none, Text('Bottom Middle'), TableCell.none]),
            ],
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Top Right'), findsOneWidget);
      expect(find.text('Left Tall'), findsOneWidget);
      expect(find.text('Middle'), findsOneWidget);
      expect(find.text('Right Tall'), findsOneWidget);
      expect(find.text('Bottom Middle'), findsOneWidget);
    });

    testWidgets('Table with all cells using TableCell.none in spanning area', (
      WidgetTester tester,
    ) async {
      // Test that using TableCell.none correctly maintains table structure
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Table(
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  TableCell(colSpan: 3, rowSpan: 2, child: Text('Big Cell')),
                  TableCell.none,
                  TableCell.none,
                ],
              ),
              TableRow(children: <Widget>[TableCell.none, TableCell.none, TableCell.none]),
              TableRow(children: <Widget>[Text('A'), Text('B'), Text('C')]),
            ],
          ),
        ),
      );

      expect(find.text('Big Cell'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });
}
