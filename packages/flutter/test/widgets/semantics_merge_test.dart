// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('MergeSemantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    // not merged
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Row(
          children: <Widget>[
            new Semantics(
              container: true,
              child: const Text('test1'),
            ),
            new Semantics(
              container: true,
              child: const Text('test2'),
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            label: 'test1',
          ),
          new TestSemantics.rootChild(
            id: 2,
            label: 'test2',
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    // merged
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new MergeSemantics(
          child: new Row(
            children: <Widget>[
              new Semantics(
                container: true,
                child: const Text('test1'),
              ),
              new Semantics(
                container: true,
                child: const Text('test2'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 3,
            label: 'test1\ntest2',
          ),
        ]
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    // not merged
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Row(
          children: <Widget>[
            new Semantics(
              container: true,
              child: const Text('test1'),
            ),
            new Semantics(
              container: true,
              child: const Text('test2'),
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(id: 6, label: 'test1'),
          new TestSemantics.rootChild(id: 7, label: 'test2'),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('MergeSemantics works if other nodes are implicitly merged into its node', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new MergeSemantics(
          child: new Semantics(
            selected: true, // this is implicitly merged into the MergeSemantics node
            child: new Row(
              children: <Widget>[
                new Semantics(
                  container: true,
                  child: const Text('test1'),
                ),
                new Semantics(
                  container: true,
                  child: const Text('test2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
          children: <TestSemantics>[
            new TestSemantics.rootChild(
              id: 1,
              flags: <SemanticsFlag>[
                SemanticsFlag.isSelected,
              ],
              label: 'test1\ntest2',
            ),
          ]
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });
}
