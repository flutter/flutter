// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TestStatefulWidget extends StatefulWidget {
  const TestStatefulWidget({ Key key }) : super(key: key);

  @override
  TestStatefulWidgetState createState() => new TestStatefulWidgetState();
}

class TestStatefulWidgetState extends State<TestStatefulWidget> {
  @override
  Widget build(BuildContext context) => new Container();
}

void main() {
  testWidgets('Table widget - control test', (WidgetTester tester) async {
    Future<Null> run(TextDirection textDirection) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: textDirection,
          child: new Table(
            children: <TableRow>[
              new TableRow(
                children: <Widget>[
                  const Text('AAAAAA'), const Text('B'), const Text('C'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('D'), const Text('EEE'), const Text('F'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('G'), const Text('H'), const Text('III'),
                ],
              ),
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
    await tester.pumpWidget(new Container());
    await run(TextDirection.rtl);
  });

  testWidgets('Table widget - column offset (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Table(
            columnWidths: const <int, TableColumnWidth> {
              0: const FixedColumnWidth(100.0),
              1: const FixedColumnWidth(110.0),
              2: const FixedColumnWidth(125.0),
            },
            defaultColumnWidth: const FixedColumnWidth(333.0),
            children: <TableRow>[
              new TableRow(
                children: <Widget>[
                  const Text('A1'), const Text('B1'), const Text('C1'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('A2'), const Text('B2'), const Text('C2'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('A3'), const Text('B3'), const Text('C3'),
                ],
              ),
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
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Table(
            columnWidths: const <int, TableColumnWidth> {
              0: const FixedColumnWidth(100.0),
              1: const FixedColumnWidth(110.0),
              2: const FixedColumnWidth(125.0),
            },
            defaultColumnWidth: const FixedColumnWidth(333.0),
            children: <TableRow>[
              new TableRow(
                children: <Widget>[
                  const Text('A1'), const Text('B1'), const Text('C1'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('A2'), const Text('B2'), const Text('C2'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('A3'), const Text('B3'), const Text('C3'),
                ],
              ),
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
    Future<Null> run(TextDirection textDirection) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: textDirection,
          child: new Table(
            border: new TableBorder.all(),
            children: <TableRow>[
              new TableRow(
                children: <Widget>[
                  const Text('AAAAAA'), const Text('B'), const Text('C'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('D'), const Text('EEE'), const Text('F'),
                ],
              ),
              new TableRow(
                children: <Widget>[
                  const Text('G'), const Text('H'), const Text('III'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    await run(TextDirection.ltr);
    await tester.pumpWidget(new Container());
    await run(TextDirection.rtl);
  });

  testWidgets('Table widget - changing table dimensions', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('A'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('E'), const Text('F'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('I'),
              ],
            ),
          ],
        ),
      ),
    );
    final RenderBox boxA1 = tester.renderObject(find.text('A'));
    final RenderBox boxG1 = tester.renderObject(find.text('G'));
    expect(boxA1, isNotNull);
    expect(boxG1, isNotNull);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('a'), const Text('b'), const Text('c'), const Text('d'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('e'), const Text('f'), const Text('g'), const Text('h'),
              ],
            ),
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

  testWidgets('Table widget - repump test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('AAAAAA'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('EEE'), const Text('F'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('AAA'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('E'), const Text('FFFFFF'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
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
      new Directionality(
      textDirection: TextDirection.ltr,
        child: new Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('AAA'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('E'), const Text('FFFFFF'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('AAAAAA'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('EEE'), const Text('F'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('A'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('EEE'), const Text('F'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
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

  testWidgets('Table widget - intrinsic sizing test, changing column widths', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('AAA'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('E'), const Text('FFFFFF'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('AAA'), const Text('B'), const Text('C'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('D'), const Text('E'), const Text('FFFFFF'),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('G'), const Text('H'), const Text('III'),
              ],
            ),
          ],
        )
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              key: const ValueKey<int>(1),
              children: <Widget>[
                new StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    contexts.add(context);
                    return const Text('A');
                  },
                ),
              ],
            ),
            new TableRow(
              children: <Widget>[
                const Text('b'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                const Text('b'),
              ],
            ),
            new TableRow(
              key: const ValueKey<int>(1),
              children: <Widget>[
                new StatefulBuilder(
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              key: const ValueKey<int>(1),
              children: <Widget>[
                const TestStatefulWidget(key: const ValueKey<int>(11)),
                const TestStatefulWidget(key: const ValueKey<int>(12)),
              ],
            ),
            new TableRow(
              key: const ValueKey<int>(2),
              children: <Widget>[
                const TestStatefulWidget(key: const ValueKey<int>(21)),
                const TestStatefulWidget(key: const ValueKey<int>(22)),
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Table(
          children: <TableRow>[
            new TableRow(
              key: const ValueKey<int>(2),
              children: <Widget>[
                const TestStatefulWidget(key: const ValueKey<int>(21)),
                const TestStatefulWidget(key: const ValueKey<int>(22)),
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
    final GlobalKey key = new GlobalKey();
    final Key tableKey = new UniqueKey();

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget> [
            new Expanded(
              key: tableKey,
              child: new Table(
                children: <TableRow>[
                  new TableRow(
                    children: <Widget>[
                      new Container(key: const ValueKey<int>(1)),
                      new TestStatefulWidget(key: key),
                      new Container(key: const ValueKey<int>(2)),
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget> [
            new Expanded(child: new TestStatefulWidget(key: key)),
            new Expanded(
              key: tableKey,
              child: new Table(
                children: <TableRow>[
                  new TableRow(
                    children: <Widget>[
                      new Container(key: const ValueKey<int>(1)),
                      new Container(key: const ValueKey<int>(2)),
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget> [
            new Expanded(
              key: tableKey,
              child: new Table(
                children: <TableRow>[
                  new TableRow(
                    children: <Widget>[
                      new Container(key: const ValueKey<int>(1)),
                      new TestStatefulWidget(key: key),
                      new Container(key: const ValueKey<int>(2)),
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget> [
            new Expanded(
              key: tableKey,
              child: new Table(
                children: <TableRow>[
                  new TableRow(
                    children: <Widget>[
                      new Container(key: const ValueKey<int>(1)),
                      new Container(key: const ValueKey<int>(2)),
                    ],
                  ),
                ],
              ),
            ),
            new Expanded(child: new TestStatefulWidget(key: key)),
          ],
        ),
      ),
    );

    expect(tester.renderObject(find.byType(Table)), equals(table));
    expect(table.row(0).length, 2);
  });

  testWidgets('Table widget diagnostics', (WidgetTester tester) async {
    GlobalKey key0;
    final Widget table = new Directionality(
      textDirection: TextDirection.ltr,
      child: new Table(
        key: key0 = new GlobalKey(),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: <TableRow>[
          new TableRow(
            children: <Widget>[
              const Text('A'), const Text('B'), const Text('C'),
            ],
          ),
          new TableRow(
            children: <Widget>[
              const Text('D'), const Text('EEE'), const Text('F'),
            ],
          ),
          new TableRow(
            children: <Widget>[
              const Text('G'), const Text('H'), const Text('III'),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(table);
    final RenderObjectElement element = key0.currentContext;
    expect(element, hasAGoodToStringDeep);
    expect(
      element.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'Table-[GlobalKey#00000](renderObject: RenderTable#00000)\n'
        '├Text("A")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("B")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("C")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("D")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("EEE")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("F")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("G")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '├Text("H")\n'
        '│└RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n'
        '└Text("III")\n'
        ' └RichText(renderObject: RenderParagraph#00000 relayoutBoundary=up1)\n',
      ),
    );
  });

  // TODO(ianh): Test handling of TableCell object
}
