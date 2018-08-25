// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('markNeedsSemanticsUpdate() called on non-boundary with non-boundary parent', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Semantics(
        container: true,
        onTap: dummyTapHandler,
        child: new Semantics(
          onTap: dummyTapHandler,
          child: new Semantics(
            onTap: dummyTapHandler,
            textDirection: TextDirection.ltr,
            label: 'foo',
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          actions: SemanticsAction.tap.index,
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              actions: SemanticsAction.tap.index,
              children: <TestSemantics>[
                new TestSemantics(
                  id: 3,
                  actions: SemanticsAction.tap.index,
                  label: 'foo',
                )
              ],
            ),
          ],
        )
      ],
    ), ignoreRect: true, ignoreTransform: true));

    // make a change causing call to markNeedsSemanticsUpdate()

    // This should not throw an assert.
    await tester.pumpWidget(
      new Semantics(
        container: true,
        onTap: dummyTapHandler,
        child: new Semantics(
          onTap: dummyTapHandler,
          child: new Semantics(
            onTap: dummyTapHandler,
            textDirection: TextDirection.ltr,
            label: 'bar', // <-- only change
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          actions: SemanticsAction.tap.index,
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              actions: SemanticsAction.tap.index,
              children: <TestSemantics>[
                new TestSemantics(
                  id: 3,
                  actions: SemanticsAction.tap.index,
                  label: 'bar',
                )
              ],
            ),
          ],
        )
      ],
    ), ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });
}

void dummyTapHandler() { }
