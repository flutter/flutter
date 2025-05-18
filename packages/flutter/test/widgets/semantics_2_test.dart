// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 2', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    // this test is the same as the test in Semantics 1, but
    // starting with the second branch being ignored and then
    // switching to not ignoring it.

    // forking semantics
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 10.0,
              child: Semantics(label: 'child1', textDirection: TextDirection.ltr, selected: true),
            ),
            SizedBox(
              height: 10.0,
              child: ExcludeSemantics(
                excluding: false,
                child: Semantics(label: 'child2', textDirection: TextDirection.ltr, selected: true),
              ),
            ),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  label: 'child1',
                  rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
                  flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
                ),
                TestSemantics(
                  id: 3,
                  label: 'child2',
                  rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
                  flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
      ),
    );

    // toggle a branch off
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 10.0,
              child: Semantics(label: 'child1', textDirection: TextDirection.ltr, selected: true),
            ),
            SizedBox(
              height: 10.0,
              child: ExcludeSemantics(
                child: Semantics(label: 'child2', textDirection: TextDirection.ltr, selected: true),
              ),
            ),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'child1',
              rect: TestSemantics.fullScreen,
              flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
            ),
          ],
        ),
      ),
    );

    // toggle a branch back on
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 10.0,
              child: Semantics(label: 'child1', textDirection: TextDirection.ltr, selected: true),
            ),
            SizedBox(
              height: 10.0,
              child: ExcludeSemantics(
                excluding: false,
                child: Semantics(label: 'child2', textDirection: TextDirection.ltr, selected: true),
              ),
            ),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                  id: 4,
                  label: 'child1',
                  rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
                  flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
                ),
                TestSemantics(
                  id: 3,
                  label: 'child2',
                  rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
                  flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });
}
