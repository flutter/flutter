// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 1', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    // smoketest
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Container(
          child: Semantics(
            label: 'test1',
            textDirection: TextDirection.ltr,
            child: Container(),
            selected: true,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          label: 'test1',
          rect: TestSemantics.fullScreen,
          flags: SemanticsFlag.isSelected.index,
        ),
      ],
    )));

    // control for forking
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 10.0,
              child: Semantics(
                label: 'child1',
                textDirection: TextDirection.ltr,
                selected: true,
              ),
            ),
            Container(
              height: 10.0,
              child: IgnorePointer(
                ignoring: true,
                child: Semantics(
                  label: 'child1',
                  textDirection: TextDirection.ltr,
                  selected: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          label: 'child1',
          rect: TestSemantics.fullScreen,
          flags: SemanticsFlag.isSelected.index,
        ),
      ],
    )));

    // forking semantics
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 10.0,
              child: Semantics(
                label: 'child1',
                textDirection: TextDirection.ltr,
                selected: true,
              ),
            ),
            Container(
              height: 10.0,
              child: IgnorePointer(
                ignoring: false,
                child: Semantics(
                  label: 'child2',
                  textDirection: TextDirection.ltr,
                  selected: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              label: 'child1',
              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
              flags: SemanticsFlag.isSelected.index,
            ),
            TestSemantics(
              id: 3,
              label: 'child2',
              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
              flags: SemanticsFlag.isSelected.index,
            ),
          ],
        ),
      ],
    ), ignoreTransform: true));

    // toggle a branch off
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 10.0,
              child: Semantics(
                label: 'child1',
                textDirection: TextDirection.ltr,
                selected: true,
              ),
            ),
            Container(
              height: 10.0,
              child: IgnorePointer(
                ignoring: true,
                child: Semantics(
                  label: 'child2',
                  textDirection: TextDirection.ltr,
                  selected: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          label: 'child1',
          rect: TestSemantics.fullScreen,
          flags: SemanticsFlag.isSelected.index,
        ),
      ],
    )));

    // toggle a branch back on
    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 10.0,
              child: Semantics(
                label: 'child1',
                textDirection: TextDirection.ltr,
                selected: true,
              ),
            ),
            Container(
              height: 10.0,
              child: IgnorePointer(
                ignoring: false,
                child: Semantics(
                  label: 'child2',
                  textDirection: TextDirection.ltr,
                  selected: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              id: 4,
              label: 'child1',
              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
              flags: SemanticsFlag.isSelected.index,
            ),
            TestSemantics(
              id: 3,
              label: 'child2',
              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
              flags: SemanticsFlag.isSelected.index,
            ),
          ],
        ),
      ],
    ), ignoreTransform: true));

    semantics.dispose();
  });
}
