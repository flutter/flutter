// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Traversal order handles touching elements', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new MaterialApp(
        home: new Column(
          children: new List<Widget>.generate(3, (int column) {
            return new Row(children: List<Widget>.generate(3, (int row) {
              return new Semantics(
                child: new SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: new Text('$column - $row'),
                ),
              );
          }));
        }),
      ),
    ));

    final TestSemantics expected = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics(
          id: 1,
          textDirection: TextDirection.ltr,
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
              children: <TestSemantics>[
                new TestSemantics(
                  id: 3,
                  label: '0 - 0',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 4,
                  label: '0 - 1',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 5,
                  label: '0 - 2',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 6,
                  label: '1 - 0',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 7,
                  label: '1 - 1',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 8,
                  label: '1 - 2',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 9,
                  label: '2 - 0',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 10,
                  label: '2 - 1',
                  textDirection: TextDirection.ltr,
                ),
                new TestSemantics(
                  id: 11,
                  label: '2 - 2',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expected, ignoreRect: true, ignoreTransform: true));
    semantics.dispose();
  });
}
