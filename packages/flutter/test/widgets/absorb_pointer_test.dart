// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('AbsorbPointers do not block siblings', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      new Column(
        children: <Widget>[
          new Expanded(
            child: new GestureDetector(
              onTap: () => tapped = true,
            ),
          ),
          const Expanded(
            child: AbsorbPointer(
              absorbing: true,
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    expect(tapped, true);
  });

  testWidgets('AbsorbPointers semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new AbsorbPointer(
        absorbing: true,
        child: new Semantics(
          label: 'test',
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    expect(semantics, hasSemantics(
      new TestSemantics.root(), ignoreId: true, ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(
      new AbsorbPointer(
        absorbing: false,
        child: new Semantics(
          label: 'test',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'test',
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
      ignoreId: true, ignoreRect: true, ignoreTransform: true));
    semantics.dispose();
  });
}
