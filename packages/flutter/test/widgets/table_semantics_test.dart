// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Table semantics uses logical column indices in RTL', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topLeft,
          child: Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(80),
              1: FixedColumnWidth(120),
            },
            children: const <TableRow>[
              TableRow(
                children: <Widget>[
                  SizedBox(height: 20, child: Text('first')),
                  SizedBox(height: 20, child: Text('second')),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final SemanticsNode first = find.semantics.byLabel('first').evaluate().single;
    final SemanticsNode second = find.semantics.byLabel('second').evaluate().single;
    final SemanticsNode firstCell = first.parent!;
    final SemanticsNode secondCell = second.parent!;

    expect(firstCell.role, SemanticsRole.cell);
    expect(firstCell.indexInParent, 0);
    expect(firstCell.rect.width, 80);
    expect(MatrixUtils.getAsTranslation(firstCell.transform!), const Offset(120, 0));

    expect(secondCell.role, SemanticsRole.cell);
    expect(secondCell.indexInParent, 1);
    expect(secondCell.rect.width, 120);
    expect(MatrixUtils.getAsTranslation(secondCell.transform!), Offset.zero);
  });
}
