// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('AbsorbPointers do not block siblings', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => tapped = true,
            ),
          ),
          const Expanded(
            child: AbsorbPointer(),
          ),
        ],
      ),
    );
    await tester.tap(find.byType(GestureDetector));
    expect(tapped, true);
  });

  testWidgets('AbsorbPointers semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      AbsorbPointer(
        child: Semantics(
          label: 'test',
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    expect(semantics, hasSemantics(TestSemantics.root(), ignoreId: true, ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(
      AbsorbPointer(
        absorbing: false,
        child: Semantics(
          label: 'test',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            label: 'test',
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));
    semantics.dispose();
  });
}
